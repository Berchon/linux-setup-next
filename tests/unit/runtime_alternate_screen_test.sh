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

output=""
runtime_emit_ansi() {
  output+="$1"
}

runtime_alt_screen_enabled=0
runtime_enter_alternate_screen
runtime_enter_alternate_screen
runtime_leave_alternate_screen
runtime_leave_alternate_screen

assert_eq "${output}" '\033[?1049h\033[?1049l' "alternate screen should emit on/off once"
assert_eq "${runtime_alt_screen_enabled}" "0" "alternate screen flag should return to disabled"

output=""
runtime_init
runtime_shutdown
assert_eq "${output}" '\033[?1049h\033[?1049l' "init/shutdown should emit alternate screen on/off"

printf "PASS: runtime alternate screen tests\n"
