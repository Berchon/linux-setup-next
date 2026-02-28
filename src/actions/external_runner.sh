#!/usr/bin/env bash

readonly EXTERNAL_RUNNER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR="${EXTERNAL_RUNNER_ROOT}/scripts"

declare -g external_runner_allowed_dir="${EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR}"
declare -g external_runner_last_error=""
declare -g external_runner_last_rc=0
declare -g external_runner_last_timed_out=0
declare -g external_runner_last_severity="info"
declare -g external_runner_last_optional_dependency_missing=0
declare -g external_runner_last_stdout=""
declare -g external_runner_last_stderr=""
declare -gA external_runner_reference_scripts=()

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
  external_runner_last_severity="info"
  external_runner_last_optional_dependency_missing=0
  external_runner_last_stdout=""
  external_runner_last_stderr=""
  external_runner_allowed_dir="${EXTERNAL_RUNNER_DEFAULT_ALLOWED_DIR}"
}

external_runner_register_reference_device() {
  local device="$1"
  local install_script="$2"
  local remove_script="$3"
  local status_script="$4"
  local normalized_device=""

  normalized_device="${device,,}"
  if [[ ! "${normalized_device}" =~ ^[a-z0-9_-]+$ ]]; then
    external_runner_last_error="external_runner: invalid reference device '${device}'"
    return 1
  fi

  if [[ -z "${install_script}" || -z "${remove_script}" || -z "${status_script}" ]]; then
    external_runner_last_error="external_runner: incomplete script mapping for '${normalized_device}'"
    return 1
  fi

  external_runner_reference_scripts["${normalized_device}.install"]="${install_script}"
  external_runner_reference_scripts["${normalized_device}.remove"]="${remove_script}"
  external_runner_reference_scripts["${normalized_device}.status"]="${status_script}"
}

external_runner_resolve_reference_script() {
  local device="$1"
  local action="$2"
  local normalized_device=""
  local normalized_action=""
  local map_key=""
  local script_relpath=""

  normalized_device="${device,,}"
  normalized_action="${action,,}"
  map_key="${normalized_device}.${normalized_action}"

  case "${normalized_action}" in
    install|remove|status)
      ;;
    *)
      external_runner_last_error="external_runner: unsupported action '${action}'"
      return 1
      ;;
  esac

  script_relpath="${external_runner_reference_scripts[${map_key}]:-}"
  if [[ -z "${script_relpath}" ]]; then
    external_runner_last_error="external_runner: unsupported reference device '${device}'"
    return 1
  fi

  printf '%s' "${script_relpath}"
}

external_runner_run_reference_action() {
  local device="$1"
  local action="$2"
  local timeout_seconds="$3"
  shift 3
  local script_relpath=""

  script_relpath="$(external_runner_resolve_reference_script "${device}" "${action}")" || return 1
  external_runner_run_action "${action}" "${script_relpath}" "${timeout_seconds}" "$@"
}

external_runner_init_reference_actions() {
  external_runner_reference_scripts=()
  external_runner_register_reference_device \
    "k380" \
    "keyboards/k380/install.sh" \
    "keyboards/k380/remove.sh" \
    "keyboards/k380/status.sh"
  external_runner_register_reference_device \
    "k270" \
    "keyboards/k270/install.sh" \
    "keyboards/k270/remove.sh" \
    "keyboards/k270/status.sh"
}

external_runner_init_reference_actions

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
  external_runner_last_severity="info"
  external_runner_last_optional_dependency_missing=0

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

external_runner_map_exit_code_to_severity() {
  local action="$1"
  local rc="$2"
  local timed_out="${3:-0}"
  local severity="error"

  if [[ "${timed_out}" == "1" || "${rc}" -eq 124 ]]; then
    severity="error"
  elif external_runner_is_optional_dependency_missing "${rc}" "${external_runner_last_stderr}" "${external_runner_last_error}"; then
    severity="warn"
  elif [[ "${action}" == "status" ]]; then
    case "${rc}" in
      0) severity="info" ;;
      1|127) severity="warn" ;;
      *) severity="error" ;;
    esac
  else
    case "${rc}" in
      0) severity="success" ;;
      127) severity="warn" ;;
      *) severity="error" ;;
    esac
  fi

  external_runner_last_severity="${severity}"
  REPLY="${severity}"
  printf '%s' "${severity}"
}

external_runner_is_optional_dependency_missing() {
  local rc="$1"
  local stderr_text="${2:-}"
  local error_text="${3:-}"
  local combined_text=""

  if [[ "${rc}" -eq 127 ]]; then
    return 0
  fi

  combined_text="${stderr_text}"$'\n'"${error_text}"
  combined_text="${combined_text,,}"

  if [[ "${combined_text}" == *"command not found"* ]]; then
    return 0
  fi

  if [[ "${combined_text}" == *"dependency not available"* ]]; then
    return 0
  fi

  return 1
}

external_runner_build_result_message() {
  local action="$1"
  local rc="$2"
  local detail=""

  if [[ -n "${external_runner_last_error}" ]]; then
    detail="${external_runner_last_error}"
  elif [[ -n "${external_runner_last_stderr}" ]]; then
    detail="${external_runner_last_stderr%%$'\n'*}"
  elif [[ -n "${external_runner_last_stdout}" ]]; then
    detail="${external_runner_last_stdout%%$'\n'*}"
  else
    detail="exit code ${rc}"
  fi

  printf '%s: %s' "${action}" "${detail}"
}

external_runner_present_result() {
  local action="$1"
  local rc="${2:-${external_runner_last_rc}}"
  local timed_out="${3:-${external_runner_last_timed_out}}"
  local severity=""
  local title=""
  local message=""

  external_runner_map_exit_code_to_severity "${action}" "${rc}" "${timed_out}" >/dev/null
  severity="${REPLY}"
  message="$(external_runner_build_result_message "${action}" "${rc}")"
  title="External action: ${action} (${severity})"

  case "${action}" in
    status)
      if declare -F toast_state_enqueue >/dev/null; then
        toast_state_enqueue "${severity}" "${message}"
      fi
      ;;
    install|remove)
      if declare -F modal_state_open_text >/dev/null; then
        modal_state_open_text "${title}" "${message}"
      elif declare -F toast_state_enqueue >/dev/null; then
        toast_state_enqueue "${severity}" "${message}"
      fi
      ;;
    *)
      if declare -F toast_state_enqueue >/dev/null; then
        toast_state_enqueue "${severity}" "${message}"
      fi
      ;;
  esac

  REPLY="${severity}|${message}"
  printf '%s' "${REPLY}"
}

external_runner_run_action() {
  local action="$1"
  local script_input="$2"
  local timeout_seconds="$3"
  shift 3
  local rc=0

  if external_runner_run_script "${script_input}" "${timeout_seconds}" "$@"; then
    rc=0
  else
    rc="$?"
  fi

  external_runner_last_optional_dependency_missing=0
  if external_runner_is_optional_dependency_missing "${rc}" "${external_runner_last_stderr}" "${external_runner_last_error}"; then
    external_runner_last_optional_dependency_missing=1
  fi

  external_runner_present_result "${action}" "${rc}" "${external_runner_last_timed_out}" >/dev/null

  if [[ "${external_runner_last_optional_dependency_missing}" -eq 1 ]]; then
    return 0
  fi

  return "${rc}"
}
