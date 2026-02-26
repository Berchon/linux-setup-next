#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/core/runtime.sh
source "${TEST_ROOT}/src/core/runtime.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

runtime_is_tty() {
  return 0
}

runtime_has_tput() {
  return 0
}

runtime_tput_command() {
  case "$1" in
    cup)
      return 0
      ;;
    clear)
      return 0
      ;;
    civis)
      return 0
      ;;
    cnorm)
      return 0
      ;;
    colors)
      printf "256"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

runtime_detect_terminal_capabilities
assert_eq "${runtime_cap_cursor_positioning}" "1" "cursor positioning capability should be detected"
assert_eq "${runtime_cap_clear_screen}" "1" "clear screen capability should be detected"
assert_eq "${runtime_cap_cursor_visibility}" "1" "cursor visibility capability should be detected"
assert_eq "${runtime_terminal_supports_minimum}" "1" "minimum terminal capabilities should be supported"
assert_eq "${runtime_color_capacity}" "256" "color capacity should upgrade to 256 when available"

runtime_tput_command() {
  case "$1" in
    cup)
      return 0
      ;;
    clear)
      return 1
      ;;
    civis)
      return 0
      ;;
    cnorm)
      return 0
      ;;
    colors)
      printf "16"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

runtime_detect_terminal_capabilities
assert_eq "${runtime_cap_cursor_positioning}" "1" "cursor positioning should stay available in degraded profile"
assert_eq "${runtime_cap_clear_screen}" "0" "clear capability should be marked unavailable"
assert_eq "${runtime_cap_cursor_visibility}" "1" "cursor visibility should remain available"
assert_eq "${runtime_terminal_supports_minimum}" "0" "minimum capability flag should fail when any required capability is missing"
assert_eq "${runtime_color_capacity}" "16" "color capacity should fallback to 16"

runtime_is_tty() {
  return 1
}

runtime_detect_terminal_capabilities
assert_eq "${runtime_terminal_supports_minimum}" "0" "non-tty session should not report minimum capabilities"
assert_eq "${runtime_color_capacity}" "16" "non-tty session should keep base color profile"

printf "PASS: runtime terminal capabilities tests\n"
