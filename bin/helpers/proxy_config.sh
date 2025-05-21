#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib.sh"

MANIFEST="manifest.yml"
TEMPLATE_PATH="tsdproxy/tsdproxy.routes.json.template"
OUTPUT_PATH="tsdproxy/tsdproxy.routes.json"

if [[ -f "$TEMPLATE_PATH" ]]; then
  log_info "🔐 Injecting tsdproxy.routes.json from template"
  op inject -i "$TEMPLATE_PATH" -o "$OUTPUT_PATH"
else
  log_warn "⚠️  No tsdproxy.routes.json.template found at $TEMPLATE_PATH"
fi

log_success "✅ Tailscale proxy config written to $OUTPUT_PATH"

# Restart tsdproxy if it's running
if docker ps --format '{{.Names}}' | grep -q '^tsdproxy$'; then
  log_info "♻️ Restarting tsdproxy..."
  docker restart tsdproxy
fi
