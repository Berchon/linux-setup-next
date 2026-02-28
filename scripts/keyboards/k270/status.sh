#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly DEVICE_ID="k270"
readonly STATE_FILE_DEFAULT="/tmp/linux-setup-next-${DEVICE_ID}.state"
state_file="${LSN_STATE_FILE_OVERRIDE:-${STATE_FILE_DEFAULT}}"

if [[ -f "${state_file}" ]]; then
  printf '%s installed\n' "${DEVICE_ID}"
  exit 0
fi

printf '%s not installed\n' "${DEVICE_ID}" >&2
exit 1
