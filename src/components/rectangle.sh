#!/usr/bin/env bash

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
