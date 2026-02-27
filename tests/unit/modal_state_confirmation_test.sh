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
modal_state_open_confirm "Confirm" "Remove item?" "Yes" "No" "cancel"

assert_eq "$(modal_state_is_active)" "1" "confirm modal should be active"
assert_eq "${modal_state_type}" "confirm" "confirm modal should set type"
assert_eq "${modal_state_focus_button}" "cancel" "confirm modal should respect initial focus"

modal_state_set_confirm_focus "confirm"
assert_eq "${modal_state_focus_button}" "confirm" "set focus should update active button"

modal_state_toggle_confirm_focus
assert_eq "${modal_state_focus_button}" "cancel" "toggle focus should swap active button"

modal_state_resolve_confirm "confirm" >/dev/null
assert_eq "$(modal_state_is_active)" "0" "resolving confirm should close modal"
assert_eq "${modal_state_result}" "" "close should clear transient state"

modal_state_open_confirm "Confirm" "Remove item?" "Yes" "No" "confirm"
modal_state_apply_confirm_action focus_right >/dev/null
assert_eq "${modal_state_focus_button}" "cancel" "focus action should move to cancel"
modal_state_apply_confirm_action focus_left >/dev/null
assert_eq "${modal_state_focus_button}" "confirm" "focus action should move back to confirm"
modal_state_apply_confirm_action submit >/dev/null
assert_eq "$(modal_state_is_active)" "0" "submit should close modal"

if modal_state_open_confirm "Confirm" "Message" "Yes" "No" "invalid" >/dev/null 2>&1; then
  printf "ASSERTION FAILED: confirm modal should reject invalid focus button\n" >&2
  exit 1
fi

printf "PASS: modal confirmation state tests\n"
