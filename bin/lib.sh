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
  if [[ -z "$ref" ]]; then
    echo ""
    return
  fi

  # If it's not a 1Password ref, just return it
  if [[ ! "$ref" =~ ^op:// ]]; then
    echo "$ref"
    return
  fi

  local use_secrets
  use_secrets=$(yq e '.castle.secrets // false' "$MANIFEST")

   if [[ "$use_secrets" == "true" ]]; then
   ROOT_DIR="$(dirname "$(realpath "$0")")"
    # Ensure 1Password Connect is running
    if ! docker ps --format '{{.Names}}' | grep -q '^op-connect$'; then
      log_info "🔐 Starting 1Password Connect..."
      pushd secrets >/dev/null
      docker compose up -f "$ROOT_DIR/secrets/docker-compose.yaml" -d
    else
      log_info "✅ 1Password Connect is already running."
    fi

    if ! curl -sf "$OP_CONNECT_HOST/v1/status" > /dev/null; then
      log_error "❌ Failed to reach 1Password Connect at $OP_CONNECT_HOST"
      exit 1
    fi

    op read "$ref"
  else
    local key="${ref##*/}"
    read -p "🔐 Enter value for $key: " value
    echo "$value"
  fi
}

resolve_source_path() {
  local index="$1"
  local app_name="$2"
  local source_type
  source_type=$(yq e ".castle.projects[$index].source.type" "$MANIFEST")
  local path
  path=$(yq e ".castle.projects[$index].source.path // \"\"" "$MANIFEST")

  if [[ "$source_type" == "image" ]]; then
    echo ""  # No path needed for images
    return
  fi

  if [[ -z "$path" || "$path" == "null" ]]; then
    log_error "Missing source.path for $app_name"
    exit 1
  fi

  echo "$path"
}

ensure_1password_connect_running() {
  # Check if secrets are enabled in the manifest
  use_secrets=$(yq e '.castle.secrets // false' "$MANIFEST")

  # If secrets are enabled, ensure the Connect container is running
  if [[ "$use_secrets" == "true" ]]; then
    if ! docker ps --format '{{.Names}}' | grep -q '^op-connect$'; then
      log_info "🔐 Starting 1Password Connect..."
      docker compose up -f "../secrets/docker-compose.yaml" -d
    else
      log_info "✅ 1Password Connect is already running."
  fi
fi

}

get_repo_root() {
  local source="${BASH_SOURCE[0]}"
  while [ -h "$source" ]; do
    dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")/.." >/dev/null 2>&1 && pwd
}
