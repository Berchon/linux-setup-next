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

toast_render_frame back 24 10 1 "Saved config" "success"
assert_eq "$(dirty_regions_count)" "1" "opening toast should dirty only toast rect"
assert_eq "${toast_render_cache_visible}" "1" "toast render should keep cache as visible"
assert_eq "$(cell_buffer_get_cell back "${toast_render_cache_x}" "${toast_render_cache_y}")" "+|2|0|0" "toast should render border at computed origin"

active_x="${toast_render_cache_x}"
active_y="${toast_render_cache_y}"
assert_eq "$(cell_buffer_get_cell back "$((active_x + 2))" "$((active_y + 1))")" "S|2|0|1" "toast should render message content"

toast_render_frame back 24 10 0 "" "info"
assert_eq "$(dirty_regions_count)" "1" "closing toast should keep previous rect dirty for cleanup"
assert_eq "${toast_render_cache_visible}" "0" "closing toast should reset cache visibility"
assert_eq "$(cell_buffer_get_cell back "${active_x}" "${active_y}")" " |7|0|0" "closing toast should clear previous toast area"

printf "PASS: toast incremental render tests\n"
