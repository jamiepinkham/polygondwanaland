#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib.sh"

MANIFEST="manifest.yml"
TS_FRIENDLY_NAME="${TS_FRIENDLY_NAME:-myhost}"
OUTPUT="tsdproxy.routes.json"
routes=()

routes+=("{\"subdomain\":\"infra.grafana.${TS_FRIENDLY_NAME}\",\"target\":\"http://localhost:3000\"}")

project_count=$(yq e '.projects | length' "$MANIFEST")
for i in $(seq 0 $((project_count - 1))); do
  app=$(yq e ".projects[$i].name" "$MANIFEST")
  env_name_ref=$(yq e ".projects[$i].env_name // \"dev\"" "$MANIFEST")
  env_name=$(resolve_secret "$env_name_ref")
  port=$(resolve_expose_port "$i" "$app")

  routes+=("{\"subdomain\":\"${env_name}.${app}.${TS_FRIENDLY_NAME}\",\"target\":\"http://localhost:${port}\"}")
done

echo -e "{\n  \"routes\": [\n    $(IFS=,; echo "${routes[*]}")\n  ]\n}" > "$OUTPUT"
log_success "Tailscale proxy config written to $OUTPUT"

if docker ps --format '{{.Names}}' | grep -q '^tsdproxy$'; then
  log_info "♻️ Restarting tsdproxy..."
  docker restart tsdproxy
fi
