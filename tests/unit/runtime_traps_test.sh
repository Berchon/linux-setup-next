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

assert_contains() {
  local content="$1"
  local snippet="$2"
  local message="$3"

  if [[ "${content}" != *"${snippet}"* ]]; then
    printf "FAIL: %s\nmissing: %q\ncontent: %q\n" "${message}" "${snippet}" "${content}" >&2
    exit 1
  fi
}

shutdown_calls=0
runtime_shutdown() {
  shutdown_calls=$((shutdown_calls + 1))
}

runtime_cleanup_ran=0
runtime_cleanup
runtime_cleanup
assert_eq "${shutdown_calls}" "1" "cleanup should be idempotent"

runtime_resize_pending=0
runtime_handle_winch
assert_eq "${runtime_resize_pending}" "1" "WINCH handler should mark pending resize"

runtime_install_signal_traps
assert_contains "$(trap -p EXIT)" "runtime_handle_exit" "EXIT trap should be installed"
assert_contains "$(trap -p INT)" "runtime_handle_interrupt" "INT trap should be installed"
assert_contains "$(trap -p TERM)" "runtime_handle_terminate" "TERM trap should be installed"
assert_contains "$(trap -p WINCH)" "runtime_handle_winch" "WINCH trap should be installed"

interrupt_rc=0
if (runtime_cleanup_ran=0; runtime_handle_interrupt) >/dev/null 2>&1; then
  interrupt_rc=0
else
  interrupt_rc=$?
fi
assert_eq "${interrupt_rc}" "130" "INT handler should exit with 130"

terminate_rc=0
if (runtime_cleanup_ran=0; runtime_handle_terminate) >/dev/null 2>&1; then
  terminate_rc=0
else
  terminate_rc=$?
fi
assert_eq "${terminate_rc}" "143" "TERM handler should exit with 143"

printf "PASS: runtime trap tests\n"
