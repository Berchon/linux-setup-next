#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly MAIN_SCRIPT="${TEST_ROOT}/src/app/main.sh"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf "FAIL: %s\nmissing: %q\n" "${message}" "${needle}" >&2
    exit 1
  fi
}

output="$("${MAIN_SCRIPT}" 2>&1)"

assert_contains "${output}" "linux-setup-next: bootstrap ready" "main bootstrap output should be printed"
assert_contains "${output}" $'\033[?1049h' "runtime should enter alternate screen"
assert_contains "${output}" $'\033[?1049l' "runtime should leave alternate screen during cleanup"

printf "PASS: app bootstrap smoke e2e test\n"
