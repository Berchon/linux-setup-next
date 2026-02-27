#!/usr/bin/env bash

shadow_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

shadow_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

shadow_clip_rect() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local start_x=0
  local start_y=0
  local end_x=0
  local end_y=0

  if ! shadow_is_integer "${x}" || ! shadow_is_integer "${y}"; then
    return 1
  fi

  if ! shadow_is_non_negative_integer "${width}" || ! shadow_is_non_negative_integer "${height}"; then
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

shadow_cell_is_occupied() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local idx=0
  local default_char=' '
  local default_fg=7
  local default_bg=0
  local default_bold=0
  local char=""
  local fg=0
  local bg=0
  local bold=0

  if ! idx="$(cell_buffer_index "${x}" "${y}")"; then
    return 1
  fi

  if [[ -n "${cell_buffer_default_char:-}" ]]; then
    default_char="${cell_buffer_default_char}"
  fi
  if [[ -n "${cell_buffer_default_fg:-}" ]]; then
    default_fg="${cell_buffer_default_fg}"
  fi
  if [[ -n "${cell_buffer_default_bg:-}" ]]; then
    default_bg="${cell_buffer_default_bg}"
  fi
  if [[ -n "${cell_buffer_default_bold:-}" ]]; then
    default_bold="${cell_buffer_default_bold}"
  fi

  case "${buffer_name}" in
    front)
      char="${cell_front_chars[idx]}"
      fg="${cell_front_fgs[idx]}"
      bg="${cell_front_bgs[idx]}"
      bold="${cell_front_bolds[idx]}"
      ;;
    back)
      char="${cell_back_chars[idx]}"
      fg="${cell_back_fgs[idx]}"
      bg="${cell_back_bgs[idx]}"
      bold="${cell_back_bolds[idx]}"
      ;;
    *)
      return 1
      ;;
  esac

  if [[ "${char}" != "${default_char}" ]]; then
    return 0
  fi

  if [[ "${fg}" != "${default_fg}" || "${bg}" != "${default_bg}" || "${bold}" != "${default_bold}" ]]; then
    return 0
  fi

  return 1
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
  local clipped=""
  local start_x=0
  local start_y=0
  local clipped_width=0
  local clipped_height=0
  local current_x=0
  local current_y=0

  if ! declare -F cell_buffer_write_cell >/dev/null || ! declare -F cell_buffer_index >/dev/null; then
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

  clipped="$(shadow_clip_rect "$((x + dx))" "$((y + dy))" "${width}" "${height}")" || return 1
  IFS='|' read -r start_x start_y clipped_width clipped_height <<< "${clipped}"

  if ((clipped_width == 0 || clipped_height == 0)); then
    return 0
  fi

  for ((current_y = start_y; current_y < start_y + clipped_height; current_y++)); do
    for ((current_x = start_x; current_x < start_x + clipped_width; current_x++)); do
      if shadow_cell_is_occupied "${buffer_name}" "${current_x}" "${current_y}"; then
        continue
      fi

      cell_buffer_write_cell "${buffer_name}" "${current_x}" "${current_y}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
    done
  done
}
