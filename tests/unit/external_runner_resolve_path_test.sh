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
script_path="${allowed_dir}/safe.sh"
cat > "${script_path}" <<'SCRIPT'
#!/usr/bin/env bash
printf 'ok\n'
SCRIPT

external_runner_reset
external_runner_set_allowed_dir "${allowed_dir}"

resolved="$(external_runner_resolve_script_path "safe.sh")"
assert_eq "${resolved}" "${script_path}" "relative script path should resolve within allowed directory"

mkdir -p "${allowed_dir}/nested"
resolved_nested="$(external_runner_resolve_script_path "nested/../safe.sh")"
assert_eq "${resolved_nested}" "${script_path}" "normalized path should resolve to canonical file"

outside_dir="${sandbox_dir}/outside"
mkdir -p "${outside_dir}"
outside_script="${outside_dir}/bad.sh"
cat > "${outside_script}" <<'SCRIPT'
#!/usr/bin/env bash
printf 'bad\n'
SCRIPT

set +o errexit
external_runner_resolve_script_path "../outside/bad.sh" >/dev/null
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "path traversal must be rejected"
assert_eq "${external_runner_last_error}" "external_runner: script path is outside allowed directory: ../outside/bad.sh" "error message should explain traversal rejection"

set +o errexit
external_runner_resolve_script_path "missing.sh" >/dev/null
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "missing script should fail"
assert_eq "${external_runner_last_error}" "external_runner: script not found: missing.sh" "error message should expose missing file"

rm -rf "${sandbox_dir}"
printf "PASS: external runner resolve path tests\n"
