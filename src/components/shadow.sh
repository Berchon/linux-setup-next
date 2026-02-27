#!/usr/bin/env bash

shadow_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

shadow_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

shadow_render() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local dx="$6"
  local dy="$7"
  local shadow_char="$8"
  local fg="$9"
  local bg="${10}"
  local bold="${11}"
  local start_x=0
  local start_y=0
  local end_x=0
  local end_y=0
  local current_x=0
  local current_y=0

  if ! declare -F cell_buffer_write_cell >/dev/null; then
    return 1
  fi

  if ! shadow_is_integer "${x}" || ! shadow_is_integer "${y}" || ! shadow_is_integer "${dx}" || ! shadow_is_integer "${dy}"; then
    return 1
  fi

  if ! shadow_is_non_negative_integer "${width}" || ! shadow_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  if [[ -z "${shadow_char}" ]]; then
    shadow_char='.'
  fi
  shadow_char="${shadow_char:0:1}"

  start_x=$((x + dx))
  start_y=$((y + dy))
  end_x=$((start_x + width))
  end_y=$((start_y + height))

  for ((current_y = start_y; current_y < end_y; current_y++)); do
    for ((current_x = start_x; current_x < end_x; current_x++)); do
      cell_buffer_write_cell "${buffer_name}" "${current_x}" "${current_y}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
    done
  done
}
