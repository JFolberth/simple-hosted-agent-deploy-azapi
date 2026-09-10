#!/usr/bin/env bash
# End-to-end Azure Foundry deploy: bootstrap ACR -> build image -> push to ACR -> terraform plan -> apply.
# Reads ACR values from Terraform outputs, so infra must be applied at least once.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../lib/common.sh
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=../../../lib/build-docker.sh
source "$REPO_ROOT/lib/build-docker.sh"
# shellcheck source=../../../lib/deploy-terraform.sh
source "$REPO_ROOT/lib/deploy-terraform.sh"

CODE_DIR="$REPO_ROOT/simple_agent/azure/src"
INFRA_DIR="$REPO_ROOT/simple_agent/azure/infra"

ENV="dev"
TAG_OVERRIDE=""
SKIP_APPLY=0
: "${SKIP_BUILD:=0}"
: "${SKIP_PUSH:=0}"
: "${ALLOW_DIRTY:=0}"
: "${AUTO_APPROVE:=${DEPLOY_AUTO_APPROVE:-0}}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [flags]

Flags:
  --env <name>       Environment (default: dev). Selects environments/<name>.tfvars.
  --tag <string>     Override the computed image tag. 'latest' is rejected.
  --yes              Skip the interactive confirmation before terraform apply.
  --allow-dirty      Do not append '-dirty' to the tag when the working tree is unclean.
  --skip-build       Reuse an existing local image; skip 'docker build'.
  --skip-push        Do not push to ACR. Implies --skip-apply.
  --skip-apply       Produce a plan only; do not apply.
  -h, --help         Show this message.

Environment variables honored:
  PIP_INDEX_URL, PIP_TRUSTED_HOST   Forwarded to 'docker build' as build args.
  DEPLOY_AUTO_APPROVE=1             Same as --yes.
  ALLOW_DIRTY=1                     Same as --allow-dirty.
  SKIP_BUILD=1, SKIP_PUSH=1         Same as their --skip-* flags.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --env)          ENV="$2"; shift 2 ;;
    --tag)          TAG_OVERRIDE="$2"; shift 2 ;;
    --yes)          AUTO_APPROVE=1; shift ;;
    --allow-dirty)  ALLOW_DIRTY=1; shift ;;
    --skip-build)   SKIP_BUILD=1; shift ;;
    --skip-push)    SKIP_PUSH=1; SKIP_APPLY=1; shift ;;
    --skip-apply)   SKIP_APPLY=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              log_error "Unknown flag: $1"; usage; exit 2 ;;
  esac
done

export ALLOW_DIRTY AUTO_APPROVE SKIP_BUILD

require_command docker az terraform git

VAR_FILE="environments/${ENV}.tfvars"
if [[ ! -f "$INFRA_DIR/$VAR_FILE" ]]; then
  log_error "tfvars file not found: $INFRA_DIR/$VAR_FILE"
  exit 1
fi

if [[ -n "$TAG_OVERRIDE" ]]; then
  IMAGE_TAG="$TAG_OVERRIDE"
else
  IMAGE_TAG="$(compute_image_tag)"
fi

if [[ "$IMAGE_TAG" == "latest" || -z "$IMAGE_TAG" ]]; then
  log_error "Refusing to deploy with tag '$IMAGE_TAG'. Use an immutable identifier (git SHA)."
  exit 1
fi

if [[ "$IMAGE_TAG" == *-dirty ]]; then
  log_warn "Working tree is dirty. Deploying tag: $IMAGE_TAG"
fi

log_info "Environment: $ENV"
log_info "Image tag:   $IMAGE_TAG"

read_acr_outputs() {
  if ! ACR_NAME="$(tf_output "$INFRA_DIR" acr_name 2>/dev/null)"; then
    ACR_NAME=""
  fi
  if ! ACR_LOGIN_SERVER="$(tf_output "$INFRA_DIR" acr_login_server 2>/dev/null)"; then
    ACR_LOGIN_SERVER=""
  fi
  if ! ACR_REPOSITORY_NAME="$(tf_output "$INFRA_DIR" acr_repository_name 2>/dev/null)"; then
    ACR_REPOSITORY_NAME=""
  fi

  [[ -n "$ACR_NAME" && -n "$ACR_LOGIN_SERVER" && -n "$ACR_REPOSITORY_NAME" ]]
}

tf_init "$INFRA_DIR"

if ! read_acr_outputs; then
  if [[ "$SKIP_APPLY" == "1" ]]; then
    log_error "Could not read required ACR outputs from Terraform (acr_name, acr_login_server, acr_repository_name)."
    log_error "First run requires Terraform apply. Re-run without --skip-apply (and without --skip-push)."
    exit 1
  fi

  log_warn "ACR outputs are missing; running one-time Terraform bootstrap for infra creation."

  bootstrap_plan_rc=0
  terraform -chdir="$INFRA_DIR" plan \
    -target=module.image_registry \
    -var-file="$VAR_FILE" \
    -var="image_tag=$IMAGE_TAG" \
    -out="$TF_PLAN_FILE" \
    -input=false \
    -no-color \
    -detailed-exitcode || bootstrap_plan_rc=$?

  case "$bootstrap_plan_rc" in
    0)
      log_warn "Bootstrap plan reported no changes. Re-checking Terraform outputs."
      ;;
    2)
      if ! confirm "Apply bootstrap infrastructure now?"; then
        log_error "Bootstrap apply declined. Cannot continue without ACR outputs."
        exit 1
      fi
      tf_apply "$INFRA_DIR"
      ;;
    *)
      log_error "Bootstrap terraform plan failed (exit $bootstrap_plan_rc)"
      exit "$bootstrap_plan_rc"
      ;;
  esac

  if ! read_acr_outputs; then
    log_error "Required ACR outputs are still missing after bootstrap attempt."
    log_error "Ensure Terraform state/module defines acr_name, acr_login_server, and acr_repository_name."
    exit 1
  fi
fi

ACR_IMAGE_URL="${ACR_LOGIN_SERVER}/${ACR_REPOSITORY_NAME}:${IMAGE_TAG}"

log_info "ACR name:          $ACR_NAME"
log_info "ACR login server:  $ACR_LOGIN_SERVER"
log_info "ACR repository:    $ACR_REPOSITORY_NAME"

# Foundry hosted runtime requires linux/amd64 images.
DOCKER_BUILD_PLATFORM="linux/amd64" docker_build "$CODE_DIR" "basic-agent:local" "$ACR_IMAGE_URL"

if [[ "$SKIP_PUSH" == "1" ]]; then
  log_warn "SKIP_PUSH=1: not pushing to ACR"
else
  existing_tag_count="$(az acr repository show-tags \
    --name "$ACR_NAME" \
    --repository "$ACR_REPOSITORY_NAME" \
    --query "[?@=='${IMAGE_TAG}'] | length(@)" \
    --output tsv \
    2>/dev/null || true)"

  if [[ "$existing_tag_count" == "1" ]]; then
    log_info "Tag $IMAGE_TAG already exists in ACR; skipping push"
  else
    log_info "Logging in to ACR ($ACR_NAME)"
    az acr login --name "$ACR_NAME" --output none
    log_info "Pushing $ACR_IMAGE_URL"
    docker push "$ACR_IMAGE_URL"
  fi
fi

plan_rc=0
tf_plan "$INFRA_DIR" "$VAR_FILE" "image_tag=$IMAGE_TAG" || plan_rc=$?

case "$plan_rc" in
  0)
    log_success "No changes to apply."
    rm -f "$INFRA_DIR/$TF_PLAN_FILE"
    exit 0
    ;;
  2)
    log_info "Plan has changes."
    ;;
  *)
    log_error "terraform plan failed (exit $plan_rc)"
    exit "$plan_rc"
    ;;
esac

if [[ "$SKIP_APPLY" == "1" ]]; then
  log_warn "SKIP_APPLY=1: leaving plan at $INFRA_DIR/$TF_PLAN_FILE"
  exit 0
fi

if ! confirm "Apply this plan?"; then
  log_warn "Apply declined. Plan remains at $INFRA_DIR/$TF_PLAN_FILE"
  exit 0
fi

tf_apply "$INFRA_DIR"
log_success "Deploy complete: $ACR_IMAGE_URL"
