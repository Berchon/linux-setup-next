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

assert_rc() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" -ne "${expected}" ]]; then
    printf "FAIL: %s\nexpected rc: %s\nactual rc:   %s\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

sandbox_dir="$(mktemp -d)"
allowed_dir="${sandbox_dir}/allowed"
mkdir -p "${allowed_dir}"
script_path="${allowed_dir}/ok.sh"
cat > "${script_path}" <<'SCRIPT'
#!/usr/bin/env bash
printf 'runner-ok\n'
SCRIPT
chmod +x "${script_path}"

external_runner_reset
external_runner_set_allowed_dir "${allowed_dir}"

external_runner_has_timeout_command() {
  return 0
}

external_runner_timeout_command() {
  return 0
}

external_runner_execute_with_timeout "ok.sh" "3"
assert_rc "$?" 0 "successful execution should return zero"
assert_eq "${external_runner_last_rc}" "0" "last rc should be zero on success"
assert_eq "${external_runner_last_timed_out}" "0" "success should not mark timeout"

external_runner_timeout_command() {
  return 124
}

set +o errexit
external_runner_execute_with_timeout "ok.sh" "2"
rc="$?"
set -o errexit
assert_rc "${rc}" 124 "timeout should preserve timeout exit code"
assert_eq "${external_runner_last_rc}" "124" "last rc should keep timeout exit code"
assert_eq "${external_runner_last_timed_out}" "1" "timeout execution should set timed_out flag"
assert_eq "${external_runner_last_error}" "external_runner: execution timed out after 2s" "timeout should provide explicit error"

set +o errexit
external_runner_execute_with_timeout "ok.sh" "0"
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "timeout validation should reject non-positive values"
assert_eq "${external_runner_last_error}" "external_runner: timeout must be a positive integer" "invalid timeout should provide validation error"

external_runner_has_timeout_command() {
  return 1
}

set +o errexit
external_runner_execute_with_timeout "ok.sh" "2"
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "execution should fail when timeout command is missing"
assert_eq "${external_runner_last_error}" "external_runner: timeout command is unavailable" "missing timeout command should produce deterministic error"

rm -rf "${sandbox_dir}"
printf "PASS: external runner timeout tests\n"
