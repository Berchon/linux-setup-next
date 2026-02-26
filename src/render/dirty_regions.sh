#!/usr/bin/env bash

dirty_regions_screen_width=0
dirty_regions_screen_height=0

declare -ag dirty_regions_xs=()
declare -ag dirty_regions_ys=()
declare -ag dirty_regions_widths=()
declare -ag dirty_regions_heights=()

dirty_regions_is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

dirty_regions_is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

dirty_regions_is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

dirty_regions_reset() {
  dirty_regions_xs=()
  dirty_regions_ys=()
  dirty_regions_widths=()
  dirty_regions_heights=()
}

dirty_regions_init() {
  local screen_width="$1"
  local screen_height="$2"

  if ! dirty_regions_is_positive_integer "${screen_width}" || ! dirty_regions_is_positive_integer "${screen_height}"; then
    printf "dirty_regions: invalid viewport '%s'x'%s'\n" "${screen_width}" "${screen_height}" >&2
    return 1
  fi

  dirty_regions_screen_width="${screen_width}"
  dirty_regions_screen_height="${screen_height}"
  dirty_regions_reset
}

dirty_regions_count() {
  printf '%s\n' "${#dirty_regions_xs[@]}"
}

dirty_regions_get() {
  local index="$1"

  if ! dirty_regions_is_non_negative_integer "${index}"; then
    return 1
  fi

  if ((index >= ${#dirty_regions_xs[@]})); then
    return 1
  fi

  printf '%s|%s|%s|%s\n' \
    "${dirty_regions_xs[index]}" \
    "${dirty_regions_ys[index]}" \
    "${dirty_regions_widths[index]}" \
    "${dirty_regions_heights[index]}"
}

dirty_regions_add() {
  local x="$1"
  local y="$2"
  local width="$3"
  local height="$4"
  local index=0

  if ! dirty_regions_is_integer "${x}" || ! dirty_regions_is_integer "${y}"; then
    return 1
  fi

  if ! dirty_regions_is_non_negative_integer "${width}" || ! dirty_regions_is_non_negative_integer "${height}"; then
    return 1
  fi

  if ((width == 0 || height == 0)); then
    return 0
  fi

  index="${#dirty_regions_xs[@]}"
  dirty_regions_xs[index]="${x}"
  dirty_regions_ys[index]="${y}"
  dirty_regions_widths[index]="${width}"
  dirty_regions_heights[index]="${height}"
}
