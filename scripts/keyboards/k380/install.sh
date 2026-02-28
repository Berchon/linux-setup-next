#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly DEVICE_ID="k380"
readonly STATE_FILE_DEFAULT="/tmp/linux-setup-next-${DEVICE_ID}.state"
state_file="${LSN_STATE_FILE_OVERRIDE:-${STATE_FILE_DEFAULT}}"

mkdir -p "$(dirname "${state_file}")"
if [[ -f "${state_file}" ]]; then
  printf '%s already installed\n' "${DEVICE_ID}"
  exit 0
fi

printf 'installed\n' > "${state_file}"
printf '%s installed\n' "${DEVICE_ID}"
