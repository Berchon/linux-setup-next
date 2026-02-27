#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
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

assert_eq "$(menu_selection_apply_delta 2 1 5)" "3" "delta should move selection down"
assert_eq "$(menu_selection_apply_delta 2 -1 5)" "1" "delta should move selection up"
assert_eq "$(menu_selection_apply_delta 0 -1 5)" "0" "delta should clamp at lower bound"
assert_eq "$(menu_selection_apply_delta 4 5 5)" "4" "delta should clamp at upper bound"
assert_eq "$(menu_selection_apply_delta 10 -1 5)" "4" "out-of-range current index should clamp to upper bound after delta"
assert_eq "$(menu_selection_apply_delta 0 1 0)" "0" "empty menu should keep zero selection"

dirty_regions_init 20 8
menu_mark_selection_delta_dirty 2 1 10 4 1 2 0
assert_eq "$(dirty_regions_count)" "2" "delta change should dirty previous and new selected rows"
assert_eq "$(dirty_regions_get 0)" "2|2|10|1" "old selected row should be dirtied"
assert_eq "$(dirty_regions_get 1)" "2|3|10|1" "new selected row should be dirtied"

dirty_regions_reset
menu_mark_selection_delta_dirty 2 1 10 4 0 0 0
assert_eq "$(dirty_regions_count)" "0" "unchanged selection should not dirty rows"

dirty_regions_reset
menu_mark_selection_delta_dirty 2 1 10 4 7 2 5
assert_eq "$(dirty_regions_count)" "1" "only visible row should be dirtied when old selection is offscreen"
assert_eq "$(dirty_regions_get 0)" "2|3|10|1" "visible new row should map to viewport coordinates"

printf "PASS: menu selection delta tests\n"
