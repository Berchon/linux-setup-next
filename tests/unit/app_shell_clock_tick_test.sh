#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/app/app_shell.sh
source "${TEST_ROOT}/src/app/app_shell.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

app_shell_last_clock_second=-1
if app_shell_clock_tick_due 100; then
  printf "FAIL: first tick should not force render\n" >&2
  exit 1
fi
assert_eq "${app_shell_last_clock_second}" "100" "first tick should store second"
if app_shell_clock_tick_due 100; then
  printf "FAIL: same second should not force render\n" >&2
  exit 1
fi
if ! app_shell_clock_tick_due 101; then
  printf "FAIL: next second should force render\n" >&2
  exit 1
fi
assert_eq "${app_shell_last_clock_second}" "101" "tick should update stored second"

printf "PASS: app shell clock tick tests\n"
