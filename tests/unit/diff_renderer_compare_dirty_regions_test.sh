#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
# shellcheck source=src/render/diff_renderer.sh
source "${TEST_ROOT}/src/render/diff_renderer.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

cell_buffer_init 6 3
dirty_regions_init 6 3

cell_buffer_write_cell back 1 0 "A" 2 3 1
cell_buffer_write_cell back 5 2 "Z" 4 5 0

dirty_regions_add 0 0 3 1
diff_renderer_collect_changed_cells
assert_eq "$(diff_renderer_changed_count)" "1" "diff should compare only cells inside dirty regions"
assert_eq "$(diff_renderer_get_changed_cell 0)" "1|0" "changed cell inside dirty region should be collected"

dirty_regions_reset
dirty_regions_add 4 2 2 1
diff_renderer_collect_changed_cells
assert_eq "$(diff_renderer_changed_count)" "1" "second pass should only include newly tracked dirty area"
assert_eq "$(diff_renderer_get_changed_cell 0)" "5|2" "change outside previous dirty region should be collected when region is marked"

dirty_regions_reset
diff_renderer_collect_changed_cells
assert_eq "$(diff_renderer_changed_count)" "0" "no dirty regions should produce empty diff set"

printf "PASS: diff renderer dirty-region compare tests\n"
