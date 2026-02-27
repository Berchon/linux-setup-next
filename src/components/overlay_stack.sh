#!/usr/bin/env bash

overlay_resolve_modal_toast_order() {
  local modal_active="$1"
  local toast_active="$2"

  if [[ "${toast_active}" == "1" ]]; then
    printf 'toast\n'
  fi

  if [[ "${modal_active}" == "1" ]]; then
    printf 'modal\n'
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
  local layer=""
  local modal_type=""

  if ! declare -F modal_state_is_active >/dev/null; then
    return 1
  fi
  if ! declare -F toast_state_is_active >/dev/null; then
    return 1
  fi
  if ! declare -F toast_render_stack_from_state >/dev/null; then
    return 1
  fi
  if ! declare -F modal_render_text >/dev/null; then
    return 1
  fi
  if ! declare -F modal_render_confirm >/dev/null; then
    return 1
  fi

  modal_active="$(modal_state_is_active)"
  toast_active="$(toast_state_is_active)"

  while IFS= read -r layer; do
    case "${layer}" in
      toast)
        toast_render_stack_from_state "${buffer_name}" "${screen_width}" "${screen_height}" || return 1
        ;;
      modal)
        modal_type="${modal_state_type}"
        case "${modal_type}" in
          text)
            modal_render_text \
              "${buffer_name}" \
              "${screen_width}" \
              "${screen_height}" \
              "${modal_width}" \
              "${modal_height}" \
              "${modal_state_title}" \
              "${modal_state_message}" || return 1
            ;;
          confirm)
            modal_render_confirm \
              "${buffer_name}" \
              "${screen_width}" \
              "${screen_height}" \
              "${modal_width}" \
              "${modal_height}" \
              "${modal_state_title}" \
              "${modal_state_message}" \
              "${modal_state_confirm_label}" \
              "${modal_state_cancel_label}" \
              "${modal_state_focus_button}" || return 1
            ;;
          *)
            return 1
            ;;
        esac
        ;;
    esac
  done < <(overlay_resolve_modal_toast_order "${modal_active}" "${toast_active}")
}
