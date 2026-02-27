#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
# shellcheck source=src/components/rectangle.sh
source "${TEST_ROOT}/src/components/rectangle.sh"
# shellcheck source=src/components/shadow.sh
source "${TEST_ROOT}/src/components/shadow.sh"
# shellcheck source=src/components/panel.sh
source "${TEST_ROOT}/src/components/panel.sh"
# shellcheck source=src/components/modal.sh
source "${TEST_ROOT}/src/components/modal.sh"
# shellcheck source=src/components/toast.sh
source "${TEST_ROOT}/src/components/toast.sh"
# shellcheck source=src/components/overlay_stack.sh
source "${TEST_ROOT}/src/components/overlay_stack.sh"
# shellcheck source=src/state/modal_state.sh
source "${TEST_ROOT}/src/state/modal_state.sh"
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"

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
cell_buffer_init 30 10
dirty_regions_init 30 10
toast_reset_render_cache
toast_state_reset
modal_state_reset

toast_state_set_max_visible 1
toast_state_enqueue "warn" "toast-msg" "1000"
modal_state_open_confirm "Confirm" "Proceed?" "Yes" "No" "confirm"

assert_eq "$(overlay_resolve_modal_toast_order 1 1)" $'toast\nmodal' "render order should keep modal above toast"
overlay_render_modal_toast_from_state back 30 10 20 8

# Position that belongs to toast top border and modal confirm buttons row.
assert_eq "$(cell_buffer_get_cell back 8 6)" ">|7|0|1" "modal should overwrite overlapping toast content at higher z-order"

printf "PASS: overlay modal/toast z-order tests\n"
