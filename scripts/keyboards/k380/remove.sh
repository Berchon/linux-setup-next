#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly DEVICE_ID="k380"
readonly STATE_FILE_DEFAULT="/tmp/linux-setup-next-${DEVICE_ID}.state"
state_file="${LSN_STATE_FILE_OVERRIDE:-${STATE_FILE_DEFAULT}}"
confirmation_token="${1:-}"

if [[ ! -f "${state_file}" ]]; then
  printf '%s already removed\n' "${DEVICE_ID}"
  exit 0
fi

if [[ "${confirmation_token}" != "--confirm" ]]; then
  printf '%s confirmation required for remove (--confirm)\n' "${DEVICE_ID}" >&2
  exit 2
fi

rm -f "${state_file}"
printf '%s removed\n' "${DEVICE_ID}"
