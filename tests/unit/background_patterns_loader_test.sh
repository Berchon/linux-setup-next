#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/components/background.sh
source "${TEST_ROOT}/src/components/background.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_true() {
  local command="$1"
  local message="$2"

  if ! eval "${command}"; then
    printf "FAIL: %s\n" "${message}" >&2
    exit 1
  fi
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

cat > "${tmp_dir}/alpha.pattern" <<'PATTERN'
id=alpha
pattern:
ab
cd
PATTERN

cat > "${tmp_dir}/beta.pattern" <<'PATTERN'
id=beta
pattern:
#
PATTERN

background_reset_registry
background_load_patterns_from_dir "${tmp_dir}"

assert_true 'background_pattern_exists "alpha"' "alpha pattern should be available"
assert_true 'background_pattern_exists "beta"' "beta pattern should be available"
assert_eq "$(background_pattern_dimensions "alpha")" "2|2" "alpha dimensions should preserve matrix size"
assert_eq "$(background_pattern_dimensions "beta")" "1|1" "beta dimensions should preserve single-char size"

cat > "${tmp_dir}/broken.pattern" <<'PATTERN'
pattern:
oops
PATTERN

set +o errexit
background_load_patterns_from_dir "${tmp_dir}"
rc=$?
set -o errexit

if [[ "${rc}" -eq 0 ]]; then
  printf "FAIL: invalid pattern set should fail to load\n" >&2
  exit 1
fi

assert_true 'background_pattern_exists "default"' "fallback default pattern should be registered on loader failure"

printf "PASS: background patterns loader tests\n"
