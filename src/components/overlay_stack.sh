#!/usr/bin/env bash

overlay_resolve_modal_toast_order() {
  local modal_active="$1"
  local toast_active="$2"
  local modal_seq="${3:-0}"
  local toast_seq="${4:-0}"

  if [[ "${modal_active}" == "1" && "${toast_active}" == "1" ]]; then
    if ((toast_seq >= modal_seq)); then
      printf 'modal\ntoast\n'
    else
      printf 'toast\nmodal\n'
    fi
    return 0
  fi

  if [[ "${modal_active}" == "1" ]]; then
    printf 'modal\n'
  fi
  if [[ "${toast_active}" == "1" ]]; then
    printf 'toast\n'
  fi
}

overlay_render_modal_toast_from_state() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local modal_width="$4"
  local modal_height="$5"
  local modal_active="0"
  local toast_active="0"
  local modal_seq=0
  local toast_seq=0
  local layer=""

  if ! declare -F modal_state_is_active >/dev/null; then
    return 1
  fi
  if ! declare -F toast_state_is_active >/dev/null; then
    return 1
  fi
  if ! declare -F toast_render_stack_from_state >/dev/null; then
    return 1
  fi
  if ! declare -F modal_render_from_state >/dev/null; then
    return 1
  fi
  if ! declare -F modal_state_get_overlay_seq >/dev/null; then
    return 1
  fi
  if ! declare -F toast_state_get_overlay_seq >/dev/null; then
    return 1
  fi

  modal_active="$(modal_state_is_active)"
  toast_active="$(toast_state_is_active)"
  modal_seq="$(modal_state_get_overlay_seq)"
  toast_seq="$(toast_state_get_overlay_seq)"

  if [[ "${toast_active}" != "1" ]]; then
    toast_render_stack_from_state "${buffer_name}" "${screen_width}" "${screen_height}" || return 1
  fi
  if [[ "${modal_active}" != "1" ]]; then
    modal_render_from_state \
      "${buffer_name}" \
      "${screen_width}" \
      "${screen_height}" \
      "${modal_width}" \
      "${modal_height}" \
      "${modal_active}" \
      "${modal_state_type}" \
      "${modal_state_title}" \
      "${modal_state_message}" \
      "${modal_state_confirm_label}" \
      "${modal_state_cancel_label}" \
      "${modal_state_focus_button}" || return 1
  fi

  while IFS= read -r layer; do
    case "${layer}" in
      modal)
        modal_render_from_state \
          "${buffer_name}" \
          "${screen_width}" \
          "${screen_height}" \
          "${modal_width}" \
          "${modal_height}" \
          "${modal_active}" \
          "${modal_state_type}" \
          "${modal_state_title}" \
          "${modal_state_message}" \
          "${modal_state_confirm_label}" \
          "${modal_state_cancel_label}" \
          "${modal_state_focus_button}" || return 1
        ;;
      toast)
        toast_render_stack_from_state "${buffer_name}" "${screen_width}" "${screen_height}" || return 1
        ;;
    esac
  done < <(overlay_resolve_modal_toast_order "${modal_active}" "${toast_active}" "${modal_seq}" "${toast_seq}")
}
