#!/usr/bin/env bash
# Deploys the Foundry hosted-agent sample in three CLI-driven stages:
#   1. foundry_base  - Terraform: everything except the hosted agent itself.
#   2. image         - Docker: build the application image and push it to ACR.
#   3. hosted_agent  - Terraform: publish the hosted agent using the pushed image.
#
# Usage:
#   deploy.sh [--environment dev] [--stage all|base|image|agent] [--tag <tag>]
#
# Environment variables:
#   AUTO_APPROVE=1   Skip confirmation prompts (plan/apply, image push).
#   SKIP_BUILD=1     Skip the docker build (see lib/build-docker.sh).
#   ALLOW_DIRTY=1    Allow a dirty git tree when computing the default tag.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../lib/common.sh
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=../../../lib/build-docker.sh
source "$REPO_ROOT/lib/build-docker.sh"
# shellcheck source=../../../lib/deploy-terraform.sh
source "$REPO_ROOT/lib/deploy-terraform.sh"

INFRA_DIR="$REPO_ROOT/simple_agent/azure/infra"
BASE_DIR="$INFRA_DIR/foundry_base"
AGENT_DIR="$INFRA_DIR/hosted_agent"
SRC_DIR="$REPO_ROOT/simple_agent/azure/src"
IMAGE_REPOSITORY_NAME="${IMAGE_REPOSITORY_NAME:-basic-agent}"

ENVIRONMENT="dev"
STAGE="all"
IMAGE_TAG=""

usage() {
  cat >&2 <<'EOT'
Usage: deploy.sh [--environment <env>] [--stage all|base|image|agent] [--tag <tag>]
EOT
}

while (( $# > 0 )); do
  case "$1" in
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --tag) IMAGE_TAG="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) log_error "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

case "$STAGE" in
  all|base|image|agent) ;;
  *) log_error "Invalid --stage: $STAGE (expected all|base|image|agent)"; exit 2 ;;
esac

require_command terraform docker az git

# deploy_base
# Plans and, after confirmation, applies the foundry_base Terraform stack.
deploy_base() {
  local var_file="environments/${ENVIRONMENT}.tfvars"
  tf_init "$BASE_DIR"

  local rc=0
  tf_plan "$BASE_DIR" "$var_file" || rc=$?
  if (( rc != 0 && rc != 2 )); then
    log_error "terraform plan failed for foundry_base"
    return "$rc"
  fi

  if (( rc == 2 )); then
    confirm "Apply the foundry_base plan above?" || { log_warn "foundry_base apply skipped"; return 1; }
    tf_apply "$BASE_DIR"
  else
    log_info "foundry_base: no changes to apply"
  fi
}

# build_and_push_image
# Builds the application image and pushes it to the ACR created by foundry_base.
build_and_push_image() {
  local acr_name acr_login_server image_uri
  acr_name="$(tf_output "$BASE_DIR" acr_name)"
  acr_login_server="$(tf_output "$BASE_DIR" acr_login_server)"

  if [[ -z "$IMAGE_TAG" ]]; then
    IMAGE_TAG="$(compute_image_tag)"
  fi
  image_uri="${acr_login_server}/${IMAGE_REPOSITORY_NAME}:${IMAGE_TAG}"

  docker_build "$SRC_DIR" "$image_uri"

  if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    log_info "build_and_push_image: SKIP_BUILD=1, skipping push"
    return 0
  fi

  confirm "Push ${image_uri} to ${acr_name}?" || { log_warn "image push skipped"; return 1; }
  log_info "az acr login: $acr_name"
  az acr login --name "$acr_name"
  log_info "docker push: $image_uri"
  docker push "$image_uri"
}

# deploy_agent
# Plans and, after confirmation, applies the hosted_agent Terraform stack for
# the image tag built in this run (or supplied via --tag). foundry_base's
# outputs are passed as -var overrides instead of read via remote state.
deploy_agent() {
  if [[ -z "$IMAGE_TAG" ]]; then
    IMAGE_TAG="$(compute_image_tag)"
  fi

  local acr_login_server agent_name model_deployment_name project_endpoint rai_policy_id
  acr_login_server="$(tf_output "$BASE_DIR" acr_login_server)"
  agent_name="$(tf_output "$BASE_DIR" agent_name)"
  model_deployment_name="$(tf_output "$BASE_DIR" model_deployment_name)"
  project_endpoint="$(tf_output "$BASE_DIR" foundry_project_endpoint)"
  rai_policy_id="$(tf_output "$BASE_DIR" foundry_rai_policy_id)"

  local var_file="environments/${ENVIRONMENT}.tfvars"
  tf_init "$AGENT_DIR"

  local rc=0
  tf_plan "$AGENT_DIR" "$var_file" \
    "acr_login_server=$acr_login_server" \
    "agent_name=$agent_name" \
    "image_repository_name=$IMAGE_REPOSITORY_NAME" \
    "image_tag=$IMAGE_TAG" \
    "model_deployment_name=$model_deployment_name" \
    "project_endpoint=$project_endpoint" \
    "rai_policy_id=$rai_policy_id" || rc=$?
  if (( rc != 0 && rc != 2 )); then
    log_error "terraform plan failed for hosted_agent"
    return "$rc"
  fi

  if (( rc == 2 )); then
    confirm "Apply the hosted_agent plan above?" || { log_warn "hosted_agent apply skipped"; return 1; }
    tf_apply "$AGENT_DIR"
  else
    log_info "hosted_agent: no changes to apply"
  fi
}

case "$STAGE" in
  all)
    deploy_base
    build_and_push_image
    deploy_agent
    ;;
  base) deploy_base ;;
  image) build_and_push_image ;;
  agent) deploy_agent ;;
esac

log_success "deploy.sh: stage '$STAGE' complete"
