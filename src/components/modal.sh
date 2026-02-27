#!/usr/bin/env bash

if [[ -z "${modal_component_module_loaded:-}" ]]; then
  modal_component_module_loaded=1

  modal_render_cache_visible=0
  modal_render_cache_x=0
  modal_render_cache_y=0
  modal_render_cache_width=0
  modal_render_cache_height=0
fi

modal_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

modal_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

modal_reset_render_cache() {
  modal_render_cache_visible=0
  modal_render_cache_x=0
  modal_render_cache_y=0
  modal_render_cache_width=0
  modal_render_cache_height=0
}

modal_track_dirty_region() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"

  if [[ ! "${width}" =~ ^[0-9]+$ ]] || [[ ! "${height}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  if declare -F dirty_regions_add >/dev/null; then
    dirty_regions_add "${x}" "${y}" "${width}" "${height}"
  fi
}

modal_clear_cached_rect() {
  local buffer_name="$1"

  if ((modal_render_cache_visible == 0)); then
    return 0
  fi

  if ! declare -F cell_buffer_clear_rect >/dev/null; then
    return 1
  fi

  modal_track_dirty_region "${modal_render_cache_x}" "${modal_render_cache_y}" "${modal_render_cache_width}" "${modal_render_cache_height}" || return 1
  cell_buffer_clear_rect \
    "${buffer_name}" \
    "${modal_render_cache_x}" \
    "${modal_render_cache_y}" \
    "${modal_render_cache_width}" \
    "${modal_render_cache_height}"
}

modal_center_rect() {
  local screen_width="$1"
  local screen_height="$2"
  local width="$3"
  local height="$4"
  local x=0
  local y=0

  if ! modal_is_positive_integer "${screen_width}" || ! modal_is_positive_integer "${screen_height}"; then
    return 1
  fi

  if ! modal_is_positive_integer "${width}" || ! modal_is_positive_integer "${height}"; then
    return 1
  fi

  if ((width > screen_width)); then
    width="${screen_width}"
  fi
  if ((height > screen_height)); then
    height="${screen_height}"
  fi

  x=$(((screen_width - width) / 2))
  y=$(((screen_height - height) / 2))

  printf '%s|%s|%s|%s\n' "${x}" "${y}" "${width}" "${height}"
}

modal_render_text_content() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local message="$6"
  local line=""

  if ((width <= 0 || height <= 0)); then
    return 0
  fi

  line="${message:0:width}"
  cell_buffer_write_text "${buffer_name}" "${x}" "${y}" "${line}" 7 0 0
}

modal_render_confirm_content() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local message="$6"
  local confirm_label="$7"
  local cancel_label="$8"
  local focus_button="$9"
  local line=""
  local confirm_token=""
  local cancel_token=""
  local buttons_line=""
  local buttons_y=0

  if ((width <= 0 || height <= 0)); then
    return 0
  fi

  line="${message:0:width}"
  cell_buffer_write_text "${buffer_name}" "${x}" "${y}" "${line}" 7 0 0

  if [[ "${focus_button}" == "confirm" ]]; then
    confirm_token="[>${confirm_label}<]"
    cancel_token="[ ${cancel_label} ]"
  else
    confirm_token="[ ${confirm_label} ]"
    cancel_token="[>${cancel_label}<]"
  fi

  buttons_line="${confirm_token} ${cancel_token}"
  buttons_line="${buttons_line:0:width}"
  buttons_y=$((y + height - 1))
  cell_buffer_write_text "${buffer_name}" "${x}" "${buttons_y}" "${buttons_line}" 7 0 1
}

modal_render_text() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local width="$4"
  local height="$5"
  local title="$6"
  local message="$7"
  local rect=""
  local x=0
  local y=0

  if ! declare -F panel_render_with_content >/dev/null; then
    return 1
  fi

  rect="$(modal_center_rect "${screen_width}" "${screen_height}" "${width}" "${height}")" || return 1
  IFS='|' read -r x y width height <<< "${rect}"

  panel_render_with_content \
    "${buffer_name}" \
    "${x}" \
    "${y}" \
    "${width}" \
    "${height}" \
    " " \
    7 \
    0 \
    0 \
    single \
    "${title}" \
    1 \
    1 \
    1 \
    "." \
    0 \
    8 \
    0 \
    1 \
    1 \
    1 \
    1 \
    modal_render_text_content \
    "${message}"
}

modal_render_confirm() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local width="$4"
  local height="$5"
  local title="$6"
  local message="$7"
  local confirm_label="$8"
  local cancel_label="$9"
  local focus_button="${10:-confirm}"
  local rect=""
  local x=0
  local y=0

  if ! declare -F panel_render_with_content >/dev/null; then
    return 1
  fi

  if [[ "${focus_button}" != "confirm" && "${focus_button}" != "cancel" ]]; then
    return 1
  fi

  rect="$(modal_center_rect "${screen_width}" "${screen_height}" "${width}" "${height}")" || return 1
  IFS='|' read -r x y width height <<< "${rect}"

  panel_render_with_content \
    "${buffer_name}" \
    "${x}" \
    "${y}" \
    "${width}" \
    "${height}" \
    " " \
    7 \
    0 \
    0 \
    single \
    "${title}" \
    1 \
    1 \
    1 \
    "." \
    0 \
    8 \
    0 \
    1 \
    1 \
    1 \
    1 \
    modal_render_confirm_content \
    "${message}" \
    "${confirm_label}" \
    "${cancel_label}" \
    "${focus_button}"
}

modal_render_from_state() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local width="$4"
  local height="$5"
  local is_active="$6"
  local modal_type="$7"
  local title="$8"
  local message="$9"
  local confirm_label="${10:-Confirm}"
  local cancel_label="${11:-Cancel}"
  local focus_button="${12:-confirm}"
  local rect=""
  local x=0
  local y=0
  local target_width=0
  local target_height=0

  if [[ "${is_active}" != "1" ]]; then
    modal_clear_cached_rect "${buffer_name}" || return 1
    modal_reset_render_cache
    return 0
  fi

  rect="$(modal_center_rect "${screen_width}" "${screen_height}" "${width}" "${height}")" || return 1
  IFS='|' read -r x y target_width target_height <<< "${rect}"

  if ((modal_render_cache_visible == 1)); then
    if ((modal_render_cache_x != x || modal_render_cache_y != y || modal_render_cache_width != target_width || modal_render_cache_height != target_height)); then
      modal_clear_cached_rect "${buffer_name}" || return 1
    fi
  fi

  modal_track_dirty_region "${x}" "${y}" "${target_width}" "${target_height}" || return 1

  case "${modal_type}" in
    text)
      modal_render_text "${buffer_name}" "${screen_width}" "${screen_height}" "${width}" "${height}" "${title}" "${message}" || return 1
      ;;
    confirm)
      modal_render_confirm \
        "${buffer_name}" \
        "${screen_width}" \
        "${screen_height}" \
        "${width}" \
        "${height}" \
        "${title}" \
        "${message}" \
        "${confirm_label}" \
        "${cancel_label}" \
        "${focus_button}" || return 1
      ;;
    *)
      return 1
      ;;
  esac

  modal_render_cache_visible=1
  modal_render_cache_x="${x}"
  modal_render_cache_y="${y}"
  modal_render_cache_width="${target_width}"
  modal_render_cache_height="${target_height}"
}

modal_should_block_background_input() {
  local is_active="$1"

  if [[ "${is_active}" == "1" ]]; then
    printf '1\n'
    return 0
  fi

  printf '0\n'
}

modal_map_input_key() {
  local key="$1"

  case "${key}" in
    $'\033[D'|h|H)
      printf 'left\n'
      ;;
    $'\033[C'|l|L|$'\t')
      printf 'right\n'
      ;;
    ""|$'\n'|$'\r')
      printf 'enter\n'
      ;;
    $'\033')
      printf 'back\n'
      ;;
    q|Q)
      printf 'quit\n'
      ;;
    *)
      printf 'noop\n'
      ;;
  esac
}

modal_map_action_by_context() {
  local modal_type="$1"
  local key="$2"
  local input_action=""

  input_action="$(modal_map_input_key "${key}")"

  case "${modal_type}" in
    text)
      case "${input_action}" in
        enter|back|quit)
          printf 'close\n'
          ;;
        *)
          printf 'noop\n'
          ;;
      esac
      ;;
    confirm)
      case "${input_action}" in
        left)
          printf 'focus_left\n'
          ;;
        right)
          printf 'focus_right\n'
          ;;
        enter)
          printf 'submit\n'
          ;;
        back|quit)
          printf 'cancel\n'
          ;;
        *)
          printf 'noop\n'
          ;;
      esac
      ;;
    *)
      printf 'noop\n'
      ;;
  esac
}

modal_should_consume_input() {
  local is_active="$1"

  if [[ "${is_active}" == "1" ]]; then
    printf '1\n'
    return 0
  fi

  printf '0\n'
}
