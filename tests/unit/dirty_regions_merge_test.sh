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

dirty_regions_init 80 24

dirty_regions_add 0 0 4 2
dirty_regions_add 2 1 4 3
assert_eq "$(dirty_regions_count)" "1" "overlapping regions should be merged"
assert_eq "$(dirty_regions_get 0)" "0|0|6|4" "merge should keep union bounds"

dirty_regions_add 20 5 2 2
assert_eq "$(dirty_regions_count)" "2" "non-overlapping regions should remain separated"

dirty_regions_reset
dirty_regions_add 0 0 2 2
dirty_regions_add 3 0 2 2
dirty_regions_add 1 0 3 2
assert_eq "$(dirty_regions_count)" "1" "bridge overlap should collapse region chains"
assert_eq "$(dirty_regions_get 0)" "0|0|5|2" "chain merge should include full combined extent"

dirty_regions_reset
dirty_regions_add 0 0 2 2
dirty_regions_add 2 0 2 2
assert_eq "$(dirty_regions_count)" "2" "touching edges should not merge without overlap"

printf "PASS: dirty regions merge tests\n"
