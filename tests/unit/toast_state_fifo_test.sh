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
assert_eq "$(toast_state_visible_count)" "0" "visible stack should start empty"

toast_state_enqueue "info" "first" "1200"
toast_state_enqueue "warn" "second" "900"
toast_state_enqueue "error" "third" "700"
assert_eq "$(toast_state_visible_count)" "3" "toasts should be visible until max stack"
assert_eq "$(toast_state_queue_size)" "0" "queue should stay empty while there is visible capacity"
assert_eq "$(toast_state_get_visible 0)" "error|third|700" "newest toast should be inserted on top"
assert_eq "$(toast_state_get_visible 1)" "warn|second|900" "older visible toast should shift down"
assert_eq "$(toast_state_get_visible 2)" "info|first|1200" "oldest visible toast should remain at bottom"

toast_state_enqueue "success" "fourth" "600"
toast_state_enqueue "warn" "fifth" "500"
assert_eq "$(toast_state_visible_count)" "3" "visible stack should stay capped at max_visible"
assert_eq "$(toast_state_queue_size)" "2" "overflow toasts should be kept in fifo queue"
assert_eq "${toast_state_queue_message[0]}" "fourth" "first overflow should stay first in queue"
assert_eq "${toast_state_queue_message[1]}" "fifth" "queue should preserve overflow order"

toast_state_dismiss_active
assert_eq "$(toast_state_visible_count)" "3" "dismissing top should promote one queued toast"
assert_eq "$(toast_state_get_visible 0)" "success|fourth|600" "promoted queued toast should enter at top"
assert_eq "$(toast_state_queue_size)" "1" "queue should consume one promoted toast"
assert_eq "${toast_state_queue_message[0]}" "fifth" "remaining queue item should be preserved"

printf "PASS: toast state fifo tests\n"
