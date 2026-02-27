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
CONFIG_RAW["theme.menu.border_style"]="double"
CONFIG_RAW["theme.menu.shadow.enabled"]="false"
CONFIG_RAW["theme.modal.border_style"]="none"
CONFIG_RAW["theme.modal.shadow.enabled"]="0"
CONFIG_RAW["theme.toast.border_style"]="single"
CONFIG_RAW["theme.toast.shadow.enabled"]="1"
config_schema_resolve_from_raw

assert_eq "$(theme_config_menu_border_style)" "double" "menu border style should come from config"
assert_eq "$(theme_config_menu_shadow_enabled)" "0" "menu shadow should normalize to disabled flag"
assert_eq "$(theme_config_modal_border_style)" "none" "modal border style should come from config"
assert_eq "$(theme_config_modal_shadow_enabled)" "0" "modal shadow should normalize to disabled flag"
assert_eq "$(theme_config_toast_border_style)" "single" "toast border style should come from config"
assert_eq "$(theme_config_toast_shadow_enabled)" "1" "toast shadow should normalize to enabled flag"

config_loader_reset_raw
config_schema_resolve_from_raw

assert_eq "$(theme_config_menu_border_style)" "single" "menu border style should fallback to default"
assert_eq "$(theme_config_menu_shadow_enabled)" "1" "menu shadow should fallback to enabled by default"
assert_eq "$(theme_config_modal_border_style)" "single" "modal border style should fallback to default"
assert_eq "$(theme_config_modal_shadow_enabled)" "1" "modal shadow should fallback to enabled by default"
assert_eq "$(theme_config_toast_border_style)" "single" "toast border style should fallback to default"
assert_eq "$(theme_config_toast_shadow_enabled)" "1" "toast shadow should fallback to enabled by default"

printf "PASS: theme component style tests\n"
