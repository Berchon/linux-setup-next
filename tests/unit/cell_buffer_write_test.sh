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

cell_buffer_init 6 2

cell_buffer_write_cell back 1 0 "A" 2 3 1
assert_eq "$(cell_buffer_get_cell back 1 0)" "A|2|3|1" "write_cell should store char and style"

if cell_buffer_write_cell back 9 0 "Z" 1 1 0 >/dev/null 2>&1; then
  printf "FAIL: write_cell out-of-bounds should fail\n" >&2
  exit 1
fi

cell_buffer_write_cell back 2 0 "AB" 4 5 0
assert_eq "$(cell_buffer_get_cell back 2 0)" "A|4|5|0" "write_cell should store a single character per cell"

cell_buffer_write_text back 0 1 "HELLO" 6 1 0
assert_eq "$(cell_buffer_get_cell back 0 1)" "H|6|1|0" "write_text should write first character"
assert_eq "$(cell_buffer_get_cell back 4 1)" "O|6|1|0" "write_text should write sequential characters"

cell_buffer_write_text back -1 0 "AB" 3 4 1
assert_eq "$(cell_buffer_get_cell back 0 0)" "B|3|4|1" "write_text should clip left overflow"

cell_buffer_write_text back 5 1 "XYZ" 1 2 0
assert_eq "$(cell_buffer_get_cell back 5 1)" "X|1|2|0" "write_text should clip right overflow"

printf "PASS: cell buffer write tests\n"
