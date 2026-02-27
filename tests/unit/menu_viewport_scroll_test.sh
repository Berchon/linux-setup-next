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

assert_eq "$(menu_compute_viewport_start 0 0 4 10)" "0" "selected on first row should keep viewport at top"
assert_eq "$(menu_compute_viewport_start 3 0 4 10)" "0" "selected within viewport should keep current start"
assert_eq "$(menu_compute_viewport_start 4 0 4 10)" "1" "selected past viewport bottom should advance viewport"
assert_eq "$(menu_compute_viewport_start 8 2 4 10)" "5" "viewport should keep selected row visible near end"
assert_eq "$(menu_compute_viewport_start 1 5 4 10)" "1" "selected above viewport should move viewport up"
assert_eq "$(menu_compute_viewport_start 3 0 8 4)" "0" "viewport bigger than item count should stay at zero"
assert_eq "$(menu_compute_viewport_start 0 2 0 10)" "0" "zero-height viewport should fallback to zero"

dirty_regions_init 30 12
menu_mark_viewport_scroll_dirty 2 3 10 4 0 1
assert_eq "$(dirty_regions_count)" "1" "scroll change should dirty only menu viewport"
assert_eq "$(dirty_regions_get 0)" "2|3|10|4" "dirty region should match viewport bounds"

dirty_regions_reset
menu_mark_viewport_scroll_dirty 2 3 10 4 1 1
assert_eq "$(dirty_regions_count)" "0" "unchanged viewport should not dirty region"

printf "PASS: menu viewport scroll tests\n"
