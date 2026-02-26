#!/usr/bin/env bash

declare -ag diff_renderer_changed_xs=()
declare -ag diff_renderer_changed_ys=()
declare -ag diff_renderer_run_xs=()
declare -ag diff_renderer_run_ys=()
declare -ag diff_renderer_run_texts=()
declare -ag diff_renderer_run_fgs=()
declare -ag diff_renderer_run_bgs=()
declare -ag diff_renderer_run_bolds=()

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

diff_renderer_reset_runs() {
  diff_renderer_run_xs=()
  diff_renderer_run_ys=()
  diff_renderer_run_texts=()
  diff_renderer_run_fgs=()
  diff_renderer_run_bgs=()
  diff_renderer_run_bolds=()
}

diff_renderer_run_count() {
  printf '%s\n' "${#diff_renderer_run_xs[@]}"
}

diff_renderer_get_run() {
  local index="$1"

  if [[ ! "${index}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  if ((index >= ${#diff_renderer_run_xs[@]})); then
    return 1
  fi

  printf '%s|%s|%s|%s|%s|%s\n' \
    "${diff_renderer_run_xs[index]}" \
    "${diff_renderer_run_ys[index]}" \
    "${diff_renderer_run_texts[index]}" \
    "${diff_renderer_run_fgs[index]}" \
    "${diff_renderer_run_bgs[index]}" \
    "${diff_renderer_run_bolds[index]}"
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

diff_renderer_append_run() {
  local x="$1"
  local y="$2"
  local text="$3"
  local fg="$4"
  local bg="$5"
  local bold="$6"
  local run_index=0

  run_index="${#diff_renderer_run_xs[@]}"
  diff_renderer_run_xs[run_index]="${x}"
  diff_renderer_run_ys[run_index]="${y}"
  diff_renderer_run_texts[run_index]="${text}"
  diff_renderer_run_fgs[run_index]="${fg}"
  diff_renderer_run_bgs[run_index]="${bg}"
  diff_renderer_run_bolds[run_index]="${bold}"
}

diff_renderer_collect_runs() {
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
  local run_active=0
  local run_x=0
  local run_y=0
  local run_fg=0
  local run_bg=0
  local run_bold=0
  local run_text=""
  local cell_char=""
  local cell_fg=0
  local cell_bg=0
  local cell_bold=0

  if ! declare -F dirty_regions_count >/dev/null || ! declare -F dirty_regions_get >/dev/null; then
    return 1
  fi

  diff_renderer_reset_runs
  dirty_count="$(dirty_regions_count)"

  for ((dirty_index = 0; dirty_index < dirty_count; dirty_index++)); do
    rect="$(dirty_regions_get "${dirty_index}")"
    IFS='|' read -r rect_x rect_y rect_width rect_height <<< "${rect}"

    for ((y = rect_y; y < rect_y + rect_height; y++)); do
      run_active=0
      run_text=""

      for ((x = rect_x; x < rect_x + rect_width; x++)); do
        idx=$((y * cell_buffer_width + x))

        if ! diff_renderer_cell_differs_at_index "${idx}"; then
          if ((run_active == 1)); then
            diff_renderer_append_run "${run_x}" "${run_y}" "${run_text}" "${run_fg}" "${run_bg}" "${run_bold}"
            run_active=0
            run_text=""
          fi
          continue
        fi

        cell_char="${cell_back_chars[idx]}"
        cell_fg="${cell_back_fgs[idx]}"
        cell_bg="${cell_back_bgs[idx]}"
        cell_bold="${cell_back_bolds[idx]}"

        if ((run_active == 1)) && [[ "${cell_fg}" == "${run_fg}" ]] && [[ "${cell_bg}" == "${run_bg}" ]] && [[ "${cell_bold}" == "${run_bold}" ]]; then
          run_text+="${cell_char}"
          continue
        fi

        if ((run_active == 1)); then
          diff_renderer_append_run "${run_x}" "${run_y}" "${run_text}" "${run_fg}" "${run_bg}" "${run_bold}"
        fi

        run_active=1
        run_x="${x}"
        run_y="${y}"
        run_fg="${cell_fg}"
        run_bg="${cell_bg}"
        run_bold="${cell_bold}"
        run_text="${cell_char}"
      done

      if ((run_active == 1)); then
        diff_renderer_append_run "${run_x}" "${run_y}" "${run_text}" "${run_fg}" "${run_bg}" "${run_bold}"
      fi
    done
  done
}
