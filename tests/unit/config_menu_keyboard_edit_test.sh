#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/state/menu_state.sh
source "${TEST_ROOT}/src/state/menu_state.sh"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"
# shellcheck source=src/state/config_menu_state.sh
source "${TEST_ROOT}/src/state/config_menu_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

menu_state_reset
config_schema_reset_values
config_schema_resolve_from_raw
config_menu_state_build_tree "settings" "Settings"

config_menu_state_apply_input "cfg_key_theme_menu_shadow_enabled" "l"
assert_eq "$(config_schema_get_value "theme.menu.shadow.enabled")" "false" "bool values should toggle via keyboard input"

config_menu_state_apply_input "cfg_key_theme_menu_shadow_enabled" "h"
assert_eq "$(config_schema_get_value "theme.menu.shadow.enabled")" "true" "bool toggle should be reversible"

config_menu_state_apply_input "cfg_key_theme_menu_border_style" "l"
assert_eq "$(config_schema_get_value "theme.menu.border_style")" "double" "enum should cycle forward on right input"

config_menu_state_apply_input "cfg_key_theme_menu_border_style" $'\n'
assert_eq "$(config_schema_get_value "theme.menu.border_style")" "none" "enum should cycle forward on enter input"

config_menu_state_apply_input "cfg_key_theme_menu_border_style" "h"
assert_eq "$(config_schema_get_value "theme.menu.border_style")" "double" "enum should cycle backward on left input"

config_menu_state_apply_input "cfg_key_theme_menu_fg" "l"
assert_eq "$(config_schema_get_value "theme.menu.fg")" "16" "int should increment on right input"

config_menu_state_apply_input "cfg_key_theme_menu_fg" "h"
assert_eq "$(config_schema_get_value "theme.menu.fg")" "15" "int should decrement on left input"

config_schema_set_value "theme.menu.fg" "255"
set +o errexit
config_menu_state_apply_input "cfg_key_theme_menu_fg" "l"
rc="$?"
set -o errexit
assert_eq "${rc}" "1" "int should clamp and report no change at max bound"
assert_eq "$(config_schema_get_value "theme.menu.fg")" "255" "int should remain at max bound after clamp"

set +o errexit
config_menu_state_apply_input "cfg_group_theme_menu" "l"
rc="$?"
set -o errexit
assert_eq "${rc}" "1" "group nodes should not accept value edits"

printf "PASS: config menu keyboard edit tests\n"
