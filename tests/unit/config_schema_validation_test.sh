#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_gt_zero() {
  local actual="$1"
  local message="$2"

  if (( actual <= 0 )); then
    printf "FAIL: %s\nactual: %s\n" "${message}" "${actual}" >&2
    exit 1
  fi
}

config_loader_reset_raw
CONFIG_RAW["theme.menu.fg"]="42"
CONFIG_RAW["theme.menu.border_style"]="double"
CONFIG_RAW["theme.menu.shadow.enabled"]="0"
CONFIG_RAW["theme.toast.ttl_ms"]="9999"
CONFIG_RAW["app.language"]="en"

config_schema_resolve_from_raw
assert_eq "${CONFIG_VALUES[theme.menu.fg]}" "42" "schema should keep valid integer values"
assert_eq "${CONFIG_VALUES[theme.menu.border_style]}" "double" "schema should keep valid enum values"
assert_eq "${CONFIG_VALUES[theme.menu.shadow.enabled]}" "false" "schema should normalize boolean values"
assert_eq "${CONFIG_VALUES[theme.toast.ttl_ms]}" "9999" "schema should keep valid ranged integer"
assert_eq "${CONFIG_VALUES[app.language]}" "en" "schema should keep valid language"

config_loader_reset_raw
CONFIG_RAW["theme.menu.fg"]="999"
CONFIG_RAW["theme.menu.border_style"]="rounded"
CONFIG_RAW["theme.menu.shadow.enabled"]="maybe"
CONFIG_RAW["theme.toast.ttl_ms"]="10"
CONFIG_RAW["app.language"]="es"

config_schema_resolve_from_raw
assert_eq "${CONFIG_VALUES[theme.menu.fg]}" "15" "schema should fallback to default for out-of-range color"
assert_eq "${CONFIG_VALUES[theme.menu.border_style]}" "single" "schema should fallback to default for invalid enum"
assert_eq "${CONFIG_VALUES[theme.menu.shadow.enabled]}" "true" "schema should fallback to default for invalid bool"
assert_eq "${CONFIG_VALUES[theme.toast.ttl_ms]}" "2500" "schema should fallback to default for invalid ttl"
assert_eq "${CONFIG_VALUES[app.language]}" "pt" "schema should fallback to default for invalid language"
assert_gt_zero "${#config_schema_warnings[@]}" "schema should register warnings for invalid values"

config_loader_reset_raw
config_schema_resolve_from_raw
assert_eq "${CONFIG_VALUES[theme.header.fg]}" "12" "schema should apply default when key is missing"
assert_eq "$(config_schema_get_value "app.language" "pt")" "pt" "schema get should return stored value"
assert_eq "$(config_schema_get_value "unknown.key" "fallback")" "fallback" "schema get should return fallback for unknown key"

printf "PASS: config schema validation tests\n"
