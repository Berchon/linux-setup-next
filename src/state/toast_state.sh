#!/usr/bin/env bash

if [[ -z "${toast_state_module_loaded:-}" ]]; then
  toast_state_module_loaded=1

  toast_state_default_ttl_ms=3000
  toast_state_max_visible=3
  toast_state_overlay_seq=0

  declare -ag toast_state_visible_severity=()
  declare -ag toast_state_visible_message=()
  declare -ag toast_state_visible_ttl_ms=()

  declare -ag toast_state_queue_severity=()
  declare -ag toast_state_queue_message=()
  declare -ag toast_state_queue_ttl_ms=()
fi

overlay_state_next_seq() {
  if [[ -z "${overlay_state_seq_counter:-}" ]]; then
    overlay_state_seq_counter=0
  fi

  overlay_state_seq_counter=$((overlay_state_seq_counter + 1))
  REPLY="${overlay_state_seq_counter}"
}

toast_state_reset() {
  toast_state_default_ttl_ms=3000
  toast_state_max_visible=3
  toast_state_overlay_seq=0
  toast_state_visible_severity=()
  toast_state_visible_message=()
  toast_state_visible_ttl_ms=()
  toast_state_queue_severity=()
  toast_state_queue_message=()
  toast_state_queue_ttl_ms=()
}

toast_state_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

toast_state_set_default_ttl_ms() {
  local ttl_ms="$1"

  if ! toast_state_is_positive_integer "${ttl_ms}"; then
    return 1
  fi

  toast_state_default_ttl_ms="${ttl_ms}"
}

toast_state_get_default_ttl_ms() {
  printf '%s\n' "${toast_state_default_ttl_ms}"
}

toast_state_set_max_visible() {
  local max_visible="$1"
  local index=0
  local overflow_severity=""
  local overflow_message=""
  local overflow_ttl_ms=0

  if ! toast_state_is_positive_integer "${max_visible}"; then
    return 1
  fi

  toast_state_max_visible="${max_visible}"

  while ((${#toast_state_visible_message[@]} > toast_state_max_visible)); do
    index=$((${#toast_state_visible_message[@]} - 1))
    overflow_severity="${toast_state_visible_severity[index]}"
    overflow_message="${toast_state_visible_message[index]}"
    overflow_ttl_ms="${toast_state_visible_ttl_ms[index]}"

    unset 'toast_state_visible_severity[index]'
    unset 'toast_state_visible_message[index]'
    unset 'toast_state_visible_ttl_ms[index]'
    toast_state_visible_severity=("${toast_state_visible_severity[@]}")
    toast_state_visible_message=("${toast_state_visible_message[@]}")
    toast_state_visible_ttl_ms=("${toast_state_visible_ttl_ms[@]}")

    toast_state_queue_severity=("${overflow_severity}" "${toast_state_queue_severity[@]}")
    toast_state_queue_message=("${overflow_message}" "${toast_state_queue_message[@]}")
    toast_state_queue_ttl_ms=("${overflow_ttl_ms}" "${toast_state_queue_ttl_ms[@]}")
  done
}

toast_state_get_max_visible() {
  printf '%s\n' "${toast_state_max_visible}"
}

toast_state_resolve_ttl_ms() {
  local requested_ttl_ms="${1:-}"

  if toast_state_is_positive_integer "${requested_ttl_ms}"; then
    printf '%s\n' "${requested_ttl_ms}"
    return 0
  fi

  printf '%s\n' "${toast_state_default_ttl_ms}"
}

toast_state_queue_size() {
  printf '%s\n' "${#toast_state_queue_message[@]}"
}

toast_state_visible_count() {
  printf '%s\n' "${#toast_state_visible_message[@]}"
}

toast_state_is_active() {
  if ((${#toast_state_visible_message[@]} > 0)); then
    printf '1\n'
    return 0
  fi

  printf '0\n'
}

toast_state_get_overlay_seq() {
  printf '%s\n' "${toast_state_overlay_seq}"
}

toast_state_get_visible() {
  local index="$1"

  if [[ ! "${index}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  if ((index >= ${#toast_state_visible_message[@]})); then
    return 1
  fi

  printf '%s|%s|%s\n' \
    "${toast_state_visible_severity[index]}" \
    "${toast_state_visible_message[index]}" \
    "${toast_state_visible_ttl_ms[index]}"
}

toast_state_insert_visible_front() {
  local severity="$1"
  local message="$2"
  local ttl_ms="$3"

  toast_state_visible_severity=("${severity}" "${toast_state_visible_severity[@]}")
  toast_state_visible_message=("${message}" "${toast_state_visible_message[@]}")
  toast_state_visible_ttl_ms=("${ttl_ms}" "${toast_state_visible_ttl_ms[@]}")
  overlay_state_next_seq
  toast_state_overlay_seq="${REPLY}"
}

toast_state_dequeue_first_queue_entry() {
  local severity_var_name="$1"
  local message_var_name="$2"
  local ttl_var_name="$3"

  if ((${#toast_state_queue_message[@]} == 0)); then
    return 1
  fi

  printf -v "${severity_var_name}" '%s' "${toast_state_queue_severity[0]}"
  printf -v "${message_var_name}" '%s' "${toast_state_queue_message[0]}"
  printf -v "${ttl_var_name}" '%s' "${toast_state_queue_ttl_ms[0]}"

  unset 'toast_state_queue_severity[0]'
  unset 'toast_state_queue_message[0]'
  unset 'toast_state_queue_ttl_ms[0]'
  toast_state_queue_severity=("${toast_state_queue_severity[@]}")
  toast_state_queue_message=("${toast_state_queue_message[@]}")
  toast_state_queue_ttl_ms=("${toast_state_queue_ttl_ms[@]}")
}

toast_state_promote_queue_head_if_possible() {
  local next_severity=""
  local next_message=""
  local next_ttl_ms=0

  if ((${#toast_state_visible_message[@]} >= toast_state_max_visible)); then
    return 0
  fi

  if ! toast_state_dequeue_first_queue_entry next_severity next_message next_ttl_ms; then
    return 0
  fi

  toast_state_insert_visible_front "${next_severity}" "${next_message}" "${next_ttl_ms}"
}

toast_state_enqueue() {
  local severity="$1"
  local message="$2"
  local ttl_ms="${3:-}"
  local index=0

  ttl_ms="$(toast_state_resolve_ttl_ms "${ttl_ms}")"

  if ((${#toast_state_visible_message[@]} < toast_state_max_visible)); then
    toast_state_insert_visible_front "${severity}" "${message}" "${ttl_ms}"
    return 0
  fi

  index="${#toast_state_queue_message[@]}"
  toast_state_queue_severity[index]="${severity}"
  toast_state_queue_message[index]="${message}"
  toast_state_queue_ttl_ms[index]="${ttl_ms}"
}

toast_state_activate_next() {
  local next_severity=""
  local next_message=""
  local next_ttl_ms=0

  if ((${#toast_state_visible_message[@]} > 0)); then
    return 1
  fi

  if ! toast_state_dequeue_first_queue_entry next_severity next_message next_ttl_ms; then
    return 1
  fi

  toast_state_insert_visible_front "${next_severity}" "${next_message}" "${next_ttl_ms}"
}

toast_state_dismiss_visible_at() {
  local index="$1"

  if [[ ! "${index}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  if ((index >= ${#toast_state_visible_message[@]})); then
    return 1
  fi

  unset 'toast_state_visible_severity[index]'
  unset 'toast_state_visible_message[index]'
  unset 'toast_state_visible_ttl_ms[index]'
  toast_state_visible_severity=("${toast_state_visible_severity[@]}")
  toast_state_visible_message=("${toast_state_visible_message[@]}")
  toast_state_visible_ttl_ms=("${toast_state_visible_ttl_ms[@]}")

  toast_state_promote_queue_head_if_possible
}

toast_state_dismiss_active() {
  if ((${#toast_state_visible_message[@]} == 0)); then
    return 1
  fi

  toast_state_dismiss_visible_at 0
}
