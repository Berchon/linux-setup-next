#!/usr/bin/env bash

theme_config_get_bool() {
  local key="$1"
  local fallback="$2"
  local value=""

  value="$(config_schema_get_value "${key}" "${fallback}")"
  if [[ "${value}" == "true" ]]; then
    printf '1\n'
    return 0
  fi

  printf '0\n'
}

theme_config_get_int() {
  local key="$1"
  local fallback="$2"

  config_schema_get_value "${key}" "${fallback}"
}

theme_config_wallpaper_enabled() {
  theme_config_get_bool "theme.wallpaper.enabled" "true"
}

theme_config_wallpaper_fg() {
  theme_config_get_int "theme.wallpaper.fg" "7"
}

theme_config_wallpaper_bg() {
  theme_config_get_int "theme.wallpaper.bg" "0"
}
