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

assert_eq "$(menu_should_exit_requested quit "" "" "")" "1" "quit key action should request exit"
assert_eq "$(menu_should_exit_requested enter exit "" "")" "1" "exit node id should request exit"
assert_eq "$(menu_should_exit_requested enter "" app_exit "")" "1" "exit node action should request exit"
assert_eq "$(menu_should_exit_requested enter "" "" INT)" "1" "INT signal should request exit"
assert_eq "$(menu_should_exit_requested enter "" "" TERM)" "1" "TERM signal should request exit"
assert_eq "$(menu_should_exit_requested down settings open_settings "")" "0" "regular navigation should not request exit"

printf "PASS: menu exit flow tests\n"
