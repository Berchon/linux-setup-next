#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/app/app_shell.sh
source "${TEST_ROOT}/src/app/app_shell.sh"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

runtime_is_tty() {
  return 0
}

read_sequence_index=0
app_shell_read_key() {
  case "${read_sequence_index}" in
    0)
      read_sequence_index=$((read_sequence_index + 1))
      app_shell_last_key='j'
      return 0
      ;;
    1)
      read_sequence_index=$((read_sequence_index + 1))
      app_shell_last_key='q'
      return 0
      ;;
    *)
      app_shell_last_key=''
      return 1
      ;;
  esac
}

app_shell_running=0
app_shell_run
assert_eq "${app_shell_running}" "0" "app shell should stop loop after quit action"
assert_eq "${read_sequence_index}" "2" "app shell should consume key sequence until quit"

runtime_is_tty() {
  return 1
}

read_sequence_index=0
app_shell_running=1
app_shell_run
assert_eq "${app_shell_running}" "0" "app shell should exit immediately in non-tty mode"
assert_eq "${read_sequence_index}" "0" "non-tty path should not read keyboard input"

printf "PASS: app shell runtime loop tests\n"
