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

panel_content_calls=0
panel_last_content_rect=""

panel_test_content_renderer() {
  local buffer_name="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"
  local text="${6:-CONTENT}"
  local clipped_text="${text:0:width}"

  panel_content_calls=$((panel_content_calls + 1))
  panel_last_content_rect="${x}|${y}|${width}|${height}|${text}"
  cell_buffer_write_text "${buffer_name}" "${x}" "${y}" "${clipped_text}" 5 1 1
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

assert_eq "$(panel_content_rect 2 2 10 6 single 1 2 1 0)" "3|4|6|2" "content rect should respect border and per-side padding"
assert_eq "$(panel_content_rect 0 0 8 4 none 1 1 0 2)" "2|1|5|3" "content rect should respect padding without border"
assert_eq "$(panel_content_rect 1 1 4 3 single 1 1 1 1)" "3|3|0|0" "content rect should collapse when padding consumes available area"

if panel_content_rect 0 0 4 3 none -1 0 0 0 >/dev/null 2>&1; then
  printf "FAIL: content rect should reject negative padding\n" >&2
  exit 1
fi

if panel_render back 0 0 4 3 "." 1 2 0 none "" 0 1 1 "." 0 8 0 "bad" 0 0 0 >/dev/null 2>&1; then
  printf "FAIL: panel render should reject invalid padding values\n" >&2
  exit 1
fi

cell_buffer_init 12 8
panel_content_calls=0
panel_last_content_rect=""
panel_render_with_content back 1 1 8 5 "." 2 4 0 single "P" 0 1 1 "." 0 8 0 1 1 0 1 panel_test_content_renderer "HELLO"
assert_eq "${panel_content_calls}" "1" "content renderer should be invoked once when content rect is visible"
assert_eq "${panel_last_content_rect}" "3|3|4|2|HELLO" "content renderer should receive computed content rect and custom arg"
assert_eq "$(cell_buffer_get_cell back 3 3)" "H|5|1|1" "content renderer should draw at content origin"
assert_eq "$(cell_buffer_get_cell back 6 3)" "L|5|1|1" "content renderer should clip content to content width"
assert_eq "$(cell_buffer_get_cell back 7 3)" ".|2|4|0" "content renderer should not overflow beyond content width"

cell_buffer_init 8 5
panel_content_calls=0
panel_last_content_rect=""
panel_render_with_content back 1 1 4 3 "." 2 4 0 single "P" 0 1 1 "." 0 8 0 1 1 1 1 panel_test_content_renderer "HIDDEN"
assert_eq "${panel_content_calls}" "0" "content renderer should not be called when content rect is empty"

if panel_render_with_content back 0 0 4 3 "." 1 2 0 none "" 0 1 1 "." 0 8 0 0 0 0 0 missing_renderer >/dev/null 2>&1; then
  printf "FAIL: panel render with content should fail when callback is missing\n" >&2
  exit 1
fi

printf "PASS: panel composition tests\n"
