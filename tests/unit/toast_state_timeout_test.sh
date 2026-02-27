#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

toast_state_reset
assert_eq "$(toast_state_get_default_ttl_ms)" "3000" "default ttl should start at baseline value"

toast_state_set_default_ttl_ms 1800
assert_eq "$(toast_state_get_default_ttl_ms)" "1800" "default ttl should be configurable"

if toast_state_set_default_ttl_ms 0; then
  printf "ASSERTION FAILED: zero ttl should be rejected\n" >&2
  exit 1
fi

if toast_state_set_default_ttl_ms bad; then
  printf "ASSERTION FAILED: non-numeric ttl should be rejected\n" >&2
  exit 1
fi

toast_state_enqueue "info" "fallback default" ""
toast_state_enqueue "warn" "explicit ttl" "750"
toast_state_enqueue "error" "invalid fallback" "bad"

assert_eq "$(toast_state_get_visible 0)" "error|invalid fallback|1800" "invalid ttl should fallback to configured default"
assert_eq "$(toast_state_get_visible 1)" "warn|explicit ttl|750" "valid ttl should be preserved"
assert_eq "$(toast_state_get_visible 2)" "info|fallback default|1800" "missing ttl should fallback to configured default"

printf "PASS: toast timeout tests\n"
