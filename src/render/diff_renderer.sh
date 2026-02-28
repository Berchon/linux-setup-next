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
  local rect_x=0
  local rect_y=0
  local rect_width=0
  local rect_height=0
  local y=0
  local x=0
  local idx=0
  local run_index=0
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

  if ! declare -p dirty_regions_xs >/dev/null 2>&1 || ! declare -p dirty_regions_ys >/dev/null 2>&1 || ! declare -p dirty_regions_widths >/dev/null 2>&1 || ! declare -p dirty_regions_heights >/dev/null 2>&1; then
    return 1
  fi

  diff_renderer_reset_runs
  dirty_count="${#dirty_regions_xs[@]}"

  for ((dirty_index = 0; dirty_index < dirty_count; dirty_index++)); do
    rect_x="${dirty_regions_xs[dirty_index]}"
    rect_y="${dirty_regions_ys[dirty_index]}"
    rect_width="${dirty_regions_widths[dirty_index]}"
    rect_height="${dirty_regions_heights[dirty_index]}"

    for ((y = rect_y; y < rect_y + rect_height; y++)); do
      run_active=0
      run_text=""

      for ((x = rect_x; x < rect_x + rect_width; x++)); do
        idx=$((y * cell_buffer_width + x))

        if [[ "${cell_front_chars[idx]}" == "${cell_back_chars[idx]}" ]] && [[ "${cell_front_fgs[idx]}" == "${cell_back_fgs[idx]}" ]] && [[ "${cell_front_bgs[idx]}" == "${cell_back_bgs[idx]}" ]] && [[ "${cell_front_bolds[idx]}" == "${cell_back_bolds[idx]}" ]]; then
          if ((run_active == 1)); then
            diff_renderer_run_xs[run_index]="${run_x}"
            diff_renderer_run_ys[run_index]="${run_y}"
            diff_renderer_run_texts[run_index]="${run_text}"
            diff_renderer_run_fgs[run_index]="${run_fg}"
            diff_renderer_run_bgs[run_index]="${run_bg}"
            diff_renderer_run_bolds[run_index]="${run_bold}"
            run_index=$((run_index + 1))
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
          diff_renderer_run_xs[run_index]="${run_x}"
          diff_renderer_run_ys[run_index]="${run_y}"
          diff_renderer_run_texts[run_index]="${run_text}"
          diff_renderer_run_fgs[run_index]="${run_fg}"
          diff_renderer_run_bgs[run_index]="${run_bg}"
          diff_renderer_run_bolds[run_index]="${run_bold}"
          run_index=$((run_index + 1))
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
        diff_renderer_run_xs[run_index]="${run_x}"
        diff_renderer_run_ys[run_index]="${run_y}"
        diff_renderer_run_texts[run_index]="${run_text}"
        diff_renderer_run_fgs[run_index]="${run_fg}"
        diff_renderer_run_bgs[run_index]="${run_bg}"
        diff_renderer_run_bolds[run_index]="${run_bold}"
        run_index=$((run_index + 1))
      fi
    done
  done
}

diff_renderer_collect_runs_assume_changed() {
  local dirty_count=0
  local dirty_index=0
  local rect_x=0
  local rect_y=0
  local rect_width=0
  local rect_height=0
  local y=0
  local x=0
  local idx=0
  local run_index=0
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

  if ! declare -p dirty_regions_xs >/dev/null 2>&1 || ! declare -p dirty_regions_ys >/dev/null 2>&1 || ! declare -p dirty_regions_widths >/dev/null 2>&1 || ! declare -p dirty_regions_heights >/dev/null 2>&1; then
    return 1
  fi

  diff_renderer_reset_runs
  dirty_count="${#dirty_regions_xs[@]}"

  for ((dirty_index = 0; dirty_index < dirty_count; dirty_index++)); do
    rect_x="${dirty_regions_xs[dirty_index]}"
    rect_y="${dirty_regions_ys[dirty_index]}"
    rect_width="${dirty_regions_widths[dirty_index]}"
    rect_height="${dirty_regions_heights[dirty_index]}"

    for ((y = rect_y; y < rect_y + rect_height; y++)); do
      run_active=0
      run_text=""

      for ((x = rect_x; x < rect_x + rect_width; x++)); do
        idx=$((y * cell_buffer_width + x))
        cell_char="${cell_back_chars[idx]}"
        cell_fg="${cell_back_fgs[idx]}"
        cell_bg="${cell_back_bgs[idx]}"
        cell_bold="${cell_back_bolds[idx]}"

        if ((run_active == 1)) && [[ "${cell_fg}" == "${run_fg}" ]] && [[ "${cell_bg}" == "${run_bg}" ]] && [[ "${cell_bold}" == "${run_bold}" ]]; then
          run_text+="${cell_char}"
          continue
        fi

        if ((run_active == 1)); then
          diff_renderer_run_xs[run_index]="${run_x}"
          diff_renderer_run_ys[run_index]="${run_y}"
          diff_renderer_run_texts[run_index]="${run_text}"
          diff_renderer_run_fgs[run_index]="${run_fg}"
          diff_renderer_run_bgs[run_index]="${run_bg}"
          diff_renderer_run_bolds[run_index]="${run_bold}"
          run_index=$((run_index + 1))
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
        diff_renderer_run_xs[run_index]="${run_x}"
        diff_renderer_run_ys[run_index]="${run_y}"
        diff_renderer_run_texts[run_index]="${run_text}"
        diff_renderer_run_fgs[run_index]="${run_fg}"
        diff_renderer_run_bgs[run_index]="${run_bg}"
        diff_renderer_run_bolds[run_index]="${run_bold}"
        run_index=$((run_index + 1))
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
  local assume_changed="${1:-0}"
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
  local ansi_buffer=""
  local style_sequence=""
  local use_fast_style=0
  local fg_fast=0
  local bg_fast=0
  local fg_code_fast=30
  local bg_code_fast=40

  if ! declare -F cell_buffer_swap >/dev/null || ! declare -F dirty_regions_reset >/dev/null; then
    return 1
  fi

  diff_renderer_refresh_color_capacity
  if [[ "${assume_changed}" == "1" ]]; then
    use_fast_style=1
    diff_renderer_collect_runs_assume_changed
  else
    diff_renderer_collect_runs
  fi
  run_count="${#diff_renderer_run_xs[@]}"

  for ((run_index = 0; run_index < run_count; run_index++)); do
    run_x="${diff_renderer_run_xs[run_index]}"
    run_y="${diff_renderer_run_ys[run_index]}"
    run_text="${diff_renderer_run_texts[run_index]}"
    run_fg="${diff_renderer_run_fgs[run_index]}"
    run_bg="${diff_renderer_run_bgs[run_index]}"
    run_bold="${diff_renderer_run_bolds[run_index]}"
    ansi_buffer+=$'\033['"$((run_y + 1))"';'"$((run_x + 1))"'H'

    if [[ "${run_fg}" != "${current_fg}" || "${run_bg}" != "${current_bg}" || "${run_bold}" != "${current_bold}" ]]; then
      if ((use_fast_style == 1)); then
        fg_fast="${run_fg}"
        bg_fast="${run_bg}"
        if ((diff_renderer_color_capacity >= 256)); then
          if ((fg_fast < 0)); then
            fg_fast=0
          elif ((fg_fast > 255)); then
            fg_fast=255
          fi
          if ((bg_fast < 0)); then
            bg_fast=0
          elif ((bg_fast > 255)); then
            bg_fast=255
          fi

          if [[ "${run_bold}" == "1" ]]; then
            ansi_buffer+=$'\033[1;38;5;'"${fg_fast}"$';48;5;'"${bg_fast}"'m'
          else
            ansi_buffer+=$'\033[22;38;5;'"${fg_fast}"$';48;5;'"${bg_fast}"'m'
          fi
        else
          if ((fg_fast < 0)); then
            fg_fast=0
          fi
          if ((bg_fast < 0)); then
            bg_fast=0
          fi
          fg_fast=$((fg_fast % 16))
          bg_fast=$((bg_fast % 16))

          if ((fg_fast < 8)); then
            fg_code_fast=$((30 + fg_fast))
          else
            fg_code_fast=$((90 + fg_fast - 8))
          fi
          if ((bg_fast < 8)); then
            bg_code_fast=$((40 + bg_fast))
          else
            bg_code_fast=$((100 + bg_fast - 8))
          fi

          if [[ "${run_bold}" == "1" ]]; then
            ansi_buffer+=$'\033[1;'"${fg_code_fast}"';'"${bg_code_fast}"'m'
          else
            ansi_buffer+=$'\033[22;'"${fg_code_fast}"';'"${bg_code_fast}"'m'
          fi
        fi
      else
        style_sequence="$(diff_renderer_style_sequence "${run_fg}" "${run_bg}" "${run_bold}")"
        ansi_buffer+="${style_sequence}"
      fi
      current_fg="${run_fg}"
      current_bg="${run_bg}"
      current_bold="${run_bold}"
    fi

    ansi_buffer+="${run_text}"
  done

  if [[ -n "${ansi_buffer}" ]]; then
    diff_renderer_emit_ansi "${ansi_buffer}"
  fi

  cell_buffer_swap
  dirty_regions_reset
}
