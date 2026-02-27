#!/usr/bin/env bash

if [[ -z "${modal_state_module_loaded:-}" ]]; then
  modal_state_module_loaded=1

  modal_state_active=0
  modal_state_type=""
  modal_state_title=""
  modal_state_message=""
fi

modal_state_reset() {
  modal_state_active=0
  modal_state_type=""
  modal_state_title=""
  modal_state_message=""
}

modal_state_is_active() {
  printf '%s\n' "${modal_state_active}"
}

modal_state_blocks_background_input() {
  printf '%s\n' "${modal_state_active}"
}

modal_state_open_text() {
  local title="$1"
  local message="$2"

  modal_state_active=1
  modal_state_type="text"
  modal_state_title="${title}"
  modal_state_message="${message}"
}

modal_state_close() {
  modal_state_reset
}
