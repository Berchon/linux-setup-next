#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/state/menu_state.sh
source "${TEST_ROOT}/src/state/menu_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

menu_state_reset
menu_state_add_node "root" "" "Main" "" ""
menu_state_add_node "network" "root" "Network" "" ""
menu_state_add_node "display" "root" "Display" "" ""
menu_state_add_node "wifi" "network" "Wi-Fi" "" "open_wifi"
menu_state_add_node "ethernet" "network" "Ethernet" "" "open_ethernet"

menu_state_navigation_reset "root"
assert_eq "$(menu_state_navigation_depth)" "1" "navigation should start with root depth"
assert_eq "$(menu_state_navigation_current)" "root" "current node should be root after reset"
assert_eq "$(menu_state_navigation_path)" "root" "path should contain only root after reset"

menu_state_navigation_enter "network"
assert_eq "$(menu_state_navigation_depth)" "2" "enter submenu should increase depth"
assert_eq "$(menu_state_navigation_current)" "network" "current node should become entered submenu"
assert_eq "$(menu_state_navigation_path)" "root network" "path should preserve entered submenu order"

if menu_state_navigation_enter "display" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: enter should reject node outside current parent scope\n" >&2
  exit 1
fi

if menu_state_navigation_enter "wifi" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: enter should reject leaf nodes without submenu children\n" >&2
  exit 1
fi

menu_state_navigation_back
assert_eq "$(menu_state_navigation_current)" "root" "back should return to previous menu"
assert_eq "$(menu_state_navigation_depth)" "1" "back should reduce depth"

if menu_state_navigation_back >/dev/null 2>&1; then
  printf "ASSERTION FAILED: back at root should fail\n" >&2
  exit 1
fi

if menu_state_navigation_reset "unknown" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: reset should reject unknown root\n" >&2
  exit 1
fi

menu_state_reset
if menu_state_navigation_current >/dev/null 2>&1; then
  printf "ASSERTION FAILED: current should fail when stack is empty\n" >&2
  exit 1
fi

printf "PASS: menu state navigation stack tests\n"
