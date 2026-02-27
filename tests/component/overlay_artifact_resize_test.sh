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
modal_reset_render_cache
toast_state_reset
modal_state_reset

toast_state_set_max_visible 1
toast_state_enqueue "warn" "toast-A" "1000"
modal_state_open_text "Info" "modal-A"
overlay_render_modal_toast_from_state back 30 10 20 8

assert_eq "$(cell_buffer_get_cell back 5 1)" "+|7|0|0" "modal border should be rendered at initial position"

modal_state_close
toast_state_reset
overlay_render_modal_toast_from_state back 30 10 20 8
assert_eq "$(cell_buffer_get_cell back 5 1)" " |7|0|0" "overlay cleanup should clear cached modal region after closing"

toast_state_enqueue "warn" "toast-B" "1000"
overlay_render_modal_toast_from_state back 30 10 20 8
old_toast_x="${toast_render_stack_cache_x[0]}"
old_toast_y="${toast_render_stack_cache_y[0]}"
old_toast_width="${toast_render_stack_cache_width[0]}"
assert_eq "$(cell_buffer_get_cell back "${old_toast_x}" "${old_toast_y}")" "+|3|0|0" "toast should render at first layout position"

overlay_render_modal_toast_from_state back 24 8 18 6
new_toast_x="${toast_render_stack_cache_x[0]}"
new_toast_width="${toast_render_stack_cache_width[0]}"
stale_x="${old_toast_x}"
if ((old_toast_x >= new_toast_x && old_toast_x < new_toast_x + new_toast_width)); then
  stale_x=$((old_toast_x + old_toast_width - 1))
fi
assert_eq "$(cell_buffer_get_cell back "${stale_x}" "${old_toast_y}")" " |7|0|0" "resize recomposition should clear stale toast pixels from old position"

printf "PASS: overlay artifact cleanup and resize tests\n"
