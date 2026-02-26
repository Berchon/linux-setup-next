#!/usr/bin/env bash

dirty_regions_screen_width=0
dirty_regions_screen_height=0

declare -ag dirty_regions_xs=()
declare -ag dirty_regions_ys=()
declare -ag dirty_regions_widths=()
declare -ag dirty_regions_heights=()

dirty_regions_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

dirty_regions_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

dirty_regions_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

dirty_regions_reset() {
  dirty_regions_xs=()
  dirty_regions_ys=()
  dirty_regions_widths=()
  dirty_regions_heights=()
}

dirty_regions_init() {
  local screen_width="$1"
  local screen_height="$2"

  if ! dirty_regions_is_positive_integer "${screen_width}" || ! dirty_regions_is_positive_integer "${screen_height}"; then
    printf "dirty_regions: invalid viewport '%s'x'%s'\n" "${screen_width}" "${screen_height}" >&2
    return 1
  fi

  dirty_regions_screen_width="${screen_width}"
  dirty_regions_screen_height="${screen_height}"
  dirty_regions_reset
}

dirty_regions_count() {
  printf '%s\n' "${#dirty_regions_xs[@]}"
}

dirty_regions_get() {
  local index="$1"

  if ! dirty_regions_is_non_negative_integer "${index}"; then
    return 1
  fi

  if ((index >= ${#dirty_regions_xs[@]})); then
    return 1
  fi

  printf '%s|%s|%s|%s\n' \
    "${dirty_regions_xs[index]}" \
    "${dirty_regions_ys[index]}" \
    "${dirty_regions_widths[index]}" \
    "${dirty_regions_heights[index]}"
}

dirty_regions_remove_at() {
  local index="$1"

  if ! dirty_regions_is_non_negative_integer "${index}"; then
    return 1
  fi

  if ((index >= ${#dirty_regions_xs[@]})); then
    return 1
  fi

  unset 'dirty_regions_xs[index]'
  unset 'dirty_regions_ys[index]'
  unset 'dirty_regions_widths[index]'
  unset 'dirty_regions_heights[index]'

  dirty_regions_xs=("${dirty_regions_xs[@]}")
  dirty_regions_ys=("${dirty_regions_ys[@]}")
  dirty_regions_widths=("${dirty_regions_widths[@]}")
  dirty_regions_heights=("${dirty_regions_heights[@]}")
}

dirty_regions_rects_overlap() {
  local ax="$1"
  local ay="$2"
  local aw="$3"
  local ah="$4"
  local bx="$5"
  local by="$6"
  local bw="$7"
  local bh="$8"
  local a_right=0
  local a_bottom=0
  local b_right=0
  local b_bottom=0

  a_right=$((ax + aw))
  a_bottom=$((ay + ah))
  b_right=$((bx + bw))
  b_bottom=$((by + bh))

  if ((ax < b_right && bx < a_right && ay < b_bottom && by < a_bottom)); then
    return 0
  fi

  return 1
}

dirty_regions_rect_union() {
  local ax="$1"
  local ay="$2"
  local aw="$3"
  local ah="$4"
  local bx="$5"
  local by="$6"
  local bw="$7"
  local bh="$8"
  local left="${ax}"
  local top="${ay}"
  local right=0
  local bottom=0

  if ((bx < left)); then
    left="${bx}"
  fi

  if ((by < top)); then
    top="${by}"
  fi

  right=$((ax + aw))
  if ((bx + bw > right)); then
    right=$((bx + bw))
  fi

  bottom=$((ay + ah))
  if ((by + bh > bottom)); then
    bottom=$((by + bh))
  fi

  printf '%s|%s|%s|%s\n' "${left}" "${top}" "$((right - left))" "$((bottom - top))"
}

dirty_regions_clip_rect() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local start_x="${x}"
  local start_y="${y}"
  local end_x=0
  local end_y=0

  if ((dirty_regions_screen_width <= 0 || dirty_regions_screen_height <= 0)); then
    return 1
  fi

  end_x=$((x + width))
  end_y=$((y + height))

  if ((start_x < 0)); then
    start_x=0
  fi

  if ((start_y < 0)); then
    start_y=0
  fi

  if ((end_x > dirty_regions_screen_width)); then
    end_x="${dirty_regions_screen_width}"
  fi

  if ((end_y > dirty_regions_screen_height)); then
    end_y="${dirty_regions_screen_height}"
  fi

  if ((start_x >= end_x || start_y >= end_y)); then
    return 1
  fi

  printf '%s|%s|%s|%s\n' "${start_x}" "${start_y}" "$((end_x - start_x))" "$((end_y - start_y))"
}

dirty_regions_add() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local region_x="${x}"
  local region_y="${y}"
  local region_width="${width}"
  local region_height="${height}"
  local clipped_rect=""
  local scan_idx=0
  local index=0

  if ! dirty_regions_is_integer "${x}" || ! dirty_regions_is_integer "${y}"; then
    return 1
  fi

  if ! dirty_regions_is_non_negative_integer "${width}" || ! dirty_regions_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  if ! clipped_rect="$(dirty_regions_clip_rect "${region_x}" "${region_y}" "${region_width}" "${region_height}")"; then
    return 0
  fi
  IFS='|' read -r region_x region_y region_width region_height <<< "${clipped_rect}"

  while ((scan_idx < ${#dirty_regions_xs[@]})); do
    if dirty_regions_rects_overlap \
      "${region_x}" \
      "${region_y}" \
      "${region_width}" \
      "${region_height}" \
      "${dirty_regions_xs[scan_idx]}" \
      "${dirty_regions_ys[scan_idx]}" \
      "${dirty_regions_widths[scan_idx]}" \
      "${dirty_regions_heights[scan_idx]}"; then
      IFS='|' read -r region_x region_y region_width region_height <<< "$(dirty_regions_rect_union \
        "${region_x}" \
        "${region_y}" \
        "${region_width}" \
        "${region_height}" \
        "${dirty_regions_xs[scan_idx]}" \
        "${dirty_regions_ys[scan_idx]}" \
        "${dirty_regions_widths[scan_idx]}" \
        "${dirty_regions_heights[scan_idx]}")"
      dirty_regions_remove_at "${scan_idx}"
      scan_idx=0
      continue
    fi

    scan_idx=$((scan_idx + 1))
  done

  index="${#dirty_regions_xs[@]}"
  dirty_regions_xs[index]="${region_x}"
  dirty_regions_ys[index]="${region_y}"
  dirty_regions_widths[index]="${region_width}"
  dirty_regions_heights[index]="${region_height}"
}
