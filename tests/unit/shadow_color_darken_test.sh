#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/components/shadow.sh
source "${TEST_ROOT}/src/components/shadow.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

# 16-color behavior requested by product direction.
assert_eq "$(shadow_darken_color 12 16)" "4" "light blue should darken to dark blue in 16 colors"
assert_eq "$(shadow_darken_color 4 16)" "8" "dark blue should darken to dark gray in 16 colors"
assert_eq "$(shadow_darken_color 8 16)" "0" "dark gray should darken to black in 16 colors"

# Basic 256-color sanity.
assert_eq "$(shadow_darken_color 39 256)" "32" "256-color blue family should darken while keeping hue range"
assert_eq "$(shadow_darken_color 232 256)" "16" "darkest grayscale should clamp toward cube black"

printf "PASS: shadow color darken tests\n"
