#!/usr/bin/env bash

# Raw key/value pairs loaded from config file.
declare -gA CONFIG_RAW=()

declare -g config_loader_last_error=""

config_loader_reset_raw() {
  CONFIG_RAW=()
  config_loader_last_error=""
}

config_loader_trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "${value}"
}

config_loader_parse_line() {
  local line="$1"
  local line_number="$2"
  local key=""
  local value=""

  line="$(config_loader_trim "${line}")"

  if [[ -z "${line}" ]] || [[ "${line:0:1}" == "#" ]]; then
    return 0
  fi

  if [[ "${line}" != *"="* ]]; then
    config_loader_last_error="config_loader: invalid line ${line_number}: missing '='"
    return 1
  fi

  key="$(config_loader_trim "${line%%=*}")"
  value="$(config_loader_trim "${line#*=}")"

  if [[ -z "${key}" ]]; then
    config_loader_last_error="config_loader: invalid line ${line_number}: empty key"
    return 1
  fi

  CONFIG_RAW["${key}"]="${value}"
  return 0
}

config_loader_load_file() {
  local config_path="$1"
  local line=""
  local line_number=0

  config_loader_reset_raw

  if [[ ! -f "${config_path}" ]]; then
    config_loader_last_error="config_loader: missing config file '${config_path}'"
    return 1
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_number=$((line_number + 1))

    if ! config_loader_parse_line "${line}" "${line_number}"; then
      return 1
    fi
  done < "${config_path}"

  return 0
}
