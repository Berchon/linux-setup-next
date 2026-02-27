#!/usr/bin/env bash

if [[ -z "${toast_state_module_loaded:-}" ]]; then
  toast_state_module_loaded=1

  toast_state_active=0
  toast_state_current_severity=""
  toast_state_current_message=""
  toast_state_current_ttl_ms=0

  declare -ag toast_state_queue_severity=()
  declare -ag toast_state_queue_message=()
  declare -ag toast_state_queue_ttl_ms=()
fi

toast_state_reset() {
  toast_state_active=0
  toast_state_current_severity=""
  toast_state_current_message=""
  toast_state_current_ttl_ms=0
  toast_state_queue_severity=()
  toast_state_queue_message=()
  toast_state_queue_ttl_ms=()
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
  local ttl_ms="$3"
  local index=0

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
