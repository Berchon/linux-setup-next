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

assert_eq "$(menu_map_input_key $'\033[A')" "up" "up arrow should map to up"
assert_eq "$(menu_map_input_key $'\033[B')" "down" "down arrow should map to down"
assert_eq "$(menu_map_input_key $'\033[C')" "right" "right arrow should map to right"
assert_eq "$(menu_map_input_key $'\033[D')" "left" "left arrow should map to left"
assert_eq "$(menu_map_input_key $'\n')" "enter" "newline should map to enter"
assert_eq "$(menu_map_input_key $'\r')" "enter" "carriage return should map to enter"
assert_eq "$(menu_map_input_key $'\033')" "back" "escape should map to back"
assert_eq "$(menu_map_input_key q)" "quit" "q should map to quit"
assert_eq "$(menu_map_input_key Q)" "quit" "Q should map to quit"
assert_eq "$(menu_map_input_key z)" "noop" "unknown key should map to noop"

printf "PASS: menu input mapping tests\n"
