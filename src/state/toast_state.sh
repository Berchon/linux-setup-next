#!/usr/bin/env bash

if [[ -z "${toast_state_module_loaded:-}" ]]; then
  toast_state_module_loaded=1

  toast_state_default_ttl_ms=3000
  toast_state_active=0
  toast_state_current_severity=""
  toast_state_current_message=""
  toast_state_current_ttl_ms=0

  declare -ag toast_state_queue_severity=()
  declare -ag toast_state_queue_message=()
  declare -ag toast_state_queue_ttl_ms=()
fi

toast_state_reset() {
  toast_state_default_ttl_ms=3000
  toast_state_active=0
  toast_state_current_severity=""
  toast_state_current_message=""
  toast_state_current_ttl_ms=0
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

toast_state_is_active() {
  printf '%s\n' "${toast_state_active}"
}

toast_state_enqueue() {
  local severity="$1"
  local message="$2"
  local ttl_ms="${3:-}"
  local index=0

  ttl_ms="$(toast_state_resolve_ttl_ms "${ttl_ms}")"

  index="${#toast_state_queue_message[@]}"
  toast_state_queue_severity[index]="${severity}"
  toast_state_queue_message[index]="${message}"
  toast_state_queue_ttl_ms[index]="${ttl_ms}"
}

toast_state_activate_next() {
  if ((toast_state_active == 1)); then
    return 1
  fi

  if ((${#toast_state_queue_message[@]} == 0)); then
    return 1
  fi

  toast_state_current_severity="${toast_state_queue_severity[0]}"
  toast_state_current_message="${toast_state_queue_message[0]}"
  toast_state_current_ttl_ms="${toast_state_queue_ttl_ms[0]}"
  toast_state_active=1

  unset 'toast_state_queue_severity[0]'
  unset 'toast_state_queue_message[0]'
  unset 'toast_state_queue_ttl_ms[0]'
  toast_state_queue_severity=("${toast_state_queue_severity[@]}")
  toast_state_queue_message=("${toast_state_queue_message[@]}")
  toast_state_queue_ttl_ms=("${toast_state_queue_ttl_ms[@]}")
}

toast_state_dismiss_active() {
  toast_state_active=0
  toast_state_current_severity=""
  toast_state_current_message=""
  toast_state_current_ttl_ms=0
}
