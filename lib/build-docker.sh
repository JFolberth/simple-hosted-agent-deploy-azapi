#!/usr/bin/env bash
# Cloud-agnostic Docker build helper.
# Source, do not execute. Depends on lib/common.sh being sourced first.

if [[ "${LIB_BUILD_DOCKER_SOURCED:-}" == "1" ]]; then
  return 0
fi
LIB_BUILD_DOCKER_SOURCED=1

# docker_build <context_dir> <primary_tag> [<additional_tag>...]
#
# Runs `docker build` against <context_dir>, tagging with every tag argument.
# Forwards PIP_INDEX_URL and PIP_TRUSTED_HOST as --build-arg when set, so
# corporate Python mirrors are honored without hard-coding them in Dockerfiles.
# Skipped entirely when SKIP_BUILD=1.
docker_build() {
  if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    log_info "docker_build: SKIP_BUILD=1, skipping build"
    return 0
  fi

  if (( $# < 2 )); then
    log_error "docker_build: usage: docker_build <context_dir> <primary_tag> [<additional_tag>...]"
    return 2
  fi

  local context_dir="$1"
  shift

  if [[ ! -d "$context_dir" ]]; then
    log_error "docker_build: context directory does not exist: $context_dir"
    return 1
  fi

  local build_args=()
  if [[ -n "${PIP_INDEX_URL:-}" ]]; then
    build_args+=(--build-arg "PIP_INDEX_URL=${PIP_INDEX_URL}")
  fi
  if [[ -n "${PIP_TRUSTED_HOST:-}" ]]; then
    build_args+=(--build-arg "PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}")
  fi

  local tag_args=()
  local tag
  for tag in "$@"; do
    tag_args+=(-t "$tag")
  done

  local platform_args=()
  if [[ -n "${DOCKER_BUILD_PLATFORM:-}" ]]; then
    platform_args+=(--platform "${DOCKER_BUILD_PLATFORM}")
  fi

  log_info "docker_build: building $context_dir -> ${*}"
  docker build "${platform_args[@]}" "${build_args[@]}" "${tag_args[@]}" "$context_dir"
}
