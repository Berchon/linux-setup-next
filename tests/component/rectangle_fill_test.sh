#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/components/rectangle.sh
source "${TEST_ROOT}/src/components/rectangle.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

cell_buffer_init 6 4
rectangle_render_fill back 1 1 3 2 "." 2 4 1

assert_eq "$(cell_buffer_get_cell back 1 1)" ".|2|4|1" "fill should write origin cell"
assert_eq "$(cell_buffer_get_cell back 3 2)" ".|2|4|1" "fill should write full width and height"
assert_eq "$(cell_buffer_get_cell back 0 0)" " |7|0|0" "fill should not affect outside area"

rectangle_render_fill back -2 0 3 2 "x" 1 3 0
assert_eq "$(cell_buffer_get_cell back 0 0)" "x|1|3|0" "fill should clip negative x into viewport"
assert_eq "$(cell_buffer_get_cell back 1 0)" " |7|0|0" "clipped fill should not write beyond clipped range"

rectangle_render_fill back 0 0 0 2 "!" 5 6 1
assert_eq "$(cell_buffer_get_cell back 5 3)" " |7|0|0" "zero-width fill should be no-op"

cell_buffer_init 8 5
rectangle_render back 1 1 6 3 "." 3 4 0 none
assert_eq "$(cell_buffer_get_cell back 1 1)" ".|3|4|0" "none border style should keep filled top-left cell"
assert_eq "$(cell_buffer_get_cell back 6 3)" ".|3|4|0" "none border style should not draw border characters"

cell_buffer_init 8 5
rectangle_render back 1 1 6 3 "." 2 5 1 single
assert_eq "$(cell_buffer_get_cell back 1 1)" "+|2|5|1" "single border should draw top-left corner"
assert_eq "$(cell_buffer_get_cell back 3 1)" "-|2|5|1" "single border should draw horizontal edge"
assert_eq "$(cell_buffer_get_cell back 1 2)" "||2|5|1" "single border should draw vertical edge"
assert_eq "$(cell_buffer_get_cell back 6 3)" "+|2|5|1" "single border should draw bottom-right corner"
assert_eq "$(cell_buffer_get_cell back 3 2)" ".|2|5|1" "single border should preserve interior fill"

cell_buffer_init 8 5
rectangle_render back 1 1 6 3 "." 2 5 1 double
assert_eq "$(cell_buffer_get_cell back 3 1)" "=|2|5|1" "double border should use ASCII-safe fallback for horizontal edge"
assert_eq "$(cell_buffer_get_cell back 1 2)" "||2|5|1" "double border should keep ASCII-safe vertical edge"

cell_buffer_init 5 4
rectangle_render back -1 0 4 3 "." 1 2 0 single
assert_eq "$(cell_buffer_get_cell back 0 0)" "-|1|2|0" "border rendering should clip and still draw visible top edge"
assert_eq "$(cell_buffer_get_cell back 0 1)" ".|1|2|0" "clipped left edge should not write outside viewport"
assert_eq "$(cell_buffer_get_cell back 2 2)" "+|1|2|0" "clipped border should still draw visible corner"

printf "PASS: rectangle fill/border tests\n"
