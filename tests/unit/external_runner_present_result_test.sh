#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/actions/external_runner.sh
source "${TEST_ROOT}/src/actions/external_runner.sh"
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"
# shellcheck source=src/state/modal_state.sh
source "${TEST_ROOT}/src/state/modal_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf "FAIL: %s\nmissing: %q\nactual:  %q\n" "${message}" "${needle}" "${haystack}" >&2
    exit 1
  fi
}

external_runner_reset
toast_state_reset
modal_state_reset

external_runner_last_stdout="installed successfully"
external_runner_last_stderr=""
external_runner_last_error=""
external_runner_present_result "install" 0 0 >/dev/null
assert_eq "$(modal_state_is_active)" "1" "install should open modal"
assert_eq "${modal_state_type}" "text" "install should use text modal"
assert_contains "${modal_state_title}" "install (success)" "install modal title should include action and severity"
assert_contains "${modal_state_message}" "install: installed successfully" "install modal should include action details"
assert_eq "$(toast_state_visible_count)" "0" "install should not enqueue toast when modal is available"

modal_state_close
external_runner_last_stdout=""
external_runner_last_stderr="not installed"
external_runner_last_error=""
external_runner_present_result "status" 1 0 >/dev/null
assert_eq "$(modal_state_is_active)" "0" "status should not open modal"
assert_eq "$(toast_state_visible_count)" "1" "status should enqueue toast"
status_toast="$(toast_state_get_visible 0)"
assert_eq "${status_toast%%|*}" "warn" "status rc=1 should become warn toast"
assert_contains "${status_toast}" "status: not installed" "status toast should include status detail"

external_runner_last_stdout=""
external_runner_last_stderr=""
external_runner_last_error="external_runner: execution timed out after 2s"
external_runner_present_result "remove" 124 1 >/dev/null
assert_eq "$(modal_state_is_active)" "1" "remove should open modal"
assert_contains "${modal_state_title}" "remove (error)" "timeout remove should show error severity in modal"
assert_contains "${modal_state_message}" "execution timed out after 2s" "timeout remove should expose timeout detail"

printf "PASS: external runner present result tests\n"
