#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-}"
shift || true

source "$(dirname "$0")/../lib.sh"

usage() {
  cat <<EOF
🏰 Polygondwanaland CLI - "castle"

Usage:
  castle.sh up [project] [-- docker-compose args...]
  castle.sh down [project] [-- docker-compose args...]
  castle.sh reload-proxy
  castle.sh proxy_page
  castle.sh secrets reveal <env_name> [-- op args...]
EOF
}

cmd_up() { ./bin/helpers/up.sh "$@"; }
cmd_down() { ./bin/helpers/down.sh "$@"; }
cmd_reload_proxy() { ./bin/helpers/proxy_config.sh; }

cmd_proxy_page() {
  local url="http://localhost:3000"
  log_info "🌐 Opening tsdproxy at $url"
  if command -v xdg-open &>/dev/null; then xdg-open "$url"
  elif command -v open &>/dev/null; then open "$url"
  elif grep -qi microsoft /proc/version 2>/dev/null; then powershell.exe start "$url"
  else log_warn "Manual URL: $url"; fi
}

cmd_secrets_reveal() {
  local env="${1:-}"; shift || true
  [[ -z "$env" ]] && log_error "Missing env name" && exit 1
  local template="environments/${env}/.env.template"
  local output="environments/${env}/.env"
  validate_connect_env_vars
  [[ ! -f "$template" ]] && log_error "Missing $template" && exit 1
  log_info "🔐 Injecting secrets for $env"
  op inject "$@" -i "$template" -o "$output"
  log_success "Secrets written to $output"
}

case "$COMMAND" in
  up) cmd_up "$@";;
  down) cmd_down "$@";;
  reload-proxy) cmd_reload_proxy;;
  proxy_page) cmd_proxy_page;;
  secrets)
    [[ "${1:-}" == "reveal" ]] && shift && cmd_secrets_reveal "$@" || { log_error "Unknown secrets subcommand"; usage; exit 1; }
    ;;
  *) usage; exit 1;;
esac
