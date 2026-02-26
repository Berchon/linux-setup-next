#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/render/dirty_regions.sh
source "${TEST_ROOT}/src/render/dirty_regions.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

if dirty_regions_init 0 24 >/dev/null 2>&1; then
  printf "ASSERTION FAILED: dirty_regions_init should reject invalid viewport\n" >&2
  exit 1
fi

dirty_regions_init 80 24
assert_eq "${dirty_regions_screen_width}" "80" "viewport width should be initialized"
assert_eq "${dirty_regions_screen_height}" "24" "viewport height should be initialized"
assert_eq "$(dirty_regions_count)" "0" "registry should start empty after init"

dirty_regions_add 1 2 10 4
dirty_regions_add 20 3 5 1
assert_eq "$(dirty_regions_count)" "2" "add should append regions"
assert_eq "$(dirty_regions_get 0)" "1|2|10|4" "first region should preserve insertion order"
assert_eq "$(dirty_regions_get 1)" "20|3|5|1" "second region should preserve insertion order"

dirty_regions_add 9 9 0 10
assert_eq "$(dirty_regions_count)" "2" "zero-width region should be ignored"

if dirty_regions_add x 1 2 2 >/dev/null 2>&1; then
  printf "ASSERTION FAILED: dirty_regions_add should reject invalid coordinates\n" >&2
  exit 1
fi

if dirty_regions_get 9 >/dev/null 2>&1; then
  printf "ASSERTION FAILED: dirty_regions_get should reject out-of-range index\n" >&2
  exit 1
fi

dirty_regions_reset
assert_eq "$(dirty_regions_count)" "0" "reset should clear registered regions"

printf "PASS: dirty regions register tests\n"
