#!/usr/bin/env bash

readonly EXTERNAL_RUNNER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR="${EXTERNAL_RUNNER_ROOT}/scripts"

declare -g external_runner_allowed_dir="${EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR}"
declare -g external_runner_last_error=""

external_runner__canonicalize_dir() {
  local dir_path="$1"

  if [[ -z "${dir_path}" ]]; then
    return 1
  fi

  (
    cd "${dir_path}" 2>/dev/null && pwd
  )
}

external_runner__canonicalize_file() {
  local file_path="$1"
  local file_dir=""
  local file_name=""
  local canonical_dir=""

  if [[ -z "${file_path}" ]]; then
    return 1
  fi

  file_dir="$(dirname -- "${file_path}")"
  file_name="$(basename -- "${file_path}")"

  canonical_dir="$(external_runner__canonicalize_dir "${file_dir}")" || return 1
  printf '%s/%s' "${canonical_dir}" "${file_name}"
}

external_runner_reset() {
  external_runner_last_error=""
  external_runner_allowed_dir="${EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR}"
}

external_runner_set_allowed_dir() {
  local dir_path="$1"
  local canonical_dir=""

  canonical_dir="$(external_runner__canonicalize_dir "${dir_path}")" || {
    external_runner_last_error="external_runner: invalid allowed directory '${dir_path}'"
    return 1
  }

  external_runner_allowed_dir="${canonical_dir}"
  return 0
}

external_runner_resolve_script_path() {
  local script_input="$1"
  local candidate_path=""
  local resolved_path=""

  external_runner_last_error=""

  if [[ -z "${script_input}" ]]; then
    external_runner_last_error="external_runner: script path is required"
    return 1
  fi

  if [[ "${script_input}" == /* ]]; then
    candidate_path="${script_input}"
  else
    candidate_path="${external_runner_allowed_dir}/${script_input}"
  fi

  resolved_path="$(external_runner__canonicalize_file "${candidate_path}")" || {
    external_runner_last_error="external_runner: unable to resolve script path '${script_input}'"
    return 1
  }

  case "${resolved_path}" in
    "${external_runner_allowed_dir}"/*)
      ;;
    *)
      external_runner_last_error="external_runner: script path is outside allowed directory: ${script_input}"
      return 1
      ;;
  esac

  if [[ ! -f "${resolved_path}" ]]; then
    external_runner_last_error="external_runner: script not found: ${script_input}"
    return 1
  fi

  printf '%s' "${resolved_path}"
  return 0
}
