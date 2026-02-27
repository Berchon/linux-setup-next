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
  ui_state_apply_runtime_language || return 1
  ui_state_apply_runtime_theme || return 1
  return 0
}

ui_state_apply_runtime_language() {
  local language=""

  if ! declare -F i18n_load_catalog >/dev/null; then
    return 0
  fi

  language="$(config_schema_get_value "app.language" "pt")"
  i18n_load_catalog "${language}"
  return 0
}

ui_state_get_config() {
  local key="$1"
  local fallback="${2:-}"

  config_schema_get_value "${key}" "${fallback}"
}

ui_state_apply_runtime_theme() {
  local toast_ttl_ms=""

  if ! declare -F theme_config_toast_ttl_ms >/dev/null; then
    return 0
  fi

  if ! declare -F toast_state_set_default_ttl_ms >/dev/null; then
    return 0
  fi

  toast_ttl_ms="$(theme_config_toast_ttl_ms)"
  if ! toast_state_set_default_ttl_ms "${toast_ttl_ms}"; then
    ui_state_last_error="ui_state: failed to apply runtime toast ttl"
    return 1
  fi

  return 0
}

ui_state_set_config() {
  local key="$1"
  local value="$2"

  config_schema_set_value "${key}" "${value}"
}

ui_state_persist_config() {
  local target_path="${1:-}"

  if [[ -z "${target_path}" ]]; then
    target_path="${ui_state_config_source_path}"
  fi

  if [[ -z "${target_path}" ]]; then
    target_path="$(ui_state_resolve_config_path "")"
  fi

  if ! config_store_write_file "${target_path}"; then
    ui_state_last_error="${config_store_last_error}"
    return 1
  fi

  ui_state_config_source_path="${target_path}"
}

ui_state_apply_config_input() {
  local node_id="$1"
  local raw_input="$2"
  local persist_path="${3:-}"
  local config_key=""
  local previous_value=""
  local current_value=""

  if ! declare -F config_menu_state_apply_input >/dev/null; then
    ui_state_last_error="ui_state: config menu integration is unavailable"
    return 1
  fi

  config_key="$(config_menu_state_node_key "${node_id}")" || return 1
  previous_value="$(config_schema_get_value "${config_key}")"

  if ! config_menu_state_apply_input "${node_id}" "${raw_input}"; then
    return 1
  fi

  if ! ui_state_persist_config "${persist_path}"; then
    config_schema_set_value "${config_key}" "${previous_value}" || true
    if declare -F toast_state_enqueue >/dev/null; then
      toast_state_enqueue "error" "Failed to save ${config_key}"
    fi
    return 1
  fi

  if declare -F toast_state_enqueue >/dev/null; then
    current_value="$(config_schema_get_value "${config_key}")"
    toast_state_enqueue "success" "Saved ${config_key}=${current_value}"
  fi

  if [[ "${config_key}" == "app.language" ]]; then
    ui_state_apply_runtime_language || true
  fi

  ui_state_apply_runtime_theme || true
}
