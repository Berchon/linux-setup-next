#!/usr/bin/env bash

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

  if ! declare -F rectangle_render >/dev/null; then
    return 1
  fi

  if ! declare -F shadow_render >/dev/null; then
    return 1
  fi

  if ! shadow_render "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${shadow_dx}" "${shadow_dy}" "${shadow_char}" "${shadow_fg}" "${shadow_bg}" "${shadow_bold}" "${shadow_enabled}"; then
    return 1
  fi

  rectangle_render "${buffer_name}" "${x}" "${y}" "${width}" "${height}" "${fill_char}" "${fg}" "${bg}" "${bold}" "${border_style}" "${title}"
}
