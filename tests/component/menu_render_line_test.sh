#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
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

cell_buffer_init 12 3

menu_render_line back 1 0 8 "Network" 0 2 4 0 0 0 1
assert_eq "$(cell_buffer_get_cell back 1 0)" " |2|4|0" "unselected line should start with blank prefix"
assert_eq "$(cell_buffer_get_cell back 3 0)" "N|2|4|0" "unselected line should render text with normal style"
assert_eq "$(cell_buffer_get_cell back 8 0)" "r|2|4|0" "unselected line should include visible label chars"

menu_render_line back 1 1 8 "Display" 1 2 4 7 1 0 1
assert_eq "$(cell_buffer_get_cell back 1 1)" ">|7|1|1" "selected line should render selected prefix"
assert_eq "$(cell_buffer_get_cell back 3 1)" "D|7|1|1" "selected line should render label with selected style"
assert_eq "$(cell_buffer_get_cell back 8 1)" "a|7|1|1" "selected line should clip label to available width"

menu_render_line back 0 2 4 "LongLabel" 0 3 5 0 0 0 1
assert_eq "$(cell_buffer_get_cell back 0 2)" " |3|5|0" "short lines should preserve prefix"
assert_eq "$(cell_buffer_get_cell back 2 2)" "L|3|5|0" "short lines should clip label payload"
assert_eq "$(cell_buffer_get_cell back 3 2)" "o|3|5|0" "short lines should stop at width boundary"

printf "PASS: menu render line tests\n"
