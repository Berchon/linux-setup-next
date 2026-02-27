#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/components/rectangle.sh
source "${TEST_ROOT}/src/components/rectangle.sh"
# shellcheck source=src/components/shadow.sh
source "${TEST_ROOT}/src/components/shadow.sh"
# shellcheck source=src/components/panel.sh
source "${TEST_ROOT}/src/components/panel.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

rectangle_set_border_charset ascii

cell_buffer_init 12 8
panel_render back 2 2 4 3 "." 2 4 1 single "P" 1 1 1 "~" 6 0 0
assert_eq "$(cell_buffer_get_cell back 2 2)" "+|2|4|1" "panel should render rectangle body"
assert_eq "$(cell_buffer_get_cell back 3 2)" "P|2|4|1" "panel should render rectangle title"
assert_eq "$(cell_buffer_get_cell back 6 3)" "~|6|0|0" "panel should render right-side shadow"
assert_eq "$(cell_buffer_get_cell back 3 5)" "~|6|0|0" "panel should render bottom shadow"

cell_buffer_init 12 8
panel_render back 2 2 4 3 "." 2 4 1 single "P" 0 1 1 "~" 6 0 0
assert_eq "$(cell_buffer_get_cell back 6 3)" " |7|0|0" "panel should skip shadow when disabled"
assert_eq "$(cell_buffer_get_cell back 3 5)" " |7|0|0" "panel should not draw bottom shadow when disabled"

printf "PASS: panel composition tests\n"
