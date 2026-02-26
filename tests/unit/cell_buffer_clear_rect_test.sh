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

cell_buffer_init 5 4
cell_buffer_write_text back 0 0 "ABCDE" 1 2 1
cell_buffer_write_text back 0 1 "ABCDE" 1 2 1
cell_buffer_write_text back 0 2 "ABCDE" 1 2 1
cell_buffer_write_text back 0 3 "ABCDE" 1 2 1

cell_buffer_clear_rect back 1 1 3 2
assert_eq "$(cell_buffer_get_cell back 0 1)" "A|1|2|1" "clear_rect should keep cells outside rect"
assert_eq "$(cell_buffer_get_cell back 1 1)" " |7|0|0" "clear_rect should reset cells inside rect"
assert_eq "$(cell_buffer_get_cell back 3 2)" " |7|0|0" "clear_rect should reset full clipped rect area"
assert_eq "$(cell_buffer_get_cell back 4 3)" "E|1|2|1" "clear_rect should not affect unrelated cells"

cell_buffer_clear_rect back -2 -1 3 3
assert_eq "$(cell_buffer_get_cell back 0 0)" " |7|0|0" "clear_rect should clip negative origin into viewport"
assert_eq "$(cell_buffer_get_cell back 1 0)" "B|1|2|1" "clear_rect clipping should not overflow extra columns"

cell_buffer_clear_rect back 0 0 0 0
assert_eq "$(cell_buffer_get_cell back 4 3)" "E|1|2|1" "zero-size clear_rect should be a no-op"

printf "PASS: cell buffer clear rect tests\n"
