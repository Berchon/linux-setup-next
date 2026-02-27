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

assert_eq "$(menu_state_has_node "settings"; printf '%s' "$?")" "0" "tree should include root settings node"
assert_eq "$(menu_state_get_children "settings")" "cfg_group_theme cfg_group_app" "root should expose theme and app sections"
assert_eq "$(menu_state_get_children "cfg_group_theme")" "cfg_group_theme_wallpaper cfg_group_theme_menu cfg_group_theme_modal cfg_group_theme_toast cfg_group_theme_header cfg_group_theme_footer" "theme section should keep schema group order"
assert_eq "$(menu_state_get_children "cfg_group_theme_menu")" "cfg_key_theme_menu_fg cfg_key_theme_menu_bg cfg_key_theme_menu_border_style cfg_group_theme_menu_shadow" "menu group should expose direct leaves and nested groups"
assert_eq "$(menu_state_get_children "cfg_group_theme_menu_shadow")" "cfg_key_theme_menu_shadow_enabled" "nested group should expose final editable key leaf"
assert_eq "$(menu_state_get_action "cfg_key_theme_menu_fg")" "config.edit" "editable key nodes should use config action"
assert_eq "$(config_menu_state_node_key "cfg_key_theme_menu_fg")" "theme.menu.fg" "editable key node should map back to config key"

if config_menu_state_node_key "cfg_group_theme_menu" >/dev/null 2>&1; then
  printf "FAIL: group nodes should not be editable\n" >&2
  exit 1
fi

printf "PASS: config menu tree tests\n"
