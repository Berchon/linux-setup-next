#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_eq "$(menu_should_coalesce_repeat down down 100 80 40)" "1" "same nav action inside debounce window should coalesce"
assert_eq "$(menu_should_coalesce_repeat down down 140 80 40)" "0" "same nav action outside debounce window should not coalesce"
assert_eq "$(menu_should_coalesce_repeat down up 100 80 40)" "0" "different actions should not coalesce"
assert_eq "$(menu_should_coalesce_repeat quit quit 100 80 40)" "0" "quit should never be treated as navigation repeat"
assert_eq "$(menu_should_coalesce_repeat left left 50 80 40)" "1" "clock skew should clamp elapsed and still coalesce"

printf "PASS: menu input repeat tests\n"
