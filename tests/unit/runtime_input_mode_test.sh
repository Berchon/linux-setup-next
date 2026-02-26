#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/core/runtime.sh
source "${TEST_ROOT}/src/core/runtime.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

stty_log=""
runtime_is_tty() {
  return 0
}

runtime_stty_command() {
  if [[ "$1" == "-g" ]]; then
    printf "saved-state"
    return 0
  fi

  stty_log+="$*|"
}

runtime_input_mode_enabled=0
runtime_saved_stty=""
runtime_enable_input_mode
runtime_enable_input_mode

assert_eq "${stty_log}" "-echo -icanon min 0 time 1|" "input mode should be configured once"
assert_eq "${runtime_input_mode_enabled}" "1" "input mode flag should be enabled"
assert_eq "${runtime_saved_stty}" "saved-state" "stty snapshot should be persisted"

runtime_disable_input_mode
runtime_disable_input_mode

assert_eq "${stty_log}" "-echo -icanon min 0 time 1|saved-state|" "stty restore should run once"
assert_eq "${runtime_input_mode_enabled}" "0" "input mode flag should be disabled"
assert_eq "${runtime_saved_stty}" "" "stty snapshot should be cleared"

stty_log=""
runtime_is_tty() {
  return 1
}

runtime_enable_input_mode
assert_eq "${stty_log}" "" "input mode should not configure stty when stdin is not a tty"
assert_eq "${runtime_input_mode_enabled}" "0" "input mode flag should remain disabled when not tty"

printf "PASS: runtime input mode tests\n"
