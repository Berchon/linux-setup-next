#!/usr/bin/env bash

declare -ag diff_renderer_changed_xs=()
declare -ag diff_renderer_changed_ys=()

diff_renderer_reset_changed_cells() {
  diff_renderer_changed_xs=()
  diff_renderer_changed_ys=()
}

diff_renderer_changed_count() {
  printf '%s\n' "${#diff_renderer_changed_xs[@]}"
}

diff_renderer_get_changed_cell() {
  local index="$1"

  if [[ ! "${index}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  if ((index >= ${#diff_renderer_changed_xs[@]})); then
    return 1
  fi

  printf '%s|%s\n' "${diff_renderer_changed_xs[index]}" "${diff_renderer_changed_ys[index]}"
}

diff_renderer_cell_differs_at_index() {
  local idx="$1"

  if [[ "${cell_front_chars[idx]}" != "${cell_back_chars[idx]}" ]]; then
    return 0
  fi

  if [[ "${cell_front_fgs[idx]}" != "${cell_back_fgs[idx]}" ]]; then
    return 0
  fi

  if [[ "${cell_front_bgs[idx]}" != "${cell_back_bgs[idx]}" ]]; then
    return 0
  fi

  if [[ "${cell_front_bolds[idx]}" != "${cell_back_bolds[idx]}" ]]; then
    return 0
  fi

  return 1
}

diff_renderer_collect_changed_cells() {
  local dirty_count=0
  local dirty_index=0
  local rect=""
  local rect_x=0
  local rect_y=0
  local rect_width=0
  local rect_height=0
  local y=0
  local x=0
  local idx=0
  local changed_index=0

  if ! declare -F dirty_regions_count >/dev/null || ! declare -F dirty_regions_get >/dev/null; then
    return 1
  fi

  diff_renderer_reset_changed_cells
  dirty_count="$(dirty_regions_count)"

  for ((dirty_index = 0; dirty_index < dirty_count; dirty_index++)); do
    rect="$(dirty_regions_get "${dirty_index}")"
    IFS='|' read -r rect_x rect_y rect_width rect_height <<< "${rect}"

    for ((y = rect_y; y < rect_y + rect_height; y++)); do
      for ((x = rect_x; x < rect_x + rect_width; x++)); do
        idx=$((y * cell_buffer_width + x))

        if ! diff_renderer_cell_differs_at_index "${idx}"; then
          continue
        fi

        changed_index="${#diff_renderer_changed_xs[@]}"
        diff_renderer_changed_xs[changed_index]="${x}"
        diff_renderer_changed_ys[changed_index]="${y}"
      done
    done
  done
}
