#!/usr/bin/env bash

app_shell_running=0
app_shell_last_key=""
app_shell_screen_width=0
app_shell_screen_height=0
app_shell_message_bar_text=""

app_shell_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

app_shell_theme_bool() {
  local key="$1"
  local fallback="$2"
  local value=""

  if ! declare -F ui_state_get_config >/dev/null; then
    printf '%s\n' "${fallback}"
    return 0
  fi

  value="$(ui_state_get_config "${key}" "${fallback}")"
  case "${value}" in
    true)
      printf '1\n'
      ;;
    *)
      printf '0\n'
      ;;
  esac
}

app_shell_theme_int() {
  local key="$1"
  local fallback="$2"

  if ! declare -F ui_state_get_config >/dev/null; then
    printf '%s\n' "${fallback}"
    return 0
  fi

  ui_state_get_config "${key}" "${fallback}"
}

app_shell_detect_terminal_size() {
  local width="${COLUMNS:-}"
  local height="${LINES:-}"
  local detected_width=""
  local detected_height=""

  if ! app_shell_is_positive_integer "${width}"; then
    width=80
  fi

  if ! app_shell_is_positive_integer "${height}"; then
    height=24
  fi

  if (! app_shell_is_positive_integer "${COLUMNS:-}") || (! app_shell_is_positive_integer "${LINES:-}"); then
    if declare -F runtime_is_tty >/dev/null && runtime_is_tty && declare -F runtime_has_tput >/dev/null && runtime_has_tput && declare -F runtime_tput_command >/dev/null; then
      detected_width="$(runtime_tput_command cols 2>/dev/null || printf '')"
      detected_height="$(runtime_tput_command lines 2>/dev/null || printf '')"

      if app_shell_is_positive_integer "${detected_width}"; then
        width="${detected_width}"
      fi

      if app_shell_is_positive_integer "${detected_height}"; then
        height="${detected_height}"
      fi
    fi
  fi

  printf '%s|%s\n' "${width}" "${height}"
}

app_shell_init_framebuffer() {
  local width="$1"
  local height="$2"

  if ! declare -F cell_buffer_init >/dev/null || ! declare -F dirty_regions_init >/dev/null; then
    return 0
  fi

  cell_buffer_init "${width}" "${height}" || return 1
  dirty_regions_init "${width}" "${height}" || return 1

  app_shell_screen_width="${width}"
  app_shell_screen_height="${height}"
}

app_shell_sync_viewport() {
  local force_reinit="${1:-0}"
  local size=""
  local width=0
  local height=0

  size="$(app_shell_detect_terminal_size)"
  IFS='|' read -r width height <<< "${size}"

  if [[ "${force_reinit}" == "1" ]] || [[ "${width}" != "${app_shell_screen_width}" ]] || [[ "${height}" != "${app_shell_screen_height}" ]]; then
    app_shell_init_framebuffer "${width}" "${height}" || return 1
  fi
}

app_shell_back_write_cell() {
  local x="$1"
  local y="$2"
  local char="$3"
  local fg="$4"
  local bg="$5"
  local bold="$6"
  local idx=0

  idx=$((y * cell_buffer_width + x))
  cell_back_chars[idx]="${char}"
  cell_back_fgs[idx]="${fg}"
  cell_back_bgs[idx]="${bg}"
  cell_back_bolds[idx]="${bold}"
}

app_shell_draw_back_box_border() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local fg="$5"
  local bg="$6"
  local bold="$7"
  local title="${8:-}"
  local right=0
  local bottom=0
  local current_x=0
  local current_y=0
  local tl="+"
  local tr="+"
  local bl="+"
  local br="+"
  local h="-"
  local v="|"
  local title_text=""

  if ! declare -F cell_buffer_write_text >/dev/null; then
    return 0
  fi

  if ! app_shell_is_positive_integer "${width}" || ! app_shell_is_positive_integer "${height}"; then
    return 0
  fi

  if declare -F rectangle_border_chars >/dev/null && rectangle_border_chars single; then
    tl="${rectangle_border_tl}"
    tr="${rectangle_border_tr}"
    bl="${rectangle_border_bl}"
    br="${rectangle_border_br}"
    h="${rectangle_border_h}"
    v="${rectangle_border_v}"
  fi

  right=$((x + width - 1))
  bottom=$((y + height - 1))

  app_shell_back_write_cell "${x}" "${y}" "${tl}" "${fg}" "${bg}" "${bold}"

  if ((width > 1)); then
    app_shell_back_write_cell "${right}" "${y}" "${tr}" "${fg}" "${bg}" "${bold}"
  fi
  if ((height > 1)); then
    app_shell_back_write_cell "${x}" "${bottom}" "${bl}" "${fg}" "${bg}" "${bold}"
  fi
  if ((width > 1 && height > 1)); then
    app_shell_back_write_cell "${right}" "${bottom}" "${br}" "${fg}" "${bg}" "${bold}"
  fi

  if ((width > 2)); then
    for ((current_x = x + 1; current_x < right; current_x++)); do
      app_shell_back_write_cell "${current_x}" "${y}" "${h}" "${fg}" "${bg}" "${bold}"

      if ((height > 1)); then
        app_shell_back_write_cell "${current_x}" "${bottom}" "${h}" "${fg}" "${bg}" "${bold}"
      fi
    done
  fi

  if ((height > 2)); then
    for ((current_y = y + 1; current_y < bottom; current_y++)); do
      app_shell_back_write_cell "${x}" "${current_y}" "${v}" "${fg}" "${bg}" "${bold}"

      if ((width > 1)); then
        app_shell_back_write_cell "${right}" "${current_y}" "${v}" "${fg}" "${bg}" "${bold}"
      fi
    done
  fi

  if [[ -n "${title}" ]] && ((width > 4)); then
    title_text=" ${title} "
    title_text="${title_text:0:$((width - 2))}"
    cell_buffer_write_text back "$((x + 1))" "${y}" "${title_text}" "${fg}" "${bg}" "${bold}"
  fi
}

app_shell_fill_back_row() {
  local y="$1"
  local width="$2"
  local fg="$3"
  local bg="$4"
  local bold="$5"
  local start_idx=0
  local idx=0

  start_idx=$((y * cell_buffer_width))
  for ((idx = start_idx; idx < start_idx + width; idx++)); do
    cell_back_chars[idx]=' '
    cell_back_fgs[idx]="${fg}"
    cell_back_bgs[idx]="${bg}"
    cell_back_bolds[idx]="${bold}"
  done
}

app_shell_mark_base_layout_dirty_regions() {
  local wallpaper_full_fill="$1"
  local width="$2"
  local height="$3"
  local center_y=1
  local center_height=0
  local center_bottom=0

  if [[ "${wallpaper_full_fill}" == "1" ]]; then
    dirty_regions_add 0 0 "${width}" "${height}"
    return 0
  fi

  dirty_regions_add 0 0 "${width}" 1

  if ((height > 1)); then
    dirty_regions_add 0 "$((height - 1))" "${width}" 1
  fi

  if ((height > 2)); then
    center_height=$((height - 2))
    center_bottom=$((center_y + center_height - 1))

    dirty_regions_add 0 "${center_y}" "${width}" 1
    dirty_regions_add 0 "${center_bottom}" "${width}" 1

    if ((center_height > 2)); then
      dirty_regions_add 0 "$((center_y + 1))" 1 "$((center_height - 2))"
      if ((width > 1)); then
        dirty_regions_add "$((width - 1))" "$((center_y + 1))" 1 "$((center_height - 2))"
      fi
    fi
  fi
}

app_shell_render_base_layout() {
  local wallpaper_enabled=0
  local wallpaper_fg=7
  local wallpaper_bg=0
  local header_fg=15
  local header_bg=4
  local footer_fg=15
  local footer_bg=0
  local center_y=1
  local center_height=0
  local header_text=" linux-setup-next "
  local footer_text=""
  local wallpaper_requires_full_fill=0
  local y=0

  if ! declare -F cell_buffer_write_text >/dev/null || ! declare -F diff_renderer_render_dirty >/dev/null || ! declare -F dirty_regions_add >/dev/null; then
    return 0
  fi

  wallpaper_enabled="$(app_shell_theme_bool "theme.wallpaper.enabled" "true")"
  wallpaper_fg="$(app_shell_theme_int "theme.wallpaper.fg" "7")"
  wallpaper_bg="$(app_shell_theme_int "theme.wallpaper.bg" "0")"
  header_fg="$(app_shell_theme_int "theme.header.fg" "15")"
  header_bg="$(app_shell_theme_int "theme.header.bg" "4")"
  footer_fg="$(app_shell_theme_int "theme.footer.fg" "15")"
  footer_bg="$(app_shell_theme_int "theme.footer.bg" "0")"

  if [[ "${wallpaper_enabled}" == "1" ]]; then
    if [[ "${wallpaper_fg}" != "7" ]] || [[ "${wallpaper_bg}" != "0" ]]; then
      wallpaper_requires_full_fill=1
    fi
  fi

  if [[ "${wallpaper_requires_full_fill}" == "1" ]]; then
    for ((y = 0; y < app_shell_screen_height; y++)); do
      app_shell_fill_back_row "${y}" "${app_shell_screen_width}" "${wallpaper_fg}" "${wallpaper_bg}" 0
    done
  fi

  app_shell_fill_back_row 0 "${app_shell_screen_width}" "${header_fg}" "${header_bg}" 1
  cell_buffer_write_text back 0 0 "${header_text:0:${app_shell_screen_width}}" "${header_fg}" "${header_bg}" 1

  if ((app_shell_screen_height > 2)); then
    center_height=$((app_shell_screen_height - 2))
    app_shell_draw_back_box_border 0 "${center_y}" "${app_shell_screen_width}" "${center_height}" "${header_fg}" "${wallpaper_bg}" 0 "Main"
  fi

  if ((app_shell_screen_height > 1)); then
    app_shell_fill_back_row "$((app_shell_screen_height - 1))" "${app_shell_screen_width}" "${footer_fg}" "${footer_bg}" 0
    footer_text=" ${app_shell_message_bar_text}"
    cell_buffer_write_text back 0 "$((app_shell_screen_height - 1))" "${footer_text:0:${app_shell_screen_width}}" "${footer_fg}" "${footer_bg}" 0
  fi

  app_shell_mark_base_layout_dirty_regions \
    "${wallpaper_requires_full_fill}" \
    "${app_shell_screen_width}" \
    "${app_shell_screen_height}"
  diff_renderer_render_dirty 1
}

app_shell_read_key() {
  local first_char=""
  local tail_chars=""

  app_shell_last_key=""

  if ! IFS= read -r -s -n 1 -t 0.05 first_char; then
    return 1
  fi

  if [[ "${first_char}" == $'\033' ]]; then
    IFS= read -r -s -n 2 -t 0.001 tail_chars || true
    app_shell_last_key="${first_char}${tail_chars}"
    return 0
  fi

  app_shell_last_key="${first_char}"
  return 0
}

app_shell_map_key_action() {
  local key="$1"

  if declare -F menu_map_input_key >/dev/null; then
    menu_map_input_key "${key}"
    return 0
  fi

  case "${key}" in
    q|Q)
      printf 'quit\n'
      ;;
    *)
      printf 'noop\n'
      ;;
  esac
}

app_shell_handle_key() {
  local key="$1"
  local action=""

  action="$(app_shell_map_key_action "${key}")"

  if [[ "${action}" == "quit" ]]; then
    app_shell_running=0
  fi
}

app_shell_set_message_bar() {
  app_shell_message_bar_text="$1"
}

app_shell_default_message_bar() {
  printf 'Ready - press Q to exit.\n'
}

app_shell_run() {
  app_shell_running=1
  app_shell_set_message_bar "$(app_shell_default_message_bar)"

  app_shell_sync_viewport 1 || return 1
  app_shell_render_base_layout || return 1

  if declare -F runtime_is_tty >/dev/null && ! runtime_is_tty; then
    app_shell_running=0
    return 0
  fi

  while [[ "${app_shell_running}" -eq 1 ]]; do
    if [[ "${runtime_resize_pending:-0}" -eq 1 ]]; then
      runtime_resize_pending=0
      app_shell_sync_viewport 1 || return 1
      app_shell_render_base_layout || return 1
      continue
    fi

    if app_shell_read_key; then
      app_shell_handle_key "${app_shell_last_key}"
      continue
    fi
  done
}
