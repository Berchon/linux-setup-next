#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
# shellcheck source=src/components/background.sh
source "${TEST_ROOT}/src/components/background.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

cell_buffer_init 8 4
dirty_regions_init 8 4

background_reset_registry
background_register_pattern "checker" ". " " #"
background_patterns_loaded=1

background_render_region back 1 1 4 2 checker 7 0 0

assert_eq "$(cell_buffer_get_cell back 1 1)" ".|7|0|0" "first tile cell should use first row/col"
assert_eq "$(cell_buffer_get_cell back 2 1)" " |7|0|0" "first row second cell should preserve spaces"
assert_eq "$(cell_buffer_get_cell back 1 2)" " |7|0|0" "second row first cell should preserve spaces"
assert_eq "$(cell_buffer_get_cell back 2 2)" "#|7|0|0" "second row second cell should use matrix char"

background_track_dirty_region 1 1 4 2
assert_eq "$(dirty_regions_count)" "1" "background dirty tracking should add one region"
assert_eq "$(dirty_regions_get 0)" "1|1|4|2" "background dirty region should keep coordinates"

printf "PASS: background render component tests\n"
