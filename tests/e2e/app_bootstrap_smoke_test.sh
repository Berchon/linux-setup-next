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

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

count_occurrences() {
  local content="$1"
  local needle="$2"
  awk -v content="${content}" -v needle="${needle}" 'BEGIN {
    count = 0
    while ((idx = index(content, needle)) > 0) {
      count++
      content = substr(content, idx + length(needle))
    }
    printf "%d", count
  }'
}

# Force non-interactive mode so the runtime loop does not wait for keyboard input in TTY sessions.
output="$(${MAIN_SCRIPT} </dev/null 2>&1)"

assert_contains "${output}" "linux-setup-next: bootstrap ready" "main bootstrap output should be printed"
assert_contains "${output}" "Ready - press Q to exit." "app shell should render initial message bar"
assert_contains "${output}" $'\033[?1049h' "runtime should enter alternate screen"
assert_contains "${output}" $'\033[?1049l' "runtime should leave alternate screen during cleanup"
assert_eq "$(count_occurrences "${output}" $'\033[?1049l')" "1" "alternate screen leave sequence should be emitted once"

printf "PASS: app bootstrap smoke e2e test\n"
