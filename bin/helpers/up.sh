#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib.sh"

MANIFEST="manifest.yml"
validate_connect_env_vars
require_tool yq
require_tool git
require_tool docker

project_count=$(yq e '.castle.projects | length' "$MANIFEST")
for i in $(seq 0 $((project_count - 1))); do
  name=$(yq e ".castle.projects[$i].name" "$MANIFEST")
  path=$(resolve_source_path "$i" "$name")
  source_type=$(yq e ".castle.projects[$i].source.type" "$MANIFEST")
  compose_file=$(yq e ".castle.projects[$i].compose // \"docker-compose.yml\"" "$MANIFEST")

  env_file=$(resolve_secret "$(yq e '.castle.projects[$i].env // ""' "$MANIFEST")")
  port=$(resolve_expose_port "$i" "$name")

  secret_ref=$(yq e '.castle.projects[$i].secret_source // ""' "$MANIFEST")
  if [[ -n "$secret_ref" ]]; then
    log_info "🔐 Injecting secrets.json for $name"
    op read "$secret_ref" > "$path/secrets.json"
  fi

  if [[ "$source_type" == "git" ]]; then
    repo_url=$(yq e ".castle.projects[$i].source.url" "$MANIFEST")
    auth_type=$(yq e '.castle.projects[$i].source.auth.type // ""' "$MANIFEST")
    if [[ "$auth_type" == "oauth" ]]; then
      token=$(resolve_secret "$(yq e ".castle.projects[$i].source.auth.token" "$MANIFEST")")
      repo_url="https://oauth:${token}@${repo_url#https://}"
    elif [[ "$auth_type" == "basic" ]]; then
      user=$(resolve_secret "$(yq e ".castle.projects[$i].source.auth.username" "$MANIFEST")")
      token=$(resolve_secret "$(yq e ".castle.projects[$i].source.auth.token" "$MANIFEST")")
      repo_url="https://${user}:${token}@${repo_url#https://}"
    fi
    if [[ ! -d "$path/.git" ]]; then
      log_info "📦 Cloning $repo_url"
      git clone "$repo_url" "$path"
    else
      log_info "✅ Repo already cloned: $path"
    fi
  elif [[ "$source_type" == "local" ]]; then
    log_info "📂 Using local path: $path"
    validate_compose_file "$path" "$compose_file"
    log_info "🔼 Starting $name"
    pushd "$path" >/dev/null
    docker compose -f "$compose_file" ${env_file:+--env-file "$env_file"} up -d "$@"
    popd >/dev/null
  elif [[ "$source_type" == "image" ]]; then
    image=$(yq e ".castle.projects[$i].source.image" "$MANIFEST")
    command=$(yq e '.castle.projects[$i].command // ""' "$MANIFEST")
    log_info "🐳 Running image $image for $name"
    docker run -d --name "$name" -p "${port}:80" $image $command
  else
    log_error "Unsupported source type: $source_type"
    exit 1
  fi
done

# Start global services
if [[ "$(yq e '.castle.proxy' "$MANIFEST")" == "true" ]]; then
  log_info "🚀 Starting tsdproxy..."
  pushd tsdproxy > /dev/null
  docker compose up -d
  popd > /dev/null
fi

if [[ "$(yq e '.castle.metrics' "$MANIFEST")" == "true" ]]; then
  log_info "📈 Starting metrics stack..."
  pushd metrics > /dev/null
  docker compose up -d
  popd > /dev/null
fi

log_info "🔁 Updating tsdproxy routes"
"$(dirname "$0")/proxy_config.sh"
