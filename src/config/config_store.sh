#!/usr/bin/env bash

declare -g config_store_last_error=""

config_store_write_file() {
  local target_path="$1"
  local target_dir=""
  local temp_path=""
  local key=""
  local value=""

  config_store_last_error=""

  if [[ -z "${target_path}" ]]; then
    config_store_last_error="config_store: empty target path"
    return 1
  fi

  target_dir="$(dirname "${target_path}")"
  if [[ ! -d "${target_dir}" ]]; then
    config_store_last_error="config_store: missing directory '${target_dir}'"
    return 1
  fi

  config_schema_init
  temp_path="$(mktemp "${target_path}.tmp.XXXXXX")" || {
    config_store_last_error="config_store: cannot create temporary file for '${target_path}'"
    return 1
  }

  for key in "${CONFIG_SCHEMA_KEYS[@]}"; do
    value="$(config_schema_get_value "${key}" "${CONFIG_SCHEMA_DEFAULTS[${key}]}")"
    printf '%s=%s\n' "${key}" "${value}" >> "${temp_path}" || {
      rm -f "${temp_path}"
      config_store_last_error="config_store: failed writing '${target_path}'"
      return 1
    }
  done

  if ! mv "${temp_path}" "${target_path}"; then
    rm -f "${temp_path}"
    config_store_last_error="config_store: failed committing '${target_path}'"
    return 1
  fi
}
