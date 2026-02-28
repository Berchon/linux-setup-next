#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly -a DEFAULT_MODULE_ORDER=(
  "config/config_loader.sh"
  "config/config_schema.sh"
  "config/config_store.sh"
  "config/theme_config.sh"
  "i18n/i18n.sh"
  "actions/external_runner.sh"
  "state/menu_state.sh"
  "state/config_menu_state.sh"
  "state/ui_state.sh"
  "core/runtime.sh"
)

bootstrap_load_modules_from_list() {
  local root_dir="$1"
  shift

  local module_relpath
  local module_abspath
  for module_relpath in "$@"; do
    module_abspath="${root_dir}/src/${module_relpath}"
    if [[ ! -f "${module_abspath}" ]]; then
      printf "bootstrap: missing module '%s'\n" "${module_relpath}" >&2
      return 1
    fi

    # shellcheck source=/dev/null
    source "${module_abspath}"
  done
}

bootstrap_load_default_modules() {
  bootstrap_load_modules_from_list "${BOOTSTRAP_ROOT}" "${DEFAULT_MODULE_ORDER[@]}"
}
