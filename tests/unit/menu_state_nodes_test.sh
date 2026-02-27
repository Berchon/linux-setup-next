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
assert_eq "$(menu_state_node_count)" "0" "node count should start empty"

menu_state_add_node "root" "" "Main" "Root menu" ""
menu_state_add_node "network" "root" "Network" "Network actions" "open_network"
menu_state_add_node "display" "root" "Display" "Display actions" "open_display"

assert_eq "$(menu_state_node_count)" "3" "node count should include all inserted nodes"
assert_eq "$(menu_state_get_node "network")" "network|root|Network|Network actions|open_network" "get node should return all node fields"
assert_eq "$(menu_state_get_parent "display")" "root" "parent should be stored"
assert_eq "$(menu_state_get_label "display")" "Display" "label should be retrievable"
assert_eq "$(menu_state_get_desc "display")" "Display actions" "desc should be retrievable"
assert_eq "$(menu_state_get_action "display")" "open_display" "action should be retrievable"
assert_eq "$(menu_state_get_children "")" "root" "root list should include root-level nodes"
assert_eq "$(menu_state_get_children "root")" "network display" "children should preserve insertion order"

if menu_state_add_node "network" "root" "Duplicate" "" "" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: duplicate node id should be rejected\n" >&2
  exit 1
fi

if menu_state_add_node "missing-parent" "unknown" "Broken" "" "" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: unknown parent should be rejected\n" >&2
  exit 1
fi

if menu_state_add_node "" "" "No id" "" "" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: empty id should be rejected\n" >&2
  exit 1
fi

if menu_state_add_node "empty-label" "" "" "" "" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: empty label should be rejected\n" >&2
  exit 1
fi

if menu_state_get_node "unknown" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: unknown node lookup should fail\n" >&2
  exit 1
fi

printf "PASS: menu state node model tests\n"
