#!/usr/bin/env bash

if [[ -z "${config_menu_state_module_loaded:-}" ]]; then
  config_menu_state_module_loaded=1

  declare -ag config_menu_state_editable_nodes=()
  declare -Ag config_menu_state_node_to_key=()
fi

config_menu_state_reset() {
  config_menu_state_editable_nodes=()
  config_menu_state_node_to_key=()
}

config_menu_state_label_from_segment() {
  local segment="$1"
  segment="${segment//_/ }"
  printf '%s\n' "${segment}"
}

config_menu_state_group_node_id() {
  local path="$1"
  path="${path//[^a-zA-Z0-9_]/_}"
  printf 'cfg_group_%s\n' "${path}"
}

config_menu_state_key_node_id() {
  local key="$1"
  key="${key//[^a-zA-Z0-9_]/_}"
  printf 'cfg_key_%s\n' "${key}"
}

config_menu_state_register_group_path() {
  local root_id="$1"
  local path="$2"
  local parent_path="$3"
  local parent_id="$4"
  local node_id=""
  local label=""

  node_id="$(config_menu_state_group_node_id "${path}")"
  if menu_state_has_node "${node_id}"; then
    return 0
  fi

  if [[ -n "${parent_path}" ]]; then
    parent_id="$(config_menu_state_group_node_id "${parent_path}")"
  else
    parent_id="${root_id}"
  fi

  label="$(config_menu_state_label_from_segment "${path##*.}")"
  menu_state_add_node "${node_id}" "${parent_id}" "${label}" "" ""
}

config_menu_state_ensure_group_chain() {
  local root_id="$1"
  local key="$2"
  local segment_path=""
  local parent_path=""
  local segment=""
  local leaf_segment=""
  local -a segments=()

  IFS='.' read -r -a segments <<< "${key}"
  if ((${#segments[@]} < 2)); then
    REPLY="${root_id}"
    return 0
  fi

  leaf_segment="${segments[$((${#segments[@]} - 1))]}"

  for segment in "${segments[@]}"; do
    if [[ "${segment}" == "${leaf_segment}" ]] && [[ -n "${segment_path}" ]]; then
      break
    fi

    if [[ -z "${segment_path}" ]]; then
      segment_path="${segment}"
    else
      segment_path="${segment_path}.${segment}"
    fi

    config_menu_state_register_group_path "${root_id}" "${segment_path}" "${parent_path}" ""
    parent_path="${segment_path}"
  done

  if [[ -n "${parent_path}" ]]; then
    REPLY="$(config_menu_state_group_node_id "${parent_path}")"
    return 0
  fi

  REPLY="${root_id}"
}

config_menu_state_build_tree() {
  local root_id="${1:-settings}"
  local root_label="${2:-Settings}"
  local key=""
  local leaf_id=""
  local parent_id=""
  local leaf_label=""

  if ! declare -F menu_state_add_node >/dev/null; then
    return 1
  fi

  config_schema_init
  config_menu_state_reset

  if ! menu_state_has_node "${root_id}"; then
    menu_state_add_node "${root_id}" "" "${root_label}" "UI settings" ""
  fi

  for key in "${CONFIG_SCHEMA_KEYS[@]}"; do
    config_menu_state_ensure_group_chain "${root_id}" "${key}"
    parent_id="${REPLY}"
    leaf_id="$(config_menu_state_key_node_id "${key}")"
    leaf_label="$(config_menu_state_label_from_segment "${key##*.}")"

    menu_state_add_node "${leaf_id}" "${parent_id}" "${leaf_label}" "${key}" "config.edit"
    config_menu_state_editable_nodes+=("${leaf_id}")
    config_menu_state_node_to_key["${leaf_id}"]="${key}"
  done
}

config_menu_state_is_editable_node() {
  local node_id="$1"
  [[ -v "config_menu_state_node_to_key[${node_id}]" ]]
}

config_menu_state_node_key() {
  local node_id="$1"
  config_menu_state_is_editable_node "${node_id}" || return 1
  printf '%s\n' "${config_menu_state_node_to_key[${node_id}]}"
}
