#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib.sh"

MANIFEST="manifest.yml"
require_tool yq

project_count=$(yq e '.castle.projects | length' "$MANIFEST")
for i in $(seq 0 $((project_count - 1))); do
  name=$(yq e ".castle.projects[$i].name" "$MANIFEST")
  path=$(yq e ".castle.projects[$i].path" "$MANIFEST")
  compose_file=$(yq e ".castle.projects[$i].compose // \"docker-compose.yml\"" "$MANIFEST")

  if [[ -d "$path" ]]; then
    log_info "🔽 Stopping $name"
    pushd "$path" >/dev/null
    docker compose -f "$compose_file" down "$@"
    # Cleanup injected secrets.json if it exists
    if [[ -f "$path/secrets.json" ]]; then
      log_info "🧹 Removing injected secrets.json from $path"
      rm -f "$path/secrets.json"
    fi
    popd >/dev/null
  else
    log_warn "Skipping $name — path $path not found"
  fi
done


if [[ "$(yq e '.castle.proxy' "$MANIFEST")" == "true" ]]; then
  log_info "🧹 Stopping tsdproxy..."
  docker compose -f tsdproxy/docker-compose.yml down || true
fi

if [[ "$(yq e '.castle.metrics' "$MANIFEST")" == "true" ]]; then
  log_info "🧹 Stopping metrics stack..."
  docker compose -f metrics/docker-compose.yml down || true
fi
