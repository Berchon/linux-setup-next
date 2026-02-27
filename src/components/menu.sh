#!/usr/bin/env bash

menu_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

menu_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

menu_render_line() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local label="$5"
  local is_selected="$6"
  local normal_fg="$7"
  local normal_bg="$8"
  local selected_fg="$9"
  local selected_bg="${10}"
  local normal_bold="${11:-0}"
  local selected_bold="${12:-1}"
  local prefix=""
  local visible_width=0
  local clipped_label=""
  local line=""
  local fg=0
  local bg=0
  local bold=0

  if ! declare -F cell_buffer_write_text >/dev/null; then
    return 1
  fi

  if ! menu_is_integer "${x}" || ! menu_is_integer "${y}"; then
    return 1
  fi

  if ! menu_is_non_negative_integer "${width}"; then
    return 1
  fi

  if ((width == 0)); then
    return 0
  fi

  if [[ "${is_selected}" == "1" ]]; then
    prefix="> "
    fg="${selected_fg}"
    bg="${selected_bg}"
    bold="${selected_bold}"
  else
    prefix="  "
    fg="${normal_fg}"
    bg="${normal_bg}"
    bold="${normal_bold}"
  fi

  visible_width=$((width - ${#prefix}))
  if ((visible_width < 0)); then
    visible_width=0
  fi

  clipped_label="${label:0:visible_width}"
  line="${prefix}${clipped_label}"
  printf -v line '%-*s' "${width}" "${line:0:width}"

  cell_buffer_write_text "${buffer_name}" "${x}" "${y}" "${line}" "${fg}" "${bg}" "${bold}"
}

menu_render_viewport() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local selected_index="$6"
  local viewport_start="$7"
  local normal_fg="$8"
  local normal_bg="$9"
  local selected_fg="${10}"
  local selected_bg="${11}"
  shift 11
  local -a node_ids=("$@")
  local row=0
  local item_index=0
  local is_selected=0
  local node_id=""
  local label=""

  if ! declare -F menu_state_get_label >/dev/null; then
    return 1
  fi

  if ! menu_is_integer "${x}" || ! menu_is_integer "${y}" || ! menu_is_integer "${selected_index}" || ! menu_is_integer "${viewport_start}"; then
    return 1
  fi

  if ! menu_is_non_negative_integer "${width}" || ! menu_is_non_negative_integer "${height}"; then
    return 1
  fi

  for ((row = 0; row < height; row++)); do
    item_index=$((viewport_start + row))
    is_selected=0
    label=""

    if ((item_index >= 0 && item_index < ${#node_ids[@]})); then
      node_id="${node_ids[item_index]}"
      label="$(menu_state_get_label "${node_id}")" || return 1
      if ((item_index == selected_index)); then
        is_selected=1
      fi
    fi

    menu_render_line \
      "${buffer_name}" \
      "${x}" \
      "$((y + row))" \
      "${width}" \
      "${label}" \
      "${is_selected}" \
      "${normal_fg}" \
      "${normal_bg}" \
      "${selected_fg}" \
      "${selected_bg}" \
      0 \
      1
  done
}

menu_selection_apply_delta() {
  local current_index="$1"
  local delta="$2"
  local item_count="$3"
  local next_index=0

  if ! menu_is_integer "${current_index}" || ! menu_is_integer "${delta}" || ! menu_is_non_negative_integer "${item_count}"; then
    return 1
  fi

  if ((item_count == 0)); then
    printf '0\n'
    return 0
  fi

  next_index=$((current_index + delta))
  if ((next_index < 0)); then
    next_index=0
  fi
  if ((next_index >= item_count)); then
    next_index=$((item_count - 1))
  fi

  printf '%s\n' "${next_index}"
}

menu_mark_selection_delta_dirty() {
  local x="$1"
  local y="$2"
  local width="$3"
  local viewport_height="$4"
  local old_index="$5"
  local new_index="$6"
  local viewport_start="$7"
  local viewport_end=0
  local old_row=0
  local new_row=0

  if ! declare -F dirty_regions_add >/dev/null; then
    return 1
  fi

  if ! menu_is_integer "${x}" || ! menu_is_integer "${y}" || ! menu_is_integer "${old_index}" || ! menu_is_integer "${new_index}" || ! menu_is_integer "${viewport_start}"; then
    return 1
  fi

  if ! menu_is_non_negative_integer "${width}" || ! menu_is_non_negative_integer "${viewport_height}"; then
    return 1
  fi

  if ((width == 0 || viewport_height == 0 || old_index == new_index)); then
    return 0
  fi

  viewport_end=$((viewport_start + viewport_height))

  if ((old_index >= viewport_start && old_index < viewport_end)); then
    old_row=$((old_index - viewport_start))
    dirty_regions_add "${x}" "$((y + old_row))" "${width}" 1
  fi

  if ((new_index >= viewport_start && new_index < viewport_end)); then
    new_row=$((new_index - viewport_start))
    dirty_regions_add "${x}" "$((y + new_row))" "${width}" 1
  fi
}
