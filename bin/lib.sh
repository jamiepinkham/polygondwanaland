# Final lib.sh would be here if needed


resolve_source_path() {
  local index="$1"
  local app_name="$2"

  local source_type
  source_type=$(yq e ".projects[$index].source.type" "$MANIFEST")
  local path
  path=$(yq e ".projects[$index].source.path" "$MANIFEST")

  if [[ "$source_type" == "null" || -z "$path" ]]; then
    log_error "Missing source.type or source.path for $app_name"
    exit 1
  fi

  echo "$path"
}
