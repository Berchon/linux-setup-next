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
# shellcheck source=src/components/modal.sh
source "${TEST_ROOT}/src/components/modal.sh"

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
cell_buffer_init 20 10
modal_render_text back 20 10 10 5 "Info" "Hello modal"

assert_eq "$(cell_buffer_get_cell back 5 2)" "+|7|0|0" "modal should draw border top-left"
assert_eq "$(cell_buffer_get_cell back 6 2)" "I|7|0|0" "modal should draw title"
assert_eq "$(cell_buffer_get_cell back 7 4)" "H|7|0|0" "modal should draw message in content area"
assert_eq "$(modal_should_block_background_input 1)" "1" "active modal should block input"
assert_eq "$(modal_should_block_background_input 0)" "0" "inactive modal should not block input"

printf "PASS: modal text render tests\n"
