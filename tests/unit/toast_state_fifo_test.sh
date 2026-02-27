#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "ASSERTION FAILED: %s\nExpected: %s\nActual: %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

toast_state_reset
assert_eq "$(toast_state_is_active)" "0" "toast should start inactive"
assert_eq "$(toast_state_queue_size)" "0" "queue should start empty"

toast_state_enqueue "info" "first" "1200"
toast_state_enqueue "warn" "second" "900"
toast_state_enqueue "error" "third" "700"
assert_eq "$(toast_state_queue_size)" "3" "enqueue should append items"

toast_state_activate_next
assert_eq "$(toast_state_is_active)" "1" "activate next should set active"
assert_eq "${toast_state_current_message}" "first" "first enqueued message should be displayed first"
assert_eq "${toast_state_current_severity}" "info" "severity should follow first enqueued toast"
assert_eq "${toast_state_current_ttl_ms}" "1200" "ttl should follow first enqueued toast"
assert_eq "$(toast_state_queue_size)" "2" "queue should remove only active item"

toast_state_dismiss_active
toast_state_activate_next
assert_eq "${toast_state_current_message}" "second" "second toast should become active after dismiss"
assert_eq "${toast_state_current_severity}" "warn" "second severity should be preserved"
assert_eq "$(toast_state_queue_size)" "1" "queue should keep remaining tail"

toast_state_dismiss_active
toast_state_activate_next
assert_eq "${toast_state_current_message}" "third" "third toast should be last in fifo order"
assert_eq "${toast_state_current_severity}" "error" "third severity should be preserved"
assert_eq "$(toast_state_queue_size)" "0" "queue should be empty after consuming all toasts"

printf "PASS: toast state fifo tests\n"
