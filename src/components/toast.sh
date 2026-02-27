#!/usr/bin/env bash

if [[ -z "${toast_component_module_loaded:-}" ]]; then
  toast_component_module_loaded=1

  toast_render_cache_visible=0
  toast_render_cache_x=0
  toast_render_cache_y=0
  toast_render_cache_width=0
  toast_render_cache_height=0
fi

toast_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

toast_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

toast_reset_render_cache() {
  toast_render_cache_visible=0
  toast_render_cache_x=0
  toast_render_cache_y=0
  toast_render_cache_width=0
  toast_render_cache_height=0
}

toast_compute_rect() {
  local screen_width="$1"
  local screen_height="$2"
  local message="$3"
  local width=0
  local height=3
  local x=0
  local y=0
  local message_width=0

  if ! toast_is_positive_integer "${screen_width}" || ! toast_is_positive_integer "${screen_height}"; then
    return 1
  fi

  message_width="${#message}"
  width=$((message_width + 4))
  if ((width < 12)); then
    width=12
  fi
  if ((width > screen_width)); then
    width="${screen_width}"
  fi
  if ((height > screen_height)); then
    height="${screen_height}"
  fi

  x=$(((screen_width - width) / 2))
  y=$((screen_height - height - 1))
  if ((y < 0)); then
    y=0
  fi

  printf '%s|%s|%s|%s\n' "${x}" "${y}" "${width}" "${height}"
}

toast_resolve_style() {
  local severity="$1"
  local fg=7
  local bg=0
  local bold=0

  case "${severity}" in
    success)
      fg=2
      bg=0
      bold=1
      ;;
    warn|warning)
      fg=3
      bg=0
      bold=1
      ;;
    error)
      fg=1
      bg=0
      bold=1
      ;;
  esac

  printf '%s|%s|%s\n' "${fg}" "${bg}" "${bold}"
}

toast_render_content() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local _height="$5"
  local message="$6"
  local fg="$7"
  local bg="$8"
  local bold="$9"
  local line=""

  if ((width == 0)); then
    return 0
  fi

  line="${message:0:width}"
  cell_buffer_write_text "${buffer_name}" "${x}" "${y}" "${line}" "${fg}" "${bg}" "${bold}"
}

toast_track_dirty_region() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"

  if ! toast_is_non_negative_integer "${width}" || ! toast_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  if declare -F dirty_regions_add >/dev/null; then
    dirty_regions_add "${x}" "${y}" "${width}" "${height}"
  fi
}

toast_render_frame() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local is_active="$4"
  local message="$5"
  local severity="${6:-info}"
  local rect=""
  local x=0
  local y=0
  local width=0
  local height=0
  local style=""
  local fg=7
  local bg=0
  local bold=0

  if ! declare -F panel_render_with_content >/dev/null; then
    return 1
  fi
  if ! declare -F cell_buffer_clear_rect >/dev/null; then
    return 1
  fi

  if [[ "${is_active}" == "1" ]]; then
    rect="$(toast_compute_rect "${screen_width}" "${screen_height}" "${message}")" || return 1
    IFS='|' read -r x y width height <<< "${rect}"

    if ((toast_render_cache_visible == 1)); then
      toast_track_dirty_region "${toast_render_cache_x}" "${toast_render_cache_y}" "${toast_render_cache_width}" "${toast_render_cache_height}"
    fi
    toast_track_dirty_region "${x}" "${y}" "${width}" "${height}"

    style="$(toast_resolve_style "${severity}")"
    IFS='|' read -r fg bg bold <<< "${style}"

    panel_render_with_content \
      "${buffer_name}" \
      "${x}" \
      "${y}" \
      "${width}" \
      "${height}" \
      " " \
      "${fg}" \
      "${bg}" \
      0 \
      single \
      "" \
      1 \
      1 \
      1 \
      "." \
      0 \
      8 \
      0 \
      0 \
      1 \
      0 \
      1 \
      toast_render_content \
      "${message}" \
      "${fg}" \
      "${bg}" \
      "${bold}"

    toast_render_cache_visible=1
    toast_render_cache_x="${x}"
    toast_render_cache_y="${y}"
    toast_render_cache_width="${width}"
    toast_render_cache_height="${height}"
    return 0
  fi

  if ((toast_render_cache_visible == 1)); then
    toast_track_dirty_region "${toast_render_cache_x}" "${toast_render_cache_y}" "${toast_render_cache_width}" "${toast_render_cache_height}"
    cell_buffer_clear_rect \
      "${buffer_name}" \
      "${toast_render_cache_x}" \
      "${toast_render_cache_y}" \
      "${toast_render_cache_width}" \
      "${toast_render_cache_height}"
  fi

  toast_reset_render_cache
}
