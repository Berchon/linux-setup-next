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

sandbox_dir="$(mktemp -d)"
allowed_dir="${sandbox_dir}/allowed"
mkdir -p "${allowed_dir}"

missing_dep_script="${allowed_dir}/status_missing_dep.sh"
cat > "${missing_dep_script}" <<'SCRIPT'
#!/usr/bin/env bash
missing_optional_tool >/dev/null
SCRIPT
chmod +x "${missing_dep_script}"

generic_fail_script="${allowed_dir}/install_fail.sh"
cat > "${generic_fail_script}" <<'SCRIPT'
#!/usr/bin/env bash
printf 'fatal\n' >&2
exit 2
SCRIPT
chmod +x "${generic_fail_script}"

external_runner_reset
toast_state_reset
modal_state_reset
external_runner_set_allowed_dir "${allowed_dir}"

external_runner_has_timeout_command() {
  return 0
}

external_runner_timeout_command() {
  local _timeout="$1"
  shift
  "$@"
}

set +o errexit
external_runner_run_action "status" "status_missing_dep.sh" "3"
rc="$?"
set -o errexit
assert_rc "${rc}" 0 "missing optional dependency should not break action flow"
assert_eq "${external_runner_last_optional_dependency_missing}" "1" "missing dependency flag should be set"
assert_eq "${external_runner_last_severity}" "warn" "missing dependency should degrade severity to warn"
assert_eq "$(toast_state_visible_count)" "1" "status flow should still emit feedback toast"

set +o errexit
external_runner_run_action "install" "install_fail.sh" "3"
rc="$?"
set -o errexit
assert_rc "${rc}" 2 "generic failure should keep failing rc"
assert_eq "${external_runner_last_optional_dependency_missing}" "0" "generic failure must not be marked as optional dependency"
assert_eq "${external_runner_last_severity}" "error" "generic failure should stay error"
assert_eq "$(modal_state_is_active)" "1" "install failure should keep modal feedback"

rm -rf "${sandbox_dir}"
printf "PASS: external runner optional dependency tests\n"
