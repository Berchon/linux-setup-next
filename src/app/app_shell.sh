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
  local width="${COLUMNS:-80}"
  local height="${LINES:-24}"
  local detected_width=""
  local detected_height=""

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

  if ! app_shell_is_positive_integer "${width}"; then
    width=80
  fi

  if ! app_shell_is_positive_integer "${height}"; then
    height=24
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

  if ! declare -F cell_buffer_clear_rect >/dev/null || ! declare -F rectangle_render >/dev/null || ! declare -F cell_buffer_write_text >/dev/null || ! declare -F diff_renderer_render_dirty >/dev/null || ! declare -F dirty_regions_add >/dev/null; then
    return 0
  fi

  wallpaper_enabled="$(app_shell_theme_bool "theme.wallpaper.enabled" "true")"
  wallpaper_fg="$(app_shell_theme_int "theme.wallpaper.fg" "7")"
  wallpaper_bg="$(app_shell_theme_int "theme.wallpaper.bg" "0")"
  header_fg="$(app_shell_theme_int "theme.header.fg" "15")"
  header_bg="$(app_shell_theme_int "theme.header.bg" "4")"
  footer_fg="$(app_shell_theme_int "theme.footer.fg" "15")"
  footer_bg="$(app_shell_theme_int "theme.footer.bg" "0")"

  cell_buffer_clear_rect back 0 0 "${app_shell_screen_width}" "${app_shell_screen_height}"

  if [[ "${wallpaper_enabled}" == "1" ]]; then
    rectangle_render back 0 0 "${app_shell_screen_width}" "${app_shell_screen_height}" " " "${wallpaper_fg}" "${wallpaper_bg}" 0 none ""
  fi

  rectangle_render back 0 0 "${app_shell_screen_width}" 1 " " "${header_fg}" "${header_bg}" 1 none ""
  cell_buffer_write_text back 0 0 "${header_text:0:${app_shell_screen_width}}" "${header_fg}" "${header_bg}" 1

  if ((app_shell_screen_height > 2)) && declare -F panel_render >/dev/null; then
    center_height=$((app_shell_screen_height - 2))
    panel_render back 0 "${center_y}" "${app_shell_screen_width}" "${center_height}" " " "${header_fg}" "${wallpaper_bg}" 0 single "Main" 0
  fi

  if ((app_shell_screen_height > 1)); then
    rectangle_render back 0 "$((app_shell_screen_height - 1))" "${app_shell_screen_width}" 1 " " "${footer_fg}" "${footer_bg}" 0 none ""
    footer_text=" ${app_shell_message_bar_text}"
    cell_buffer_write_text back 0 "$((app_shell_screen_height - 1))" "${footer_text:0:${app_shell_screen_width}}" "${footer_fg}" "${footer_bg}" 0
  fi

  dirty_regions_add 0 0 "${app_shell_screen_width}" "${app_shell_screen_height}"
  diff_renderer_render_dirty
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

app_shell_run() {
  app_shell_running=1
  app_shell_set_message_bar ""

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
