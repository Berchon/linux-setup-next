#!/usr/bin/env bash

runtime_alt_screen_enabled=0
runtime_input_mode_enabled=0
runtime_saved_stty=""
runtime_cleanup_ran=0
runtime_resize_pending=0
runtime_cap_cursor_positioning=0
runtime_cap_clear_screen=0
runtime_cap_cursor_visibility=0
runtime_terminal_supports_minimum=0
runtime_color_capacity=16

runtime_emit_ansi() {
  printf '%b' "$1"
}

runtime_stty_command() {
  stty "$@"
}

runtime_is_tty() {
  [[ -t 0 ]]
}

runtime_has_tput() {
  command -v tput >/dev/null 2>&1
}

runtime_tput_command() {
  tput "$@"
}

runtime_detect_terminal_capabilities() {
  local color_count=0

  runtime_cap_cursor_positioning=0
  runtime_cap_clear_screen=0
  runtime_cap_cursor_visibility=0
  runtime_terminal_supports_minimum=0
  runtime_color_capacity=16

  if ! runtime_is_tty; then
    return 0
  fi

  if runtime_has_tput; then
    if runtime_tput_command cup 0 0 >/dev/null 2>&1; then
      runtime_cap_cursor_positioning=1
    fi

    if runtime_tput_command clear >/dev/null 2>&1; then
      runtime_cap_clear_screen=1
    fi

    if runtime_tput_command civis >/dev/null 2>&1 && runtime_tput_command cnorm >/dev/null 2>&1; then
      runtime_cap_cursor_visibility=1
    fi

    color_count="$(runtime_tput_command colors 2>/dev/null || printf '0')"
    if [[ "${color_count}" =~ ^[0-9]+$ ]] && [[ "${color_count}" -ge 256 ]]; then
      runtime_color_capacity=256
    fi
  fi

  if [[ "${runtime_cap_cursor_positioning}" -eq 1 ]] && [[ "${runtime_cap_clear_screen}" -eq 1 ]] && [[ "${runtime_cap_cursor_visibility}" -eq 1 ]]; then
    runtime_terminal_supports_minimum=1
  fi
}

runtime_enter_alternate_screen() {
  if [[ "${runtime_alt_screen_enabled}" -eq 1 ]]; then
    return 0
  fi

  runtime_emit_ansi '\033[?1049h'
  runtime_alt_screen_enabled=1
}

runtime_leave_alternate_screen() {
  if [[ "${runtime_alt_screen_enabled}" -eq 0 ]]; then
    return 0
  fi

  runtime_emit_ansi '\033[?1049l'
  runtime_alt_screen_enabled=0
}

runtime_enable_input_mode() {
  if [[ "${runtime_input_mode_enabled}" -eq 1 ]]; then
    return 0
  fi

  if ! runtime_is_tty; then
    return 0
  fi

  runtime_saved_stty="$(runtime_stty_command -g)"
  runtime_stty_command -echo -icanon min 0 time 1
  runtime_input_mode_enabled=1
}

runtime_disable_input_mode() {
  if [[ "${runtime_input_mode_enabled}" -eq 0 ]]; then
    return 0
  fi

  if runtime_is_tty && [[ -n "${runtime_saved_stty}" ]]; then
    runtime_stty_command "${runtime_saved_stty}"
  fi

  runtime_input_mode_enabled=0
  runtime_saved_stty=""
}

runtime_init() {
  runtime_detect_terminal_capabilities
  runtime_enter_alternate_screen
  runtime_enable_input_mode
}

runtime_shutdown() {
  runtime_disable_input_mode
  runtime_leave_alternate_screen
}

runtime_cleanup() {
  if [[ "${runtime_cleanup_ran}" -eq 1 ]]; then
    return 0
  fi

  runtime_cleanup_ran=1
  runtime_shutdown
}

runtime_handle_exit() {
  runtime_cleanup
}

runtime_handle_interrupt() {
  runtime_cleanup
  exit 130
}

runtime_handle_terminate() {
  runtime_cleanup
  exit 143
}

runtime_handle_winch() {
  runtime_resize_pending=1
}

runtime_install_signal_traps() {
  trap runtime_handle_exit EXIT
  trap runtime_handle_interrupt INT
  trap runtime_handle_terminate TERM
  trap runtime_handle_winch WINCH
}
