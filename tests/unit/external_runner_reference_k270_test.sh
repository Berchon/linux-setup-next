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
mkdir -p "${allowed_dir}/keyboards/k270"

cat > "${allowed_dir}/keyboards/k270/install.sh" <<'SCRIPT'
#!/usr/bin/env bash
printf 'k270 installed\n'
SCRIPT
chmod +x "${allowed_dir}/keyboards/k270/install.sh"

cat > "${allowed_dir}/keyboards/k270/remove.sh" <<'SCRIPT'
#!/usr/bin/env bash
printf 'k270 removed\n'
SCRIPT
chmod +x "${allowed_dir}/keyboards/k270/remove.sh"

cat > "${allowed_dir}/keyboards/k270/status.sh" <<'SCRIPT'
#!/usr/bin/env bash
printf 'k270 not installed\n' >&2
exit 1
SCRIPT
chmod +x "${allowed_dir}/keyboards/k270/status.sh"

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

assert_eq \
  "$(external_runner_resolve_reference_script "k270" "remove")" \
  "keyboards/k270/remove.sh" \
  "k270 remove mapping should resolve to script"

set +o errexit
external_runner_run_reference_action "k270" "status" "3"
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "k270 status should propagate script rc for not installed"
assert_eq "${external_runner_last_stderr}" "k270 not installed" "k270 status stderr should be captured"
assert_eq "${external_runner_last_severity}" "warn" "status rc=1 should map to warn severity"

rm -rf "${sandbox_dir}"
printf "PASS: external runner reference k270 tests\n"
