#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
# shellcheck source=src/render/diff_renderer.sh
source "${TEST_ROOT}/src/render/diff_renderer.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

diff_renderer_set_color_capacity 16
assert_eq "$(diff_renderer_style_sequence 196 240 1)" $'\033[1;34;40m' "16-color mode should map styles to ANSI 16-color palette"

diff_renderer_set_color_capacity 256
assert_eq "$(diff_renderer_style_sequence 196 240 0)" $'\033[22;38;5;196;48;5;240m' "256-color mode should emit 256-color ANSI sequences"

ansi_output=""
runtime_emit_ansi() {
  ansi_output+="$1"
}

cell_buffer_init 1 1
dirty_regions_init 1 1
cell_buffer_write_cell back 0 0 "X" 196 240 0
dirty_regions_add 0 0 1 1

runtime_color_capacity=16
diff_renderer_render_dirty
assert_eq "${ansi_output}" $'\033[1;1H\033[22;34;40mX' "render should follow runtime 16-color policy"

ansi_output=""
cell_buffer_write_cell back 0 0 "Y" 196 240 0
dirty_regions_add 0 0 1 1
runtime_color_capacity=256
diff_renderer_render_dirty
assert_eq "${ansi_output}" $'\033[1;1H\033[22;38;5;196;48;5;240mY' "render should switch to runtime 256-color policy when available"

printf "PASS: diff renderer color policy tests\n"
