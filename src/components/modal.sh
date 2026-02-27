#!/usr/bin/env bash

modal_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

modal_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
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

modal_should_block_background_input() {
  local is_active="$1"

  if [[ "${is_active}" == "1" ]]; then
    printf '1\n'
    return 0
  fi

  printf '0\n'
}
