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
assert_eq "$(cell_buffer_get_cell back 3 2)" ".|0|8|0" "shadow should apply positive dx/dy offsets"
assert_eq "$(cell_buffer_get_cell back 5 3)" ".|0|8|0" "shadow should preserve source size after offset"
assert_eq "$(cell_buffer_get_cell back 1 1)" " |7|0|0" "shadow should not paint original component area"

cell_buffer_init 7 4
shadow_render back 2 1 2 2 0 0 ":" 4 1 1
assert_eq "$(cell_buffer_get_cell back 2 1)" ":|4|1|1" "shadow should support zero offsets"
assert_eq "$(cell_buffer_get_cell back 3 2)" ":|4|1|1" "zero offsets should keep width/height"

cell_buffer_init 8 5
shadow_render back 3 2 2 2 -2 -1 "*" 5 6 0
assert_eq "$(cell_buffer_get_cell back 1 1)" "*|5|6|0" "shadow should support negative dx"
assert_eq "$(cell_buffer_get_cell back 2 2)" "*|5|6|0" "shadow should support negative dy"

printf "PASS: shadow offset tests\n"
