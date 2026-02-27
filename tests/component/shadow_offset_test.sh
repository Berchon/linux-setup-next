#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/components/shadow.sh
source "${TEST_ROOT}/src/components/shadow.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

cell_buffer_init 10 6
shadow_render back 1 1 3 2 2 1 "." 0 8 0
assert_eq "$(cell_buffer_get_cell back 3 2)" " |7|0|0" "shadow should not draw inside source-shadow overlap area"
assert_eq "$(cell_buffer_get_cell back 5 2)" ".|0|8|0" "shadow should draw visible right strip when dx is positive"
assert_eq "$(cell_buffer_get_cell back 3 3)" ".|0|8|0" "shadow should draw visible bottom strip when dy is positive"
assert_eq "$(cell_buffer_get_cell back 1 1)" " |7|0|0" "shadow should not paint original component origin"

cell_buffer_init 7 4
shadow_render back 2 1 2 2 0 0 ":" 4 1 1
assert_eq "$(cell_buffer_get_cell back 2 1)" " |7|0|0" "shadow should be empty when dx and dy are both zero"
assert_eq "$(cell_buffer_get_cell back 3 2)" " |7|0|0" "zero offset should produce no visible shadow"

cell_buffer_init 8 5
shadow_render back 3 2 2 2 -2 -1 "*" 5 6 0
assert_eq "$(cell_buffer_get_cell back 1 1)" "*|5|6|0" "shadow should support negative dx"
assert_eq "$(cell_buffer_get_cell back 2 2)" "*|5|6|0" "shadow should support negative dy"

cell_buffer_init 5 4
shadow_render back 2 1 3 2 1 1 "#" 1 2 1
assert_eq "$(cell_buffer_get_cell back 3 3)" "#|1|2|1" "shadow should clip bottom strip into viewport"
assert_eq "$(cell_buffer_get_cell back 4 3)" "#|1|2|1" "shadow clipping should keep visible cells"
assert_eq "$(cell_buffer_get_cell back 3 2)" " |7|0|0" "shadow should not draw clipped overlap area"

cell_buffer_init 5 4
shadow_render back 1 1 3 2 -2 -2 "+" 3 6 0
assert_eq "$(cell_buffer_get_cell back 0 0)" "+|3|6|0" "negative-origin clipping should keep visible portion"
assert_eq "$(cell_buffer_get_cell back 1 0)" "+|3|6|0" "negative-origin clipping should preserve width inside viewport"
assert_eq "$(cell_buffer_get_cell back 0 1)" " |7|0|0" "negative-origin clipping should preserve non-visible rows"

cell_buffer_init 10 6
shadow_render back 3 2 3 3 2 -1 "@" 2 4 1
assert_eq "$(cell_buffer_get_cell back 5 1)" "@|2|4|1" "mixed offset should draw top strip when dy is negative"
assert_eq "$(cell_buffer_get_cell back 7 3)" "@|2|4|1" "mixed offset should draw right strip when dx is positive"
assert_eq "$(cell_buffer_get_cell back 5 2)" " |7|0|0" "mixed offset should keep overlap area untouched"

cell_buffer_init 10 6
shadow_render back 3 1 4 3 -2 1 "=" 6 1 0
assert_eq "$(cell_buffer_get_cell back 1 2)" "=|6|1|0" "mixed offset should draw left strip when dx is negative"
assert_eq "$(cell_buffer_get_cell back 4 4)" "=|6|1|0" "mixed offset should draw bottom strip when dy is positive"
assert_eq "$(cell_buffer_get_cell back 3 2)" " |7|0|0" "mixed offset should not draw overlap cells"

cell_buffer_init 6 3
shadow_render back 1 1 2 1 1 0 "$" 3 2 1 0
assert_eq "$(cell_buffer_get_cell back 3 1)" " |7|0|0" "shadow should skip render when disabled by numeric flag"

cell_buffer_init 6 3
shadow_render back 1 1 2 1 1 0 "$" 3 2 1 false
assert_eq "$(cell_buffer_get_cell back 3 1)" " |7|0|0" "shadow should skip render when disabled by textual flag"

cell_buffer_init 6 3
shadow_render back 1 1 2 1 1 0 "$" 3 2 1 on
assert_eq "$(cell_buffer_get_cell back 3 1)" "$|3|2|1" "shadow should render when explicitly enabled"

printf "PASS: shadow offset tests\n"
