#!/usr/bin/env bash

readonly EXTERNAL_RUNNER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR="${EXTERNAL_RUNNER_ROOT}/scripts"

declare -g external_runner_allowed_dir="${EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR}"
declare -g external_runner_last_error=""
declare -g external_runner_last_rc=0
declare -g external_runner_last_timed_out=0
declare -g external_runner_last_stdout=""
declare -g external_runner_last_stderr=""

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
  external_runner_last_rc=0
  external_runner_last_timed_out=0
  external_runner_last_stdout=""
  external_runner_last_stderr=""
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

external_runner_has_timeout_command() {
  command -v timeout >/dev/null 2>&1
}

external_runner_timeout_command() {
  timeout --signal=TERM --kill-after=1 "$@"
}

external_runner_execute_with_timeout() {
  local script_input="$1"
  local timeout_seconds="$2"
  shift 2
  local resolved_script=""
  local rc=0

  external_runner_last_error=""
  external_runner_last_rc=0
  external_runner_last_timed_out=0

  resolved_script="$(external_runner_resolve_script_path "${script_input}")" || return 1

  if [[ ! "${timeout_seconds}" =~ ^[1-9][0-9]*$ ]]; then
    external_runner_last_error="external_runner: timeout must be a positive integer"
    return 1
  fi

  if [[ ! -x "${resolved_script}" ]]; then
    external_runner_last_error="external_runner: script is not executable: ${script_input}"
    return 1
  fi

  if ! external_runner_has_timeout_command; then
    external_runner_last_error="external_runner: timeout command is unavailable"
    return 1
  fi

  external_runner_timeout_command "${timeout_seconds}" "${resolved_script}" "$@"
  rc="$?"

  if [[ "${rc}" -eq 0 ]]; then
    external_runner_last_rc=0
    return 0
  fi

  external_runner_last_rc="${rc}"

  if [[ "${rc}" -eq 124 ]]; then
    external_runner_last_timed_out=1
    external_runner_last_error="external_runner: execution timed out after ${timeout_seconds}s"
  fi

  return "${rc}"
}

external_runner_sanitize_output() {
  local raw_text="$1"
  local esc_char=""

  esc_char="$(printf '\033')"

  printf '%s' "${raw_text}" \
    | sed "s/${esc_char}\\[[0-9;]*m//g" \
    | sed "s/${esc_char}\\[[0-9;?]*[ -\/]*[@-~]//g" \
    | tr '\r' '\n' \
    | tr -d '\000-\010\013\014\016-\037\177'
}

external_runner_run_script() {
  local script_input="$1"
  local timeout_seconds="$2"
  shift 2
  local stdout_file=""
  local stderr_file=""
  local stdout_raw=""
  local stderr_raw=""
  local rc=0

  external_runner_last_stdout=""
  external_runner_last_stderr=""

  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  if external_runner_execute_with_timeout "${script_input}" "${timeout_seconds}" "$@" >"${stdout_file}" 2>"${stderr_file}"; then
    rc=0
  else
    rc="$?"
  fi

  stdout_raw="$(cat "${stdout_file}")"
  stderr_raw="$(cat "${stderr_file}")"
  rm -f "${stdout_file}" "${stderr_file}"

  external_runner_last_stdout="$(external_runner_sanitize_output "${stdout_raw}")"
  external_runner_last_stderr="$(external_runner_sanitize_output "${stderr_raw}")"

  return "${rc}"
}
