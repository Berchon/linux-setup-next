#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/actions/external_runner.sh
source "${TEST_ROOT}/src/actions/external_runner.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

external_runner_reset
external_runner_map_exit_code_to_severity "install" 0 0 >/dev/null
assert_eq "${REPLY}" "success" "install rc=0 should map to success"
assert_eq "${external_runner_last_severity}" "success" "last severity should track last mapping"

external_runner_map_exit_code_to_severity "status" 0 0 >/dev/null
assert_eq "${REPLY}" "info" "status rc=0 should map to info"
external_runner_map_exit_code_to_severity "status" 1 0 >/dev/null
assert_eq "${REPLY}" "warn" "status rc=1 should map to warn"
external_runner_map_exit_code_to_severity "remove" 1 0 >/dev/null
assert_eq "${REPLY}" "error" "remove rc=1 should map to error"
external_runner_map_exit_code_to_severity "install" 127 0 >/dev/null
assert_eq "${REPLY}" "warn" "optional dependency rc should map to warn"
external_runner_map_exit_code_to_severity "status" 127 0 >/dev/null
assert_eq "${REPLY}" "warn" "status with missing dependency should map to warn"
external_runner_map_exit_code_to_severity "install" 2 0 >/dev/null
assert_eq "${REPLY}" "error" "generic non-zero should map to error"
external_runner_map_exit_code_to_severity "install" 124 0 >/dev/null
assert_eq "${REPLY}" "error" "timeout rc should map to error"
external_runner_map_exit_code_to_severity "status" 0 1 >/dev/null
assert_eq "${REPLY}" "error" "timed out executions should map to error"

printf "PASS: external runner severity mapping tests\n"
