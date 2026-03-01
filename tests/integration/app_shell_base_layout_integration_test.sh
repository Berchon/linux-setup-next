#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"
# shellcheck source=src/config/config_store.sh
source "${TEST_ROOT}/src/config/config_store.sh"
# shellcheck source=src/config/theme_config.sh
source "${TEST_ROOT}/src/config/theme_config.sh"
# shellcheck source=src/i18n/i18n.sh
source "${TEST_ROOT}/src/i18n/i18n.sh"
# shellcheck source=src/state/menu_state.sh
source "${TEST_ROOT}/src/state/menu_state.sh"
# shellcheck source=src/state/config_menu_state.sh
source "${TEST_ROOT}/src/state/config_menu_state.sh"
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"
# shellcheck source=src/state/ui_state.sh
source "${TEST_ROOT}/src/state/ui_state.sh"
# shellcheck source=src/render/cell_buffer.sh
source "${TEST_ROOT}/src/render/cell_buffer.sh"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"
# shellcheck source=src/render/diff_renderer.sh
source "${TEST_ROOT}/src/render/diff_renderer.sh"
# shellcheck source=src/components/rectangle.sh
source "${TEST_ROOT}/src/components/rectangle.sh"
# shellcheck source=src/components/shadow.sh
source "${TEST_ROOT}/src/components/shadow.sh"
# shellcheck source=src/components/panel.sh
source "${TEST_ROOT}/src/components/panel.sh"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"
# shellcheck source=src/components/background.sh
source "${TEST_ROOT}/src/components/background.sh"
# shellcheck source=src/app/app_shell.sh
source "${TEST_ROOT}/src/app/app_shell.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_contains() {
  local content="$1"
  local expected="$2"
  local message="$3"

  if [[ "${content}" != *"${expected}"* ]]; then
    printf "FAIL: %s\nmissing: %q\n" "${message}" "${expected}" >&2
    exit 1
  fi
}

ansi_output=""
runtime_emit_ansi() {
  ansi_output+="$1"
}

ui_state_reset
ui_state_boot_config
rectangle_set_border_charset ascii

app_shell_init_framebuffer 30 10
app_shell_set_message_bar "base status"
app_shell_render_base_layout

assert_eq "$(cell_buffer_get_cell front 1 0)" "l|15|4|1" "header should render application title"
assert_eq "$(cell_buffer_get_cell front 0 1)" "+|15|0|0" "central area should render panel border"
assert_eq "$(cell_buffer_get_cell front 2 2)" ".|7|0|0" "center body should use wallpaper pattern tile"
assert_eq "$(cell_buffer_get_cell front 1 9)" "b|15|0|0" "footer should render message bar text"
assert_contains "${ansi_output}" $'\033[1;1H' "diff renderer should emit cursor movement for layout draw"

printf "PASS: app shell base layout integration tests\n"
