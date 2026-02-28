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

assert_rc() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" -ne "${expected}" ]]; then
    printf "FAIL: %s\nexpected rc: %s\nactual rc:   %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

external_runner_has_timeout_command() {
  return 0
}

external_runner_timeout_command() {
  local _timeout="$1"
  shift
  "$@"
}

run_flow_for_device() {
  local device="$1"
  local sandbox_dir=""
  local allowed_dir=""
  local state_file=""
  local rc=0

  sandbox_dir="$(mktemp -d)"
  allowed_dir="${sandbox_dir}/allowed"
  state_file="${sandbox_dir}/${device}.state"

  mkdir -p "${allowed_dir}"
  cp -R "${TEST_ROOT}/scripts/keyboards" "${allowed_dir}/"

  external_runner_reset
  toast_state_reset
  modal_state_reset
  external_runner_set_allowed_dir "${allowed_dir}"

  set +o errexit
  LSN_STATE_FILE_OVERRIDE="${state_file}" external_runner_run_reference_action "${device}" "status" "3"
  rc="$?"
  set -o errexit
  assert_rc "${rc}" 1 "status should keep non-zero rc when device is not installed"
  assert_eq "${external_runner_last_severity}" "warn" "status not installed should map to warn"

  set +o errexit
  LSN_STATE_FILE_OVERRIDE="${state_file}" external_runner_run_reference_action "${device}" "install" "3"
  rc="$?"
  set -o errexit
  assert_rc "${rc}" 0 "install should succeed"
  assert_eq "${external_runner_last_severity}" "success" "install should map to success"

  set +o errexit
  LSN_STATE_FILE_OVERRIDE="${state_file}" external_runner_run_reference_action "${device}" "remove" "3"
  rc="$?"
  set -o errexit
  assert_rc "${rc}" 2 "remove without confirmation should require explicit confirmation"
  assert_eq "${external_runner_last_severity}" "error" "remove validation failure should stay error"

  set +o errexit
  LSN_STATE_FILE_OVERRIDE="${state_file}" external_runner_run_reference_action "${device}" "remove" "3" "--confirm"
  rc="$?"
  set -o errexit
  assert_rc "${rc}" 0 "remove with confirmation should succeed"
  assert_eq "${external_runner_last_severity}" "success" "confirmed remove should map to success"

  rm -rf "${sandbox_dir}"
}

run_flow_for_device "k380"
run_flow_for_device "k270"

printf "PASS: external runner reference validation tests\n"
