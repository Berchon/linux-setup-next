#!/usr/bin/env bash

shadow_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

shadow_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

shadow_color_capacity() {
  if [[ -n "${runtime_color_capacity:-}" ]] && shadow_is_non_negative_integer "${runtime_color_capacity}"; then
    printf '%s\n' "${runtime_color_capacity}"
    return 0
  fi

  printf '16\n'
}

shadow_darken_color_16() {
  local color="$1"

  if ! [[ "${color}" =~ ^-?[0-9]+$ ]]; then
    printf '0\n'
    return 0
  fi

  if ((color < 0)); then
    color=0
  fi

  color=$((color % 16))

  if ((color >= 8)); then
    printf '%s\n' "$((color - 8))"
    return 0
  fi

  if ((color == 0)); then
    printf '0\n'
    return 0
  fi

  printf '8\n'
}

shadow_darken_color_256() {
  local color="$1"
  local cube=0
  local r=0
  local g=0
  local b=0

  if ! [[ "${color}" =~ ^-?[0-9]+$ ]]; then
    printf '0\n'
    return 0
  fi

  if ((color < 0)); then
    color=0
  fi
  if ((color > 255)); then
    color=255
  fi

  if ((color < 16)); then
    shadow_darken_color_16 "${color}"
    return 0
  fi

  if ((color >= 232)); then
    if ((color <= 232)); then
      printf '16\n'
    else
      printf '%s\n' "$((color - 1))"
    fi
    return 0
  fi

  cube=$((color - 16))
  r=$((cube / 36))
  g=$(((cube / 6) % 6))
  b=$((cube % 6))

  if ((r > 0)); then
    r=$((r - 1))
  fi
  if ((g > 0)); then
    g=$((g - 1))
  fi
  if ((b > 0)); then
    b=$((b - 1))
  fi

  printf '%s\n' "$((16 + r * 36 + g * 6 + b))"
}

shadow_darken_color() {
  local color="$1"
  local capacity="${2:-$(shadow_color_capacity)}"

  if [[ ! "${capacity}" =~ ^[0-9]+$ ]]; then
    capacity=16
  fi

  if ((capacity >= 256)); then
    shadow_darken_color_256 "${color}"
    return 0
  fi

  shadow_darken_color_16 "${color}"
}

shadow_resolve_enabled() {
  local value="${1:-1}"

  value="${value,,}"
  case "${value}" in
    1|true|yes|on)
      printf '1\n'
      return 0
      ;;
    0|false|no|off)
      printf '0\n'
      return 0
      ;;
    *)
      return 1
      ;;
  esac
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

shadow_draw_clipped_rect() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local shadow_char="$6"
  local fg="$7"
  local bg="$8"
  local bold="$9"
  local clipped=""
  local start_x=0
  local start_y=0
  local clipped_width=0
  local clipped_height=0
  local current_x=0
  local current_y=0

  if ! shadow_is_integer "${x}" || ! shadow_is_integer "${y}"; then
    return 1
  fi

  if ! shadow_is_non_negative_integer "${width}" || ! shadow_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  clipped="$(shadow_clip_rect "${x}" "${y}" "${width}" "${height}")" || return 1
  IFS='|' read -r start_x start_y clipped_width clipped_height <<< "${clipped}"

  if ((clipped_width == 0 || clipped_height == 0)); then
    return 0
  fi

  for ((current_y = start_y; current_y < start_y + clipped_height; current_y++)); do
    for ((current_x = start_x; current_x < start_x + clipped_width; current_x++)); do
      cell_buffer_write_cell "${buffer_name}" "${current_x}" "${current_y}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
    done
  done
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
  local enabled_raw="${12:-1}"
  local enabled=1
  local shadow_x=0
  local shadow_y=0
  local base_end_x=0
  local base_end_y=0
  local shadow_end_x=0
  local shadow_end_y=0
  local overlap_start_x=0
  local overlap_start_y=0
  local overlap_end_x=0
  local overlap_end_y=0
  local middle_height=0
  local top_height=0
  local bottom_height=0
  local left_width=0
  local right_width=0

  if ! declare -F cell_buffer_write_cell >/dev/null; then
    return 1
  fi

  enabled="$(shadow_resolve_enabled "${enabled_raw}")" || return 1
  if ((enabled == 0)); then
    return 0
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

  shadow_x=$((x + dx))
  shadow_y=$((y + dy))
  base_end_x=$((x + width))
  base_end_y=$((y + height))
  shadow_end_x=$((shadow_x + width))
  shadow_end_y=$((shadow_y + height))

  overlap_start_x="${shadow_x}"
  if ((x > overlap_start_x)); then
    overlap_start_x="${x}"
  fi

  overlap_start_y="${shadow_y}"
  if ((y > overlap_start_y)); then
    overlap_start_y="${y}"
  fi

  overlap_end_x="${shadow_end_x}"
  if ((base_end_x < overlap_end_x)); then
    overlap_end_x="${base_end_x}"
  fi

  overlap_end_y="${shadow_end_y}"
  if ((base_end_y < overlap_end_y)); then
    overlap_end_y="${base_end_y}"
  fi

  if ((overlap_start_x >= overlap_end_x || overlap_start_y >= overlap_end_y)); then
    shadow_draw_clipped_rect "${buffer_name}" "${shadow_x}" "${shadow_y}" "${width}" "${height}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
    return 0
  fi

  top_height=$((overlap_start_y - shadow_y))
  bottom_height=$((shadow_end_y - overlap_end_y))
  middle_height=$((overlap_end_y - overlap_start_y))
  left_width=$((overlap_start_x - shadow_x))
  right_width=$((shadow_end_x - overlap_end_x))

  shadow_draw_clipped_rect "${buffer_name}" "${shadow_x}" "${shadow_y}" "${width}" "${top_height}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
  shadow_draw_clipped_rect "${buffer_name}" "${shadow_x}" "${overlap_end_y}" "${width}" "${bottom_height}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
  shadow_draw_clipped_rect "${buffer_name}" "${shadow_x}" "${overlap_start_y}" "${left_width}" "${middle_height}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
  shadow_draw_clipped_rect "${buffer_name}" "${overlap_end_x}" "${overlap_start_y}" "${right_width}" "${middle_height}" "${shadow_char}" "${fg}" "${bg}" "${bold}"
}
