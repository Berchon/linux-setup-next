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

cell_buffer_init 8 2
dirty_regions_init 8 2

cell_buffer_write_cell back 0 0 "A" 2 3 1
cell_buffer_write_cell back 1 0 "B" 2 3 1
cell_buffer_write_cell back 2 0 "C" 6 1 0
cell_buffer_write_cell back 4 0 "D" 2 3 1
cell_buffer_write_cell back 5 0 "E" 2 3 1
cell_buffer_write_cell back 7 1 "Z" 4 2 0

dirty_regions_add 0 0 6 1
diff_renderer_collect_runs

assert_eq "$(diff_renderer_run_count)" "3" "runs should be grouped only when contiguous and with identical style"
assert_eq "$(diff_renderer_get_run 0)" "0|0|AB|2|3|1" "first run should merge same-style contiguous cells"
assert_eq "$(diff_renderer_get_run 1)" "2|0|C|6|1|0" "style change should create a new run"
assert_eq "$(diff_renderer_get_run 2)" "4|0|DE|2|3|1" "unchanged gap should split runs even with same style"

dirty_regions_reset
dirty_regions_add 7 1 1 1
diff_renderer_collect_runs
assert_eq "$(diff_renderer_run_count)" "1" "run collection should follow active dirty region set"
assert_eq "$(diff_renderer_get_run 0)" "7|1|Z|4|2|0" "region-specific run should keep coordinates and style"

printf "PASS: diff renderer style run tests\n"
