#!/usr/bin/env bash

app_shell_running=0
app_shell_last_key=""

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

app_shell_run() {
  app_shell_running=1

  if declare -F runtime_is_tty >/dev/null && ! runtime_is_tty; then
    app_shell_running=0
    return 0
  fi

  while [[ "${app_shell_running}" -eq 1 ]]; do
    if app_shell_read_key; then
      app_shell_handle_key "${app_shell_last_key}"
      continue
    fi

    if [[ "${runtime_resize_pending:-0}" -eq 1 ]]; then
      runtime_resize_pending=0
    fi
  done
}
