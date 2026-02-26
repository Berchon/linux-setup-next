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

dirty_regions_init 10 4

dirty_regions_add -2 -1 4 3
assert_eq "$(dirty_regions_count)" "1" "negative origin should be clipped into viewport"
assert_eq "$(dirty_regions_get 0)" "0|0|2|2" "clipped region should keep only visible area"

dirty_regions_add 8 3 5 3
assert_eq "$(dirty_regions_count)" "2" "overflow on right/bottom should be clipped and kept"
assert_eq "$(dirty_regions_get 1)" "8|3|2|1" "region should clip to viewport limits"

dirty_regions_add 15 0 2 2
dirty_regions_add 0 8 3 3
assert_eq "$(dirty_regions_count)" "2" "fully out-of-viewport regions should be ignored"

dirty_regions_add 1 1 20 10
assert_eq "$(dirty_regions_count)" "1" "clipped region should still merge with overlapping existing regions"
assert_eq "$(dirty_regions_get 0)" "0|0|10|4" "merged clipped result should respect viewport bounds"

printf "PASS: dirty regions clipping tests\n"
