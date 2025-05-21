#!/usr/bin/env bash
set -euo pipefail

log_info()    { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
log_warn()    { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Required tool '$1' is not installed or not in PATH."
    exit 1
  fi
}

validate_connect_env_vars() {
  : "${OP_CONNECT_HOST:?Must set OP_CONNECT_HOST}"
  : "${OP_CONNECT_TOKEN:?Must set OP_CONNECT_TOKEN}"
}

validate_compose_file() {
  local path="$1"
  local file="$2"
  if [[ ! -f "$path/$file" ]]; then
    log_error "Missing docker-compose file: $path/$file"
    exit 1
  fi
}

resolve_secret() {
  local ref="$1"
  if [[ "$ref" =~ ^op:// ]]; then
    op read "$ref"
  else
    echo "$ref"
  fi
}

resolve_expose_port() {
  local index="$1"
  local name="$2"

  local override
  override=$(yq e '.castle.projects[$index].expose_port // ""' "$MANIFEST")
  if [[ -n "$override" && "$override" != "null" ]]; then
    echo "$override"
  else
    echo $((4000 + index))
  fi
}

resolve_source_path() {
  local index="$1"
  local app_name="$2"

  local source_type
  source_type=$(yq e ".castle.projects[$index].source.type" "$MANIFEST")
  local path
  path=$(yq e ".castle.projects[${index}].source.path // \"\"" "$MANIFEST")
  if [[ "$source_type" == "local" || "$source_type" == "git" ]]; then
    if [[ "$path" == "null" || -z "$path" ]]; then
      log_error "Missing source.path for $app_name"
      exit 1
    fi
    echo "$path"
  else
    echo "."  # no path needed for image-based containers
  fi
}
