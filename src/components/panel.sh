#!/usr/bin/env bash

panel_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

panel_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

panel_border_style_is_valid() {
  case "$1" in
    none|single|double)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

panel_content_rect() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local border_style="${5:-none}"
  local padding_top="${6:-0}"
  local padding_right="${7:-0}"
  local padding_bottom="${8:-0}"
  local padding_left="${9:-0}"
  local content_x=0
  local content_y=0
  local content_width=0
  local content_height=0

  if ! panel_is_integer "${x}" || ! panel_is_integer "${y}"; then
    return 1
  fi

  if ! panel_is_non_negative_integer "${width}" || ! panel_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ! panel_border_style_is_valid "${border_style}"; then
    return 1
  fi

  if ! panel_is_non_negative_integer "${padding_top}" || ! panel_is_non_negative_integer "${padding_right}" || ! panel_is_non_negative_integer "${padding_bottom}" || ! panel_is_non_negative_integer "${padding_left}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    printf '0|0|0|0\n'
    return 0
  fi

  content_x="${x}"
  content_y="${y}"
  content_width="${width}"
  content_height="${height}"

  if [[ "${border_style}" != "none" ]]; then
    content_x=$((content_x + 1))
    content_y=$((content_y + 1))
    content_width=$((content_width - 2))
    content_height=$((content_height - 2))
  fi

  if ((content_width <= 0 || content_height <= 0)); then
    printf '%s|%s|0|0\n' "${content_x}" "${content_y}"
    return 0
  fi

  content_x=$((content_x + padding_left))
  content_y=$((content_y + padding_top))
  content_width=$((content_width - padding_left - padding_right))
  content_height=$((content_height - padding_top - padding_bottom))

  if ((content_width <= 0 || content_height <= 0)); then
    printf '%s|%s|0|0\n' "${content_x}" "${content_y}"
    return 0
  fi

  printf '%s|%s|%s|%s\n' "${content_x}" "${content_y}" "${content_width}" "${content_height}"
}

panel_render() {
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
  local shadow_enabled="${12:-0}"
  local shadow_dx="${13:-1}"
  local shadow_dy="${14:-1}"
  local shadow_char="${15:-.}"
  local shadow_fg="${16:-0}"
  local shadow_bg="${17:-8}"
  local shadow_bold="${18:-0}"
  local padding_top="${19:-0}"
  local padding_right="${20:-0}"
  local padding_bottom="${21:-0}"
  local padding_left="${22:-0}"

  if ! declare -F rectangle_render >/dev/null; then
    return 1
  fi

  if ! declare -F shadow_render >/dev/null; then
    return 1
  fi

  if ! panel_content_rect "${x}" "${y}" "${width}" "${height}" "${border_style}" "${padding_top}" "${padding_right}" "${padding_bottom}" "${padding_left}" >/dev/null; then
    return 1
  fi

  if ! shadow_render "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${shadow_dx}" "${shadow_dy}" "${shadow_char}" "${shadow_fg}" "${shadow_bg}" "${shadow_bold}" "${shadow_enabled}"; then
    return 1
  fi

  rectangle_render "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${fill_char}" "${fg}" "${bg}" "${bold}" "${border_style}" "${title}"
}

panel_render_with_content() {
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
  local shadow_enabled="${12:-0}"
  local shadow_dx="${13:-1}"
  local shadow_dy="${14:-1}"
  local shadow_char="${15:-.}"
  local shadow_fg="${16:-0}"
  local shadow_bg="${17:-8}"
  local shadow_bold="${18:-0}"
  local padding_top="${19:-0}"
  local padding_right="${20:-0}"
  local padding_bottom="${21:-0}"
  local padding_left="${22:-0}"
  local content_renderer="${23:-}"
  local content_rect=""
  local content_x=0
  local content_y=0
  local content_width=0
  local content_height=0
  local -a content_args=()

  if (($# > 23)); then
    content_args=("${@:24}")
  fi

  if ! panel_render "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${fill_char}" "${fg}" "${bg}" "${bold}" "${border_style}" "${title}" "${shadow_enabled}" "${shadow_dx}" "${shadow_dy}" "${shadow_char}" "${shadow_fg}" "${shadow_bg}" "${shadow_bold}" "${padding_top}" "${padding_right}" "${padding_bottom}" "${padding_left}"; then
    return 1
  fi

  if [[ -z "${content_renderer}" ]]; then
    return 0
  fi

  if ! declare -F "${content_renderer}" >/dev/null; then
    return 1
  fi

  content_rect="$(panel_content_rect "${x}" "${y}" "${width}" "${height}" "${border_style}" "${padding_top}" "${padding_right}" "${padding_bottom}" "${padding_left}")" || return 1
  IFS='|' read -r content_x content_y content_width content_height <<< "${content_rect}"

  if ((content_width == 0 || content_height == 0)); then
    return 0
  fi

  "${content_renderer}" "${buffer_name}" "${content_x}" "${content_y}" "${content_width}" "${content_height}" "${content_args[@]}"
}
