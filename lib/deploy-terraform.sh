#!/usr/bin/env bash
# Cloud-agnostic Terraform wrappers.
# Source, do not execute. Depends on lib/common.sh being sourced first.

if [[ "${LIB_DEPLOY_TERRAFORM_SOURCED:-}" == "1" ]]; then
  return 0
fi
LIB_DEPLOY_TERRAFORM_SOURCED=1

# Standard plan-file name written into the module directory.
TF_PLAN_FILE="${TF_PLAN_FILE:-tfplan}"

# tf_init <module_dir>
tf_init() {
  local dir="$1"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    log_error "tf_init: module directory does not exist: $dir"
    return 1
  fi
  log_info "terraform init: $dir"
  terraform -chdir="$dir" init -input=false -no-color
}

# tf_output <module_dir> <output_name>
# Prints the raw output value on stdout so the caller can capture it.
tf_output() {
  local dir="$1"
  local name="$2"
  terraform -chdir="$dir" output -raw "$name"
}

# tf_plan <module_dir> <var_file> [<var_key=value>...]
#
# Writes tfplan into the module directory. Uses -detailed-exitcode so the
# caller can distinguish "no changes" (0) from "changes queued" (2). Any other
# non-zero exit code indicates an error. Callers should invoke with the
# `|| rc=$?` idiom so bash errexit is not triggered on 2.
tf_plan() {
  local dir="$1"
  local var_file="$2"
  shift 2

  local var_args=()
  local kv
  for kv in "$@"; do
    var_args+=(-var "$kv")
  done

  log_info "terraform plan: $dir (var-file=$var_file)"
  local rc=0
  terraform -chdir="$dir" plan \
    -var-file="$var_file" \
    "${var_args[@]}" \
    -out="$TF_PLAN_FILE" \
    -input=false \
    -no-color \
    -detailed-exitcode || rc=$?
  return "$rc"
}

# tf_apply <module_dir>
# Applies the saved plan, removes the plan file on success, prints outputs.
tf_apply() {
  local dir="$1"
  if [[ ! -f "$dir/$TF_PLAN_FILE" ]]; then
    log_error "tf_apply: plan file not found: $dir/$TF_PLAN_FILE"
    return 1
  fi

  log_info "terraform apply: $dir"
  terraform -chdir="$dir" apply -input=false -no-color "$TF_PLAN_FILE"
  rm -f "$dir/$TF_PLAN_FILE"

  log_info "terraform outputs:"
  terraform -chdir="$dir" output
}
