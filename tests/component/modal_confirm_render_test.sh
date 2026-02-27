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
cell_buffer_init 30 12
modal_render_confirm back 30 12 16 7 "Confirm" "Apply change?" "Yes" "No" "confirm"
assert_eq "$(cell_buffer_get_cell back 9 4)" "A|7|0|0" "confirm modal should render message"
assert_eq "$(cell_buffer_get_cell back 9 6)" "[|7|0|1" "confirm modal should render button row"
assert_eq "$(cell_buffer_get_cell back 10 6)" ">|7|0|1" "confirm focus should highlight confirm button"

cell_buffer_init 30 12
modal_render_confirm back 30 12 16 7 "Confirm" "Apply change?" "Yes" "No" "cancel"
assert_eq "$(cell_buffer_get_cell back 18 6)" ">|7|0|1" "cancel focus should highlight cancel button"

if modal_render_confirm back 30 12 16 7 "Confirm" "Apply change?" "Yes" "No" "invalid" >/dev/null 2>&1; then
  printf "FAIL: render confirm should reject invalid focus\n" >&2
  exit 1
fi

printf "PASS: modal confirmation render tests\n"
