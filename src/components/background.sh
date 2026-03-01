#!/usr/bin/env bash

if [[ -z "${background_component_module_loaded:-}" ]]; then
  background_component_module_loaded=1

  readonly BACKGROUND_COMPONENT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  readonly BACKGROUND_DEFAULT_PATTERNS_DIR="${BACKGROUND_COMPONENT_ROOT}/config/patterns"
  readonly BACKGROUND_ROW_SEPARATOR=$'\x1e'

  declare -gA background_pattern_rows=()
  declare -gA background_pattern_widths=()
  declare -gA background_pattern_heights=()

  declare -g background_patterns_loaded=0
  declare -g background_patterns_last_error=""
fi

background_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

background_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

background_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

background_trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "${value}"
}

background_reset_registry() {
  background_pattern_rows=()
  background_pattern_widths=()
  background_pattern_heights=()
  background_patterns_loaded=0
  background_patterns_last_error=""
}

background_pattern_exists() {
  local pattern_id="$1"

  [[ -n "${pattern_id}" ]] && [[ -v "background_pattern_rows[${pattern_id}]" ]]
}

background_register_pattern() {
  local pattern_id="$1"
  shift

  local -a rows=("$@")
  local max_width=0
  local height=0
  local row=""
  local normalized_rows=""

  if [[ -z "${pattern_id}" ]]; then
    background_patterns_last_error="background: pattern id is required"
    return 1
  fi

  if ((${#rows[@]} == 0)); then
    rows=(' ')
  fi

  for row in "${rows[@]}"; do
    if ((${#row} > max_width)); then
      max_width="${#row}"
    fi
  done

  if ((max_width == 0)); then
    max_width=1
  fi

  for row in "${rows[@]}"; do
    printf -v row '%-*s' "${max_width}" "${row}"
    normalized_rows+="${row}${BACKGROUND_ROW_SEPARATOR}"
    height=$((height + 1))
  done

  background_pattern_rows["${pattern_id}"]="${normalized_rows}"
  background_pattern_widths["${pattern_id}"]="${max_width}"
  background_pattern_heights["${pattern_id}"]="${height}"
}

background_register_fallback_pattern() {
  background_register_pattern "default" " "
  background_patterns_loaded=1
}

background_pattern_dimensions() {
  local pattern_id="$1"
  local width=0
  local height=0

  if ! background_pattern_exists "${pattern_id}"; then
    return 1
  fi

  width="${background_pattern_widths[${pattern_id}]}"
  height="${background_pattern_heights[${pattern_id}]}"
  printf '%s|%s\n' "${width}" "${height}"
}

background_parse_pattern_file() {
  local pattern_file="$1"
  local line=""
  local line_number=0
  local id=""
  local trimmed=""
  local in_pattern=0
  local -a rows=()

  if [[ ! -f "${pattern_file}" ]]; then
    background_patterns_last_error="background: missing pattern file '${pattern_file}'"
    return 1
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_number=$((line_number + 1))
    line="${line%$'\r'}"

    if ((in_pattern == 1)); then
      rows+=("${line}")
      continue
    fi

    trimmed="$(background_trim "${line}")"

    if [[ -z "${trimmed}" ]] || [[ "${trimmed:0:1}" == "#" ]]; then
      continue
    fi

    if [[ "${trimmed}" == id=* ]]; then
      id="$(background_trim "${trimmed#id=}")"
      continue
    fi

    if [[ "${trimmed}" == "pattern:" ]]; then
      in_pattern=1
      continue
    fi

    background_patterns_last_error="background: invalid line ${line_number} in '${pattern_file}'"
    return 1
  done < "${pattern_file}"

  if [[ -z "${id}" ]]; then
    background_patterns_last_error="background: missing id in '${pattern_file}'"
    return 1
  fi

  if ((in_pattern == 0)); then
    background_patterns_last_error="background: missing 'pattern:' section in '${pattern_file}'"
    return 1
  fi

  if ((${#rows[@]} == 0)); then
    background_patterns_last_error="background: empty pattern in '${pattern_file}'"
    return 1
  fi

  background_register_pattern "${id}" "${rows[@]}"
}

background_load_patterns_from_dir() {
  local patterns_dir="$1"
  local pattern_file=""
  local loaded_count=0

  background_reset_registry

  if [[ ! -d "${patterns_dir}" ]]; then
    background_patterns_last_error="background: patterns directory not found '${patterns_dir}'"
    background_register_fallback_pattern
    return 1
  fi

  while IFS= read -r pattern_file; do
    if ! background_parse_pattern_file "${pattern_file}"; then
      background_register_fallback_pattern
      return 1
    fi
    loaded_count=$((loaded_count + 1))
  done < <(find "${patterns_dir}" -maxdepth 1 -type f -name '*.pattern' | sort)

  if ((loaded_count == 0)); then
    background_patterns_last_error="background: no .pattern files found in '${patterns_dir}'"
    background_register_fallback_pattern
    return 1
  fi

  background_patterns_loaded=1
}

background_ensure_patterns_loaded() {
  local patterns_dir="${1:-${BACKGROUND_DEFAULT_PATTERNS_DIR}}"

  if [[ "${background_patterns_loaded}" -eq 1 ]]; then
    return 0
  fi

  if background_load_patterns_from_dir "${patterns_dir}"; then
    return 0
  fi

  # Keep the UI operable even if pattern files are missing or invalid.
  return 1
}

background_track_dirty_region() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"

  if ! background_is_non_negative_integer "${width}" || ! background_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  if declare -F dirty_regions_add >/dev/null; then
    dirty_regions_add "${x}" "${y}" "${width}" "${height}"
  fi
}

background_clip_rect() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local start_x=0
  local start_y=0
  local end_x=0
  local end_y=0

  if ! background_is_integer "${x}" || ! background_is_integer "${y}"; then
    return 1
  fi

  if ! background_is_non_negative_integer "${width}" || ! background_is_non_negative_integer "${height}"; then
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

background_render_region() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local pattern_id="$6"
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
  local pattern_width=0
  local pattern_height=0
  local pattern_rows_serialized=""
  local -a pattern_rows=()
  local row_index=0
  local column_index=0
  local row_value=""
  local char=' '

  if ! declare -F cell_buffer_write_cell >/dev/null; then
    return 1
  fi

  if ! background_is_integer "${x}" || ! background_is_integer "${y}"; then
    return 1
  fi

  if ! background_is_non_negative_integer "${width}" || ! background_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  if ! background_ensure_patterns_loaded; then
    true
  fi

  if ! background_pattern_exists "${pattern_id}"; then
    pattern_id="default"
  fi

  if ! background_pattern_exists "${pattern_id}"; then
    background_register_fallback_pattern
  fi

  pattern_width="${background_pattern_widths[${pattern_id}]}"
  pattern_height="${background_pattern_heights[${pattern_id}]}"
  pattern_rows_serialized="${background_pattern_rows[${pattern_id}]}"
  IFS="${BACKGROUND_ROW_SEPARATOR}" read -r -a pattern_rows <<< "${pattern_rows_serialized}"

  clipped="$(background_clip_rect "${x}" "${y}" "${width}" "${height}")" || return 1
  IFS='|' read -r start_x start_y clipped_width clipped_height <<< "${clipped}"

  if ((clipped_width == 0 || clipped_height == 0)); then
    return 0
  fi

  for ((current_y = start_y; current_y < start_y + clipped_height; current_y++)); do
    row_index=$(((current_y - y) % pattern_height))
    row_value="${pattern_rows[row_index]}"

    for ((current_x = start_x; current_x < start_x + clipped_width; current_x++)); do
      column_index=$(((current_x - x) % pattern_width))
      char="${row_value:column_index:1}"
      if [[ -z "${char}" ]]; then
        char=' '
      fi

      cell_buffer_write_cell "${buffer_name}" "${current_x}" "${current_y}" "${char}" "${fg}" "${bg}" "${bold}"
    done
  done
}

background_render_screen() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local pattern_id="$4"
  local fg="$5"
  local bg="$6"
  local bold="$7"

  background_render_region "${buffer_name}" 0 0 "${screen_width}" "${screen_height}" "${pattern_id}" "${fg}" "${bg}" "${bold}"
}

background_render_header() {
  local buffer_name="$1"
  local screen_width="$2"
  local header_height="$3"
  local pattern_id="$4"
  local fg="$5"
  local bg="$6"
  local bold="$7"

  background_render_region "${buffer_name}" 0 0 "${screen_width}" "${header_height}" "${pattern_id}" "${fg}" "${bg}" "${bold}"
}

background_render_footer() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local footer_height="$4"
  local pattern_id="$5"
  local fg="$6"
  local bg="$7"
  local bold="$8"
  local footer_y=0

  if ! background_is_positive_integer "${footer_height}"; then
    return 0
  fi

  if ((footer_height > screen_height)); then
    footer_height="${screen_height}"
  fi

  footer_y=$((screen_height - footer_height))
  background_render_region "${buffer_name}" 0 "${footer_y}" "${screen_width}" "${footer_height}" "${pattern_id}" "${fg}" "${bg}" "${bold}"
}

background_render_content() {
  local buffer_name="$1"
  local screen_width="$2"
  local screen_height="$3"
  local header_height="$4"
  local footer_height="$5"
  local pattern_id="$6"
  local fg="$7"
  local bg="$8"
  local bold="$9"
  local content_y=0
  local content_height=0

  if ! background_is_non_negative_integer "${header_height}" || ! background_is_non_negative_integer "${footer_height}"; then
    return 1
  fi

  content_y="${header_height}"
  content_height=$((screen_height - header_height - footer_height))
  if ((content_height <= 0)); then
    return 0
  fi

  background_render_region "${buffer_name}" 0 "${content_y}" "${screen_width}" "${content_height}" "${pattern_id}" "${fg}" "${bg}" "${bold}"
}
