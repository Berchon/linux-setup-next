#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/app/bootstrap.sh
source "${APP_DIR}/bootstrap.sh"

main() {
  bootstrap_load_default_modules

  if ! ui_state_boot_config; then
    printf '%s\n' "${ui_state_last_error}" >&2
    return 1
  fi

  runtime_install_signal_traps
  runtime_init

  printf 'linux-setup-next: bootstrap ready\n'
  app_shell_run
}

main "$@"
