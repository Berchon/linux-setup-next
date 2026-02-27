#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/components/modal.sh
source "${TEST_ROOT}/src/components/modal.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_eq "$(modal_map_action_by_context text $'\n')" "close" "text modal should close on enter"
assert_eq "$(modal_map_action_by_context text $'\033')" "close" "text modal should close on escape"
assert_eq "$(modal_map_action_by_context text x)" "noop" "text modal should ignore unrelated keys"

assert_eq "$(modal_map_action_by_context confirm $'\033[D')" "focus_left" "confirm modal should map left arrow to focus_left"
assert_eq "$(modal_map_action_by_context confirm $'\033[C')" "focus_right" "confirm modal should map right arrow to focus_right"
assert_eq "$(modal_map_action_by_context confirm $'\n')" "submit" "confirm modal should submit on enter"
assert_eq "$(modal_map_action_by_context confirm q)" "cancel" "confirm modal should cancel on q"

assert_eq "$(modal_should_consume_input 1)" "1" "active modal must consume input"
assert_eq "$(modal_should_consume_input 0)" "0" "inactive modal must not consume input"

printf "PASS: modal input context tests\n"
