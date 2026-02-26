#!/usr/bin/env bash

diff_renderer_color_capacity=16

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

diff_renderer_emit_ansi() {
  local sequence="$1"

  if declare -F runtime_emit_ansi >/dev/null; then
    runtime_emit_ansi "${sequence}"
    return 0
  fi

  printf '%b' "${sequence}"
}

diff_renderer_cursor_sequence() {
  local x="$1"
  local y="$2"

  printf '\033[%s;%sH' "$((y + 1))" "$((x + 1))"
}

diff_renderer_normalize_color_16() {
  local color="$1"

  if [[ ! "${color}" =~ ^-?[0-9]+$ ]]; then
    printf '0\n'
    return 0
  fi

  if ((color < 0)); then
    color=0
  fi

  printf '%s\n' "$((color % 16))"
}

diff_renderer_normalize_color_256() {
  local color="$1"

  if [[ ! "${color}" =~ ^-?[0-9]+$ ]]; then
    printf '0\n'
    return 0
  fi

  if ((color < 0)); then
    color=0
  fi

  if ((color > 255)); then
    color=255
  fi

  printf '%s\n' "${color}"
}

diff_renderer_set_color_capacity() {
  local requested="$1"

  if [[ "${requested}" =~ ^[0-9]+$ ]] && ((requested >= 256)); then
    diff_renderer_color_capacity=256
    return 0
  fi

  diff_renderer_color_capacity=16
}

diff_renderer_refresh_color_capacity() {
  if [[ -n "${runtime_color_capacity:-}" ]]; then
    diff_renderer_set_color_capacity "${runtime_color_capacity}"
    return 0
  fi

  diff_renderer_set_color_capacity 16
}

diff_renderer_style_sequence_16() {
  local fg_raw="$1"
  local bg_raw="$2"
  local bold="$3"
  local fg=0
  local bg=0
  local fg_code=30
  local bg_code=40

  fg="$(diff_renderer_normalize_color_16 "${fg_raw}")"
  bg="$(diff_renderer_normalize_color_16 "${bg_raw}")"

  if ((fg < 8)); then
    fg_code=$((30 + fg))
  else
    fg_code=$((90 + fg - 8))
  fi

  if ((bg < 8)); then
    bg_code=$((40 + bg))
  else
    bg_code=$((100 + bg - 8))
  fi

  if [[ "${bold}" == "1" ]]; then
    printf '\033[1;%s;%sm' "${fg_code}" "${bg_code}"
    return 0
  fi

  printf '\033[22;%s;%sm' "${fg_code}" "${bg_code}"
}

diff_renderer_style_sequence_256() {
  local fg_raw="$1"
  local bg_raw="$2"
  local bold="$3"
  local fg=0
  local bg=0

  fg="$(diff_renderer_normalize_color_256 "${fg_raw}")"
  bg="$(diff_renderer_normalize_color_256 "${bg_raw}")"

  if [[ "${bold}" == "1" ]]; then
    printf '\033[1;38;5;%s;48;5;%sm' "${fg}" "${bg}"
    return 0
  fi

  printf '\033[22;38;5;%s;48;5;%sm' "${fg}" "${bg}"
}

diff_renderer_style_sequence() {
  local fg="$1"
  local bg="$2"
  local bold="$3"

  if ((diff_renderer_color_capacity >= 256)); then
    diff_renderer_style_sequence_256 "${fg}" "${bg}" "${bold}"
    return 0
  fi

  diff_renderer_style_sequence_16 "${fg}" "${bg}" "${bold}"
}

diff_renderer_render_dirty() {
  local run_count=0
  local run_index=0
  local run_x=0
  local run_y=0
  local run_text=""
  local run_fg=0
  local run_bg=0
  local run_bold=0
  local current_fg=""
  local current_bg=""
  local current_bold=""

  if ! declare -F cell_buffer_swap >/dev/null || ! declare -F dirty_regions_reset >/dev/null; then
    return 1
  fi

  diff_renderer_refresh_color_capacity
  diff_renderer_collect_runs
  run_count="$(diff_renderer_run_count)"

  for ((run_index = 0; run_index < run_count; run_index++)); do
    IFS='|' read -r run_x run_y run_text run_fg run_bg run_bold <<< "$(diff_renderer_get_run "${run_index}")"
    diff_renderer_emit_ansi "$(diff_renderer_cursor_sequence "${run_x}" "${run_y}")"

    if [[ "${run_fg}" != "${current_fg}" || "${run_bg}" != "${current_bg}" || "${run_bold}" != "${current_bold}" ]]; then
      diff_renderer_emit_ansi "$(diff_renderer_style_sequence "${run_fg}" "${run_bg}" "${run_bold}")"
      current_fg="${run_fg}"
      current_bg="${run_bg}"
      current_bold="${run_bold}"
    fi

    diff_renderer_emit_ansi "${run_text}"
  done

  cell_buffer_swap
  dirty_regions_reset
}
