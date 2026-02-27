#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"

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

test_config_file="$(mktemp)"
cat > "${test_config_file}" <<'CFG'

# comentario inicial
 theme.menu.fg = 15

theme.menu.bg=4
app.language = pt
literal.with.equals = foo=bar=baz
CFG

config_loader_load_file "${test_config_file}"
assert_eq "${CONFIG_RAW[theme.menu.fg]}" "15" "parser should trim value"
assert_eq "${CONFIG_RAW[theme.menu.bg]}" "4" "parser should parse plain key=value"
assert_eq "${CONFIG_RAW[app.language]}" "pt" "parser should trim key and value"
assert_eq "${CONFIG_RAW[literal.with.equals]}" "foo=bar=baz" "parser should keep additional equals in value"

bad_config_file="$(mktemp)"
cat > "${bad_config_file}" <<'CFG'
valid.key=value
invalid line
CFG

set +o errexit
config_loader_load_file "${bad_config_file}"
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "parser should fail on malformed lines"
assert_eq "${config_loader_last_error}" "config_loader: invalid line 2: missing '='" "parser should expose line error"

missing_path="${bad_config_file}.missing"
set +o errexit
config_loader_load_file "${missing_path}"
rc="$?"
set -o errexit
assert_rc "${rc}" 1 "loader should fail when file is missing"

rm -f "${test_config_file}" "${bad_config_file}"
printf "PASS: config loader parser tests\n"
