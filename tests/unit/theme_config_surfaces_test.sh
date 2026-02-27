#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"
# shellcheck source=src/config/theme_config.sh
source "${TEST_ROOT}/src/config/theme_config.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

config_loader_reset_raw
CONFIG_RAW["theme.menu.fg"]="25"
CONFIG_RAW["theme.menu.bg"]="26"
CONFIG_RAW["theme.modal.fg"]="27"
CONFIG_RAW["theme.modal.bg"]="28"
CONFIG_RAW["theme.toast.fg"]="29"
CONFIG_RAW["theme.toast.bg"]="30"
config_schema_resolve_from_raw

assert_eq "$(theme_config_menu_fg)" "25" "menu fg should come from config"
assert_eq "$(theme_config_menu_bg)" "26" "menu bg should come from config"
assert_eq "$(theme_config_modal_fg)" "27" "modal fg should come from config"
assert_eq "$(theme_config_modal_bg)" "28" "modal bg should come from config"
assert_eq "$(theme_config_toast_fg)" "29" "toast fg should come from config"
assert_eq "$(theme_config_toast_bg)" "30" "toast bg should come from config"

config_loader_reset_raw
config_schema_resolve_from_raw

assert_eq "$(theme_config_menu_fg)" "15" "menu fg should fallback to default"
assert_eq "$(theme_config_menu_bg)" "4" "menu bg should fallback to default"
assert_eq "$(theme_config_modal_fg)" "15" "modal fg should fallback to default"
assert_eq "$(theme_config_modal_bg)" "0" "modal bg should fallback to default"
assert_eq "$(theme_config_toast_fg)" "0" "toast fg should fallback to default"
assert_eq "$(theme_config_toast_bg)" "3" "toast bg should fallback to default"

printf "PASS: theme menu/modal/toast config tests\n"
