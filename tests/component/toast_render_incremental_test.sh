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
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"
# shellcheck source=src/components/toast.sh
source "${TEST_ROOT}/src/components/toast.sh"

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
cell_buffer_init 24 10
dirty_regions_init 24 10
toast_reset_render_cache
toast_state_reset

toast_state_set_max_visible 2
toast_state_enqueue "info" "A-one" "1000"
toast_render_stack_from_state back 24 10
assert_eq "$(dirty_regions_count)" "1" "first render should dirty only first visible rect"
assert_eq "${toast_render_stack_cache_count}" "1" "stack cache should store one visible toast rect"

first_x="${toast_render_stack_cache_x[0]}"
first_y="${toast_render_stack_cache_y[0]}"
assert_eq "$(cell_buffer_get_cell back "$((first_x + 2))" "$((first_y + 1))")" "A|7|0|0" "first toast should render message content"

toast_state_enqueue "success" "B-two" "1000"
toast_render_stack_from_state back 24 10
assert_eq "${toast_render_stack_cache_count}" "2" "second toast should render two stacked items"
assert_eq "$(toast_state_get_visible 0)" "success|B-two|1000" "new toast should enter at stack top"

top_y="${toast_render_stack_cache_y[0]}"
down_y="${toast_render_stack_cache_y[1]}"
assert_eq "$((down_y > top_y))" "1" "older toast should be shifted downward"
assert_eq "$(cell_buffer_get_cell back "$((toast_render_stack_cache_x[0] + 2))" "$((top_y + 1))")" "B|2|0|1" "top stacked toast should render newest message"

toast_state_enqueue "warn" "C-three" "1000"
assert_eq "$(toast_state_queue_size)" "1" "third toast should stay queued after hitting max_visible"

toast_state_dismiss_active
toast_render_stack_from_state back 24 10
assert_eq "$(toast_state_get_visible 0)" "warn|C-three|1000" "queued toast should be promoted after a visible toast is dismissed"
assert_eq "$(toast_state_queue_size)" "0" "queue should be consumed after promotion"

printf "PASS: toast stack render tests\n"
