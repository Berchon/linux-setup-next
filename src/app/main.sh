#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/app/bootstrap.sh
source "${APP_DIR}/bootstrap.sh"

main() {
  bootstrap_load_default_modules
  runtime_install_signal_traps
  runtime_init
  printf 'linux-setup-next: bootstrap ready\n'
}

main "$@"
