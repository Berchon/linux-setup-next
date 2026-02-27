#!/usr/bin/env bash

rectangle_border_charset='auto'

rectangle_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

rectangle_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

rectangle_clip_rect() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local start_x=0
  local start_y=0
  local end_x=0
  local end_y=0

  if ! rectangle_is_integer "${x}" || ! rectangle_is_integer "${y}"; then
    return 1
  fi

  if ! rectangle_is_non_negative_integer "${width}" || ! rectangle_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    printf '0|0|0|0\n'
    return 0
  fi

  start_x="${x}"
  start_y="${y}"
  end_x=$((x + width))
  end_y=$((y + height))

  if ((start_x < 0)); then
    start_x=0
  fi
  if ((start_y < 0)); then
    start_y=0
  fi
  if ((end_x > cell_buffer_width)); then
    end_x="${cell_buffer_width}"
  fi
  if ((end_y > cell_buffer_height)); then
    end_y="${cell_buffer_height}"
  fi

  if ((start_x >= end_x || start_y >= end_y)); then
    printf '0|0|0|0\n'
    return 0
  fi

  printf '%s|%s|%s|%s\n' "${start_x}" "${start_y}" "$((end_x - start_x))" "$((end_y - start_y))"
}

rectangle_render_fill() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local fill_char="$6"
  local fg="$7"
  local bg="$8"
  local bold="$9"
  local clipped=""
  local start_x=0
  local start_y=0
  local clipped_width=0
  local clipped_height=0
  local end_x=0
  local end_y=0
  local current_x=0
  local current_y=0

  if ! declare -F cell_buffer_write_cell >/dev/null; then
    return 1
  fi

  clipped="$(rectangle_clip_rect "${x}" "${y}" "${width}" "${height}")" || return 1
  IFS='|' read -r start_x start_y clipped_width clipped_height <<< "${clipped}"

  if ((clipped_width == 0 || clipped_height == 0)); then
    return 0
  fi

  if [[ -z "${fill_char}" ]]; then
    fill_char=' '
  fi
  fill_char="${fill_char:0:1}"

  end_x=$((start_x + clipped_width))
  end_y=$((start_y + clipped_height))

  for ((current_y = start_y; current_y < end_y; current_y++)); do
    for ((current_x = start_x; current_x < end_x; current_x++)); do
      cell_buffer_write_cell "${buffer_name}" "${current_x}" "${current_y}" "${fill_char}" "${fg}" "${bg}" "${bold}"
    done
  done
}

rectangle_border_style_is_valid() {
  case "$1" in
    none|single|double)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

rectangle_border_chars() {
  local border_style="$1"

  if [[ "${rectangle_border_charset}" != 'auto' && "${rectangle_border_charset}" != 'ascii' ]]; then
    return 1
  fi

  case "${border_style}" in
    single)
      rectangle_border_tl='+'
      rectangle_border_tr='+'
      rectangle_border_bl='+'
      rectangle_border_br='+'
      rectangle_border_h='-'
      rectangle_border_v='|'
      return 0
      ;;
    double)
      rectangle_border_tl='+'
      rectangle_border_tr='+'
      rectangle_border_bl='+'
      rectangle_border_br='+'
      rectangle_border_h='='
      rectangle_border_v='|'
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

rectangle_set_border_charset() {
  local charset="$1"

  case "${charset}" in
    auto|ascii)
      rectangle_border_charset="${charset}"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

rectangle_write_visible_cell() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local cell_char="$4"
  local fg="$5"
  local bg="$6"
  local bold="$7"

  if ((x < 0 || y < 0 || x >= cell_buffer_width || y >= cell_buffer_height)); then
    return 0
  fi

  cell_buffer_write_cell "${buffer_name}" "${x}" "${y}" "${cell_char}" "${fg}" "${bg}" "${bold}"
}

rectangle_render_border() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local border_style="$6"
  local fg="$7"
  local bg="$8"
  local bold="$9"
  local tl=""
  local tr=""
  local bl=""
  local br=""
  local h=""
  local v=""
  local right=0
  local bottom=0
  local current_x=0
  local current_y=0

  if ! rectangle_is_integer "${x}" || ! rectangle_is_integer "${y}"; then
    return 1
  fi

  if ! rectangle_is_non_negative_integer "${width}" || ! rectangle_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ! rectangle_border_style_is_valid "${border_style}"; then
    return 1
  fi

  if [[ "${border_style}" == "none" ]] || ((width == 0 || height == 0)); then
    return 0
  fi

  rectangle_border_chars "${border_style}" || return 1
  tl="${rectangle_border_tl}"
  tr="${rectangle_border_tr}"
  bl="${rectangle_border_bl}"
  br="${rectangle_border_br}"
  h="${rectangle_border_h}"
  v="${rectangle_border_v}"

  right=$((x + width - 1))
  bottom=$((y + height - 1))

  rectangle_write_visible_cell "${buffer_name}" "${x}" "${y}" "${tl}" "${fg}" "${bg}" "${bold}"
  if ((width > 1)); then
    rectangle_write_visible_cell "${buffer_name}" "${right}" "${y}" "${tr}" "${fg}" "${bg}" "${bold}"
  fi
  if ((height > 1)); then
    rectangle_write_visible_cell "${buffer_name}" "${x}" "${bottom}" "${bl}" "${fg}" "${bg}" "${bold}"
    if ((width > 1)); then
      rectangle_write_visible_cell "${buffer_name}" "${right}" "${bottom}" "${br}" "${fg}" "${bg}" "${bold}"
    fi
  fi

  for ((current_x = x + 1; current_x < right; current_x++)); do
    rectangle_write_visible_cell "${buffer_name}" "${current_x}" "${y}" "${h}" "${fg}" "${bg}" "${bold}"
    if ((height > 1)); then
      rectangle_write_visible_cell "${buffer_name}" "${current_x}" "${bottom}" "${h}" "${fg}" "${bg}" "${bold}"
    fi
  done

  for ((current_y = y + 1; current_y < bottom; current_y++)); do
    rectangle_write_visible_cell "${buffer_name}" "${x}" "${current_y}" "${v}" "${fg}" "${bg}" "${bold}"
    if ((width > 1)); then
      rectangle_write_visible_cell "${buffer_name}" "${right}" "${current_y}" "${v}" "${fg}" "${bg}" "${bold}"
    fi
  done
}

rectangle_render_title() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local border_style="$6"
  local title="$7"
  local fg="$8"
  local bg="$9"
  local bold="${10}"
  local title_x=0
  local title_y=0
  local max_length=0
  local clipped_title=""

  if [[ -z "${title}" ]]; then
    return 0
  fi

  if ! rectangle_is_integer "${x}" || ! rectangle_is_integer "${y}"; then
    return 1
  fi

  if ! rectangle_is_non_negative_integer "${width}" || ! rectangle_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ! rectangle_border_style_is_valid "${border_style}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  title_x="${x}"
  title_y="${y}"
  max_length="${width}"

  if [[ "${border_style}" != "none" ]]; then
    if ((width <= 2)); then
      return 0
    fi

    title_x=$((x + 1))
    max_length=$((width - 2))
  fi

  if ((max_length <= 0)); then
    return 0
  fi

  clipped_title="${title:0:max_length}"
  cell_buffer_write_text "${buffer_name}" "${title_x}" "${title_y}" "${clipped_title}" "${fg}" "${bg}" "${bold}"
}

rectangle_render() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local fill_char="$6"
  local fg="$7"
  local bg="$8"
  local bold="$9"
  local border_style="${10:-none}"
  local title="${11:-}"

  if ! rectangle_render_fill "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${fill_char}" "${fg}" "${bg}" "${bold}"; then
    return 1
  fi

  if ! rectangle_render_border "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${border_style}" "${fg}" "${bg}" "${bold}"; then
    return 1
  fi

  rectangle_render_title "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${border_style}" "${title}" "${fg}" "${bg}" "${bold}"
}
