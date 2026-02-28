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

external_runner_reset
external_runner_init_reference_actions

assert_eq \
  "$(external_runner_resolve_reference_script "K380" "INSTALL")" \
  "keyboards/k380/install.sh" \
  "resolver should normalize device/action casing"

set +o errexit
external_runner_resolve_reference_script "k380" "upgrade" >/dev/null
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "unsupported action must fail"
assert_eq "${external_runner_last_error}" "external_runner: unsupported action 'upgrade'" "unsupported action message should stay stable"

set +o errexit
external_runner_resolve_reference_script "mx-keys" "status" >/dev/null
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "unsupported reference device must fail"
assert_eq "${external_runner_last_error}" "external_runner: unsupported reference device 'mx-keys'" "unsupported device message should stay stable"

set +o errexit
external_runner_register_reference_device "bad device" "a" "b" "c" >/dev/null
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "invalid device id must be rejected"
assert_eq "${external_runner_last_error}" "external_runner: invalid reference device 'bad device'" "invalid device error should stay stable"

set +o errexit
external_runner_register_reference_device "demo" "a" "" "c" >/dev/null
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "incomplete mapping must be rejected"
assert_eq "${external_runner_last_error}" "external_runner: incomplete script mapping for 'demo'" "incomplete mapping error should stay stable"

printf "PASS: external runner reference contract regression tests\n"
