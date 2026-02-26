#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

if cell_buffer_init 0 4 >/dev/null 2>&1; then
  printf "FAIL: zero width should fail\n" >&2
  exit 1
fi

cell_buffer_init 4 3
assert_eq "${cell_buffer_width}" "4" "width should be initialized"
assert_eq "${cell_buffer_height}" "3" "height should be initialized"
assert_eq "$(cell_buffer_cell_count)" "12" "cell count should match width*height"
assert_eq "${#cell_front_chars[@]}" "12" "front buffer should allocate all cells"
assert_eq "${#cell_back_chars[@]}" "12" "back buffer should allocate all cells"
assert_eq "$(cell_buffer_get_cell front 0 0)" " |7|0|0" "front buffer should start with default cell"
assert_eq "$(cell_buffer_get_cell back 3 2)" " |7|0|0" "back buffer should start with default cell"

if cell_buffer_index 4 0 >/dev/null 2>&1; then
  printf "FAIL: out-of-bounds index should fail\n" >&2
  exit 1
fi

cell_back_chars[0]="X"
cell_back_fgs[0]=1
cell_back_bgs[0]=2
cell_back_bolds[0]=1
cell_buffer_swap
assert_eq "$(cell_buffer_get_cell front 0 0)" "X|1|2|1" "swap should move back content to front"
assert_eq "$(cell_buffer_get_cell back 0 0)" " |7|0|0" "swap should preserve previous front in back"

printf "PASS: cell buffer init tests\n"
