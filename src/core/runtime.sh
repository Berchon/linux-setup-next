#!/usr/bin/env bash

runtime_alt_screen_enabled=0

runtime_emit_ansi() {
  printf '%b' "$1"
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

runtime_init() {
  runtime_enter_alternate_screen
}

runtime_shutdown() {
  runtime_leave_alternate_screen
}
