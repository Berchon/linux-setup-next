#!/usr/bin/env bash

if [[ -z "${modal_state_module_loaded:-}" ]]; then
  modal_state_module_loaded=1

  modal_state_active=0
  modal_state_overlay_seq=0
  modal_state_type=""
  modal_state_title=""
  modal_state_message=""
  modal_state_confirm_label=""
  modal_state_cancel_label=""
  modal_state_focus_button=""
  modal_state_result=""
fi

overlay_state_next_seq() {
  if [[ -z "${overlay_state_seq_counter:-}" ]]; then
    overlay_state_seq_counter=0
  fi

  overlay_state_seq_counter=$((overlay_state_seq_counter + 1))
  REPLY="${overlay_state_seq_counter}"
}

modal_state_reset() {
  modal_state_active=0
  modal_state_overlay_seq=0
  modal_state_type=""
  modal_state_title=""
  modal_state_message=""
  modal_state_confirm_label=""
  modal_state_cancel_label=""
  modal_state_focus_button=""
  modal_state_result=""
}

modal_state_is_active() {
  printf '%s\n' "${modal_state_active}"
}

modal_state_get_overlay_seq() {
  printf '%s\n' "${modal_state_overlay_seq}"
}

modal_state_blocks_background_input() {
  printf '%s\n' "${modal_state_active}"
}

modal_state_open_text() {
  local title="$1"
  local message="$2"

  modal_state_active=1
  overlay_state_next_seq
  modal_state_overlay_seq="${REPLY}"
  modal_state_type="text"
  modal_state_title="${title}"
  modal_state_message="${message}"
}

modal_state_normalize_focus_button() {
  local focus="${1:-confirm}"

  case "${focus}" in
    confirm|cancel)
      printf '%s\n' "${focus}"
      ;;
    *)
      return 1
      ;;
  esac
}

modal_state_open_confirm() {
  local title="$1"
  local message="$2"
  local confirm_label="${3:-Confirm}"
  local cancel_label="${4:-Cancel}"
  local focus_button="${5:-confirm}"

  focus_button="$(modal_state_normalize_focus_button "${focus_button}")" || return 1

  modal_state_active=1
  overlay_state_next_seq
  modal_state_overlay_seq="${REPLY}"
  modal_state_type="confirm"
  modal_state_title="${title}"
  modal_state_message="${message}"
  modal_state_confirm_label="${confirm_label}"
  modal_state_cancel_label="${cancel_label}"
  modal_state_focus_button="${focus_button}"
  modal_state_result=""
}

modal_state_set_confirm_focus() {
  local focus_button="$1"

  if [[ "${modal_state_type}" != "confirm" ]]; then
    return 1
  fi

  focus_button="$(modal_state_normalize_focus_button "${focus_button}")" || return 1
  modal_state_focus_button="${focus_button}"
}

modal_state_toggle_confirm_focus() {
  if [[ "${modal_state_type}" != "confirm" ]]; then
    return 1
  fi

  if [[ "${modal_state_focus_button}" == "confirm" ]]; then
    modal_state_focus_button="cancel"
  else
    modal_state_focus_button="confirm"
  fi
}

modal_state_resolve_confirm() {
  local action="$1"

  if [[ "${modal_state_type}" != "confirm" ]]; then
    return 1
  fi

  action="$(modal_state_normalize_focus_button "${action}")" || return 1
  modal_state_result="${action}"
  printf '%s\n' "${modal_state_result}"
  modal_state_close
}

modal_state_apply_confirm_action() {
  local action="$1"

  if [[ "${modal_state_type}" != "confirm" ]]; then
    return 1
  fi

  case "${action}" in
    focus_left|focus_right)
      modal_state_toggle_confirm_focus
      printf '%s\n' "${modal_state_focus_button}"
      ;;
    submit)
      modal_state_resolve_confirm "${modal_state_focus_button}"
      ;;
    cancel)
      modal_state_resolve_confirm "cancel"
      ;;
    *)
      return 1
      ;;
  esac
}

modal_state_close() {
  modal_state_reset
}
