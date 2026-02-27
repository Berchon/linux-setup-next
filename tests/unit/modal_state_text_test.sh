#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/state/modal_state.sh
source "${TEST_ROOT}/src/state/modal_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

modal_state_reset
assert_eq "$(modal_state_is_active)" "0" "modal should start inactive"
assert_eq "$(modal_state_blocks_background_input)" "0" "inactive modal should not block background"

modal_state_open_text "Status" "Working"
assert_eq "$(modal_state_is_active)" "1" "text modal should become active"
assert_eq "${modal_state_type}" "text" "text modal should set type"
assert_eq "${modal_state_title}" "Status" "text modal should store title"
assert_eq "${modal_state_message}" "Working" "text modal should store message"
assert_eq "$(modal_state_blocks_background_input)" "1" "active modal should block background"

modal_state_close
assert_eq "$(modal_state_is_active)" "0" "closing modal should reset active"
assert_eq "${modal_state_type}" "" "closing modal should clear type"

printf "PASS: modal text state tests\n"
