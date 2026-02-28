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

ok_script="${allowed_dir}/capture_ok.sh"
cat > "${ok_script}" <<'SCRIPT'
#!/usr/bin/env bash
printf '\033[32mhello\033[0m\r\n'
printf 'clean\a\n'
printf '\033[31mwarn\033[0m\r\n' >&2
SCRIPT
chmod +x "${ok_script}"

fail_script="${allowed_dir}/capture_fail.sh"
cat > "${fail_script}" <<'SCRIPT'
#!/usr/bin/env bash
printf 'out\n'
printf '\033[33mboom\033[0m\n' >&2
exit 42
SCRIPT
chmod +x "${fail_script}"

external_runner_reset
external_runner_set_allowed_dir "${allowed_dir}"

external_runner_has_timeout_command() {
  return 0
}

external_runner_timeout_command() {
  local _timeout="$1"
  shift
  "$@"
}

external_runner_run_script "capture_ok.sh" "3"
assert_rc "$?" 0 "successful script should keep zero rc"
assert_eq "${external_runner_last_stdout}" $'hello\n\nclean' "stdout should be sanitized and normalize CR"
assert_eq "${external_runner_last_stderr}" $'warn' "stderr should be sanitized"

set +o errexit
external_runner_run_script "capture_fail.sh" "3"
rc="$?"
set -o errexit
assert_rc "${rc}" 42 "runner should preserve non-zero script rc"
assert_eq "${external_runner_last_rc}" "42" "runner should store non-zero rc"
assert_eq "${external_runner_last_stdout}" "out" "stdout should still be captured on failures"
assert_eq "${external_runner_last_stderr}" "boom" "stderr should be captured and sanitized on failures"

rm -rf "${sandbox_dir}"
printf "PASS: external runner capture sanitize tests\n"
