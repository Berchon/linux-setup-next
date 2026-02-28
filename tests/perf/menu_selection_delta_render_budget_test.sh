#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
# shellcheck source=src/render/diff_renderer.sh
source "${TEST_ROOT}/src/render/diff_renderer.sh"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %s\nactual:   %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_le() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if ((actual > expected)); then
    printf "FAIL: %s\nexpected <= %s\nactual:      %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

capture_ansi=""

diff_renderer_emit_ansi() {
  capture_ansi+="$1"
}

cell_buffer_init 80 24
dirty_regions_init 80 24

# Base state rendered in both buffers with selection at line 0.
menu_render_line front 2 2 20 "Keyboard K380" 1 7 0 0 7
menu_render_line front 2 3 20 "Keyboard K270" 0 7 0 0 7
menu_render_line back 2 2 20 "Keyboard K380" 1 7 0 0 7
menu_render_line back 2 3 20 "Keyboard K270" 0 7 0 0 7

# Simulate one down navigation event: previous + next selected rows only.
menu_render_line back 2 2 20 "Keyboard K380" 0 7 0 0 7
menu_render_line back 2 3 20 "Keyboard K270" 1 7 0 0 7
menu_mark_selection_delta_dirty 2 2 20 2 0 1 0

capture_ansi=""
diff_renderer_render_dirty

assert_eq "$(dirty_regions_count)" "0" "dirty regions should be consumed after render"
assert_le "$(diff_renderer_run_count)" "2" "delta render should keep run count bounded to two lines"
assert_le "${#capture_ansi}" "140" "ansi payload for single selection delta should stay within budget"

printf "PASS: menu selection delta render budget perf test\n"
