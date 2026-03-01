#!/usr/bin/env bash

# Normalized configuration used at runtime.
declare -gA CONFIG_VALUES=()
declare -ga CONFIG_SCHEMA_KEYS=()
declare -gA CONFIG_SCHEMA_DEFAULTS=()
declare -gA CONFIG_SCHEMA_TYPES=()
declare -gA CONFIG_SCHEMA_ENUMS=()
declare -gA CONFIG_SCHEMA_MIN=()
declare -gA CONFIG_SCHEMA_MAX=()

declare -ga config_schema_warnings=()
declare -g config_schema_initialized=0

config_schema_reset_values() {
  CONFIG_VALUES=()
  config_schema_warnings=()
}

config_schema_define_key() {
  local key="$1"
  local default_value="$2"
  local value_type="$3"
  local enum_values="$4"
  local min_value="$5"
  local max_value="$6"

  CONFIG_SCHEMA_KEYS+=("${key}")
  CONFIG_SCHEMA_DEFAULTS["${key}"]="${default_value}"
  CONFIG_SCHEMA_TYPES["${key}"]="${value_type}"
  CONFIG_SCHEMA_ENUMS["${key}"]="${enum_values}"
  CONFIG_SCHEMA_MIN["${key}"]="${min_value}"
  CONFIG_SCHEMA_MAX["${key}"]="${max_value}"
}

config_schema_init() {
  if [[ "${config_schema_initialized}" -eq 1 ]]; then
    return 0
  fi

  config_schema_initialized=1

  config_schema_define_key "theme.wallpaper.enabled" "true" "bool" "" "" ""
  config_schema_define_key "theme.wallpaper.fg" "7" "int" "" "0" "255"
  config_schema_define_key "theme.wallpaper.bg" "0" "int" "" "0" "255"
  config_schema_define_key "theme.menu.fg" "15" "int" "" "0" "255"
  config_schema_define_key "theme.menu.bg" "4" "int" "" "0" "255"
  config_schema_define_key "theme.menu.border_style" "single" "enum" "none|single|double" "" ""
  config_schema_define_key "theme.menu.shadow.enabled" "true" "bool" "" "" ""
  config_schema_define_key "theme.modal.fg" "15" "int" "" "0" "255"
  config_schema_define_key "theme.modal.bg" "0" "int" "" "0" "255"
  config_schema_define_key "theme.modal.border_style" "single" "enum" "none|single|double" "" ""
  config_schema_define_key "theme.modal.shadow.enabled" "true" "bool" "" "" ""
  config_schema_define_key "theme.toast.fg" "0" "int" "" "0" "255"
  config_schema_define_key "theme.toast.bg" "3" "int" "" "0" "255"
  config_schema_define_key "theme.toast.border_style" "single" "enum" "none|single|double" "" ""
  config_schema_define_key "theme.toast.shadow.enabled" "true" "bool" "" "" ""
  config_schema_define_key "theme.toast.ttl_ms" "2500" "int" "" "100" "60000"
  config_schema_define_key "theme.header.fg" "9" "int" "" "0" "255"
  config_schema_define_key "theme.header.bg" "15" "int" "" "0" "255"
  config_schema_define_key "theme.footer.fg" "15" "int" "" "0" "255"
  config_schema_define_key "theme.footer.bg" "0" "int" "" "0" "255"
  config_schema_define_key "app.language" "pt" "enum" "pt|en" "" ""
}

config_schema_warn() {
  local message="$1"
  config_schema_warnings+=("${message}")
}

config_schema_validate_bool() {
  local value="$1"

  case "${value}" in
    true|TRUE|1|yes|YES)
      printf 'true'
      return 0
      ;;
    false|FALSE|0|no|NO)
      printf 'false'
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

config_schema_validate_int() {
  local value="$1"
  local min_value="$2"
  local max_value="$3"

  if [[ ! "${value}" =~ ^-?[0-9]+$ ]]; then
    return 1
  fi

  if [[ -n "${min_value}" ]] && (( value < min_value )); then
    return 1
  fi

  if [[ -n "${max_value}" ]] && (( value > max_value )); then
    return 1
  fi

  printf '%s' "${value}"
}

config_schema_validate_enum() {
  local value="$1"
  local enum_values="$2"

  local allowed=""
  IFS='|' read -r -a allowed <<< "${enum_values}"

  for allowed in "${allowed[@]}"; do
    if [[ "${value}" == "${allowed}" ]]; then
      printf '%s' "${value}"
      return 0
    fi
  done

  return 1
}

config_schema_validate_value() {
  local key="$1"
  local value="$2"
  local value_type="${CONFIG_SCHEMA_TYPES[${key}]}"
  local enum_values="${CONFIG_SCHEMA_ENUMS[${key}]}"
  local min_value="${CONFIG_SCHEMA_MIN[${key}]}"
  local max_value="${CONFIG_SCHEMA_MAX[${key}]}"

  case "${value_type}" in
    bool)
      config_schema_validate_bool "${value}"
      ;;
    int)
      config_schema_validate_int "${value}" "${min_value}" "${max_value}"
      ;;
    enum)
      config_schema_validate_enum "${value}" "${enum_values}"
      ;;
    *)
      return 1
      ;;
  esac
}

config_schema_resolve_from_raw() {
  local key=""
  local raw_value=""
  local normalized_value=""

  config_schema_init
  config_schema_reset_values

  for key in "${CONFIG_SCHEMA_KEYS[@]}"; do
    raw_value="${CONFIG_RAW[${key}]-}"

    if [[ -z "${raw_value}" ]]; then
      CONFIG_VALUES["${key}"]="${CONFIG_SCHEMA_DEFAULTS[${key}]}"
      continue
    fi

    if normalized_value="$(config_schema_validate_value "${key}" "${raw_value}")"; then
      CONFIG_VALUES["${key}"]="${normalized_value}"
    else
      CONFIG_VALUES["${key}"]="${CONFIG_SCHEMA_DEFAULTS[${key}]}"
      config_schema_warn "config_schema: invalid value for '${key}', using default"
    fi
  done

  return 0
}

config_schema_get_value() {
  local key="$1"
  local fallback="${2:-}"

  if [[ -v "CONFIG_VALUES[${key}]" ]]; then
    printf '%s' "${CONFIG_VALUES[${key}]}"
    return 0
  fi

  printf '%s' "${fallback}"
  return 0
}

config_schema_set_value() {
  local key="$1"
  local raw_value="$2"
  local normalized_value=""

  config_schema_init

  if [[ ! -v "CONFIG_SCHEMA_DEFAULTS[${key}]" ]]; then
    return 1
  fi

  if ! normalized_value="$(config_schema_validate_value "${key}" "${raw_value}")"; then
    return 1
  fi

  CONFIG_VALUES["${key}"]="${normalized_value}"
}
