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
CONFIG_RAW["theme.wallpaper.enabled"]="false"
CONFIG_RAW["theme.wallpaper.fg"]="31"
CONFIG_RAW["theme.wallpaper.bg"]="8"
config_schema_resolve_from_raw

assert_eq "$(theme_config_wallpaper_enabled)" "0" "wallpaper enabled should map false to 0"
assert_eq "$(theme_config_wallpaper_fg)" "31" "wallpaper fg should come from resolved config"
assert_eq "$(theme_config_wallpaper_bg)" "8" "wallpaper bg should come from resolved config"

config_loader_reset_raw
config_schema_resolve_from_raw

assert_eq "$(theme_config_wallpaper_enabled)" "1" "wallpaper enabled should default to true"
assert_eq "$(theme_config_wallpaper_fg)" "7" "wallpaper fg should fallback to default"
assert_eq "$(theme_config_wallpaper_bg)" "0" "wallpaper bg should fallback to default"

printf "PASS: theme wallpaper config tests\n"
