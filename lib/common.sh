#!/usr/bin/env bash
# Cross-cloud helpers: logging, prompts, image tagging, prerequisites.
# Source, do not execute.

if [[ "${LIB_COMMON_SOURCED:-}" == "1" ]]; then
  return 0
fi
LIB_COMMON_SOURCED=1

if [[ -t 1 ]]; then
  _COLOR_RESET=$'\033[0m'
  _COLOR_BLUE=$'\033[34m'
  _COLOR_YELLOW=$'\033[33m'
  _COLOR_RED=$'\033[31m'
  _COLOR_GREEN=$'\033[32m'
else
  _COLOR_RESET=""
  _COLOR_BLUE=""
  _COLOR_YELLOW=""
  _COLOR_RED=""
  _COLOR_GREEN=""
fi

log_info()    { printf '%s[info]%s %s\n'    "$_COLOR_BLUE"   "$_COLOR_RESET" "$*" >&2; }
log_warn()    { printf '%s[warn]%s %s\n'    "$_COLOR_YELLOW" "$_COLOR_RESET" "$*" >&2; }
log_error()   { printf '%s[error]%s %s\n'   "$_COLOR_RED"    "$_COLOR_RESET" "$*" >&2; }
log_success() { printf '%s[ ok ]%s %s\n'    "$_COLOR_GREEN"  "$_COLOR_RESET" "$*" >&2; }

require_command() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    log_error "Missing required command(s): ${missing[*]}"
    return 1
  fi
}

resolve_repo_root() {
  git rev-parse --show-toplevel
}

# Prints the image tag: short git SHA, plus `-dirty` when the working tree has
# uncommitted changes. Set ALLOW_DIRTY=1 to strip the suffix.
compute_image_tag() {
  local sha
  sha="$(git rev-parse --short HEAD 2>/dev/null)" || {
    log_error "compute_image_tag: not inside a git repository"
    return 1
  }

  if ! git diff-index --quiet HEAD -- 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
    if [[ "${ALLOW_DIRTY:-0}" == "1" ]]; then
      printf '%s\n' "$sha"
    else
      printf '%s-dirty\n' "$sha"
    fi
  else
    printf '%s\n' "$sha"
  fi
}

# Interactive y/N prompt. Returns 0 on yes, 1 on no. Bypassed with AUTO_APPROVE=1.
confirm() {
  local prompt="${1:-Continue?}"
  if [[ "${AUTO_APPROVE:-0}" == "1" ]]; then
    log_info "$prompt [auto-approved]"
    return 0
  fi
  local reply
  read -r -p "$prompt [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}
