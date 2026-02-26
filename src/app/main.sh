#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/app/bootstrap.sh
source "${APP_DIR}/bootstrap.sh"

cleanup_ran=0

cleanup() {
  if [[ "${cleanup_ran}" -eq 1 ]]; then
    return 0
  fi

  cleanup_ran=1
  if declare -F runtime_shutdown >/dev/null 2>&1; then
    runtime_shutdown
  fi
}

on_interrupt() {
  cleanup
  exit 130
}

on_terminate() {
  cleanup
  exit 143
}

main() {
  bootstrap_load_default_modules
  runtime_init
  printf 'linux-setup-next: bootstrap ready\n'
}

trap cleanup EXIT
trap on_interrupt INT
trap on_terminate TERM

main "$@"
