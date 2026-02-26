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

ansi_output=""
runtime_emit_ansi() {
  ansi_output+="$1"
}

cell_buffer_init 4 1
dirty_regions_init 4 1

cell_buffer_write_cell back 0 0 "A" 2 3 1
cell_buffer_write_cell back 2 0 "C" 2 3 1
dirty_regions_add 0 0 4 1

diff_renderer_render_dirty

assert_eq "${ansi_output}" $'\033[1;1H\033[1;32;43mA\033[1;3HC' "renderer should emit cursor moves and avoid repeating identical style sequence"
assert_eq "$(cell_buffer_get_cell front 0 0)" "A|2|3|1" "render should swap back buffer into front"
assert_eq "$(cell_buffer_get_cell front 2 0)" "C|2|3|1" "render should keep all changed cells after swap"
assert_eq "$(cell_buffer_get_cell back 0 0)" " |7|0|0" "swap should move previous front into back buffer"
assert_eq "$(dirty_regions_count)" "0" "render should clear dirty regions after flushing"

printf "PASS: diff renderer emit and swap tests\n"
