#!/usr/bin/env bash

if [[ -z "${menu_state_module_loaded:-}" ]]; then
  menu_state_module_loaded=1

  declare -ag menu_state_node_ids=()
  declare -Ag menu_state_node_parent=()
  declare -Ag menu_state_node_label=()
  declare -Ag menu_state_node_desc=()
  declare -Ag menu_state_node_action=()
  declare -Ag menu_state_children=()
fi

menu_state_reset() {
  menu_state_node_ids=()
  menu_state_node_parent=()
  menu_state_node_label=()
  menu_state_node_desc=()
  menu_state_node_action=()
  menu_state_children=()
}

menu_state_parent_key() {
  local parent_id="$1"

  if [[ -z "${parent_id}" ]]; then
    printf '__root__\n'
    return 0
  fi

  printf '%s\n' "${parent_id}"
}

menu_state_has_node() {
  local node_id="$1"
  [[ -n "${node_id}" ]] || return 1
  [[ -v "menu_state_node_parent[${node_id}]" ]]
}

menu_state_node_count() {
  printf '%s\n' "${#menu_state_node_ids[@]}"
}

menu_state_append_child() {
  local parent_id="$1"
  local child_id="$2"
  local parent_key=""
  local current_children=""

  parent_key="$(menu_state_parent_key "${parent_id}")"
  current_children="${menu_state_children[${parent_key}]:-}"

  if [[ -z "${current_children}" ]]; then
    menu_state_children["${parent_key}"]="${child_id}"
    return 0
  fi

  menu_state_children["${parent_key}"]+=" ${child_id}"
}

menu_state_add_node() {
  local node_id="$1"
  local parent_id="$2"
  local label="$3"
  local description="${4:-}"
  local action="${5:-}"

  if [[ -z "${node_id}" ]] || [[ -z "${label}" ]]; then
    return 1
  fi

  if menu_state_has_node "${node_id}"; then
    return 1
  fi

  if [[ -n "${parent_id}" ]] && ! menu_state_has_node "${parent_id}"; then
    return 1
  fi

  menu_state_node_ids+=("${node_id}")
  menu_state_node_parent["${node_id}"]="${parent_id}"
  menu_state_node_label["${node_id}"]="${label}"
  menu_state_node_desc["${node_id}"]="${description}"
  menu_state_node_action["${node_id}"]="${action}"

  menu_state_append_child "${parent_id}" "${node_id}"
}

menu_state_get_parent() {
  local node_id="$1"
  menu_state_has_node "${node_id}" || return 1
  printf '%s\n' "${menu_state_node_parent[${node_id}]}"
}

menu_state_get_label() {
  local node_id="$1"
  menu_state_has_node "${node_id}" || return 1
  printf '%s\n' "${menu_state_node_label[${node_id}]}"
}

menu_state_get_desc() {
  local node_id="$1"
  menu_state_has_node "${node_id}" || return 1
  printf '%s\n' "${menu_state_node_desc[${node_id}]}"
}

menu_state_get_action() {
  local node_id="$1"
  menu_state_has_node "${node_id}" || return 1
  printf '%s\n' "${menu_state_node_action[${node_id}]}"
}

menu_state_get_node() {
  local node_id="$1"
  menu_state_has_node "${node_id}" || return 1

  printf '%s|%s|%s|%s|%s\n' \
    "${node_id}" \
    "${menu_state_node_parent[${node_id}]}" \
    "${menu_state_node_label[${node_id}]}" \
    "${menu_state_node_desc[${node_id}]}" \
    "${menu_state_node_action[${node_id}]}"
}

menu_state_get_children() {
  local parent_id="${1:-}"
  local parent_key=""

  parent_key="$(menu_state_parent_key "${parent_id}")"
  printf '%s\n' "${menu_state_children[${parent_key}]:-}"
}
