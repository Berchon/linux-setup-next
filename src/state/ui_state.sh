#!/usr/bin/env bash

readonly UI_STATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly UI_STATE_CONFIG_FILE="${UI_STATE_ROOT}/config/ui.conf"
readonly UI_STATE_CONFIG_EXAMPLE_FILE="${UI_STATE_ROOT}/config/ui.conf.example"

declare -g ui_state_config_loaded=0
declare -g ui_state_config_load_count=0
declare -g ui_state_config_source_path=""

declare -g ui_state_last_error=""

ui_state_reset() {
  ui_state_config_loaded=0
  ui_state_config_load_count=0
  ui_state_config_source_path=""
  ui_state_last_error=""

  config_loader_reset_raw
  config_schema_reset_values
}

ui_state_resolve_config_path() {
  local preferred_path="$1"

  if [[ -n "${preferred_path}" ]]; then
    printf '%s' "${preferred_path}"
    return 0
  fi

  if [[ -f "${UI_STATE_CONFIG_FILE}" ]]; then
    printf '%s' "${UI_STATE_CONFIG_FILE}"
    return 0
  fi

  printf '%s' "${UI_STATE_CONFIG_EXAMPLE_FILE}"
  return 0
}

ui_state_boot_config() {
  local preferred_path="${1:-}"
  local config_path=""

  if [[ "${ui_state_config_loaded}" -eq 1 ]]; then
    return 0
  fi

  config_path="$(ui_state_resolve_config_path "${preferred_path}")"

  if ! config_loader_load_file "${config_path}"; then
    ui_state_last_error="${config_loader_last_error}"
    return 1
  fi

  config_schema_resolve_from_raw

  ui_state_config_loaded=1
  ui_state_config_load_count=$((ui_state_config_load_count + 1))
  ui_state_config_source_path="${config_path}"
  return 0
}

ui_state_get_config() {
  local key="$1"
  local fallback="${2:-}"

  config_schema_get_value "${key}" "${fallback}"
}
