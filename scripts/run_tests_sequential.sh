#!/usr/bin/env bash

set -o nounset
set -o pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TESTS_DIR="${ROOT_DIR}/tests"
readonly -a TEST_GROUP_ORDER=(unit component integration e2e perf)

verbose=0
stop_on_fail=0
filter=""

declare -a discovered_tests=()
declare -a selected_tests=()
declare -a failed_tests=()

if [[ -t 1 ]]; then
  readonly COLOR_GREEN=$'\033[32m'
  readonly COLOR_RED=$'\033[31m'
  readonly COLOR_RESET=$'\033[0m'
else
  readonly COLOR_GREEN=""
  readonly COLOR_RED=""
  readonly COLOR_RESET=""
fi

usage() {
  cat <<'USAGE'
Usage: scripts/run_tests_sequential.sh [options]

Options:
  --verbose          Show full output for passing tests too
  --stop-on-fail     Stop execution at the first failing test
  --filter <text>    Run only tests whose path contains <text>
  --help             Show this help
USAGE
}

percentage() {
  local done="$1"
  local total="$2"

  awk -v done="${done}" -v total="${total}" 'BEGIN {
    if (total == 0) {
      printf "0.0"
      exit
    }

    printf "%.1f", (done * 100) / total
  }'
}

discover_tests_from_dir() {
  local dir_path="$1"

  if [[ ! -d "${dir_path}" ]]; then
    return 0
  fi

  while IFS= read -r test_path; do
    discovered_tests+=("${test_path}")
  done < <(find "${dir_path}" -type f -name '*_test.sh' | sort)
}

is_in_known_group_dir() {
  local test_path="$1"
  local group=""

  for group in "${TEST_GROUP_ORDER[@]}"; do
    if [[ "${test_path}" == "${TESTS_DIR}/${group}/"* ]]; then
      return 0
    fi
  done

  return 1
}

relative_test_path() {
  local absolute_path="$1"
  printf '%s\n' "${absolute_path#"${ROOT_DIR}/"}"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --verbose)
        verbose=1
        ;;
      --stop-on-fail)
        stop_on_fail=1
        ;;
      --filter)
        shift
        if (($# == 0)); then
          printf 'ERROR: --filter requires a value\n' >&2
          return 1
        fi
        filter="$1"
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        printf 'ERROR: unknown option: %s\n' "$1" >&2
        usage >&2
        return 1
        ;;
    esac

    shift
  done
}

run_all_tests() {
  local index=0
  local current=0
  local remaining=0
  local total=0
  local passed=0
  local failed=0
  local executed=0
  local started_percent=""
  local completed_percent=""
  local test_path=""
  local test_rel_path=""
  local output_file=""
  local start_time=0
  local end_time=0
  local duration_seconds=0

  parse_args "$@" || return 1

  for group in "${TEST_GROUP_ORDER[@]}"; do
    discover_tests_from_dir "${TESTS_DIR}/${group}"
  done

  while IFS= read -r test_path; do
    if ! is_in_known_group_dir "${test_path}"; then
      discovered_tests+=("${test_path}")
    fi
  done < <(find "${TESTS_DIR}" -type f -name '*_test.sh' | sort)

  if ((${#discovered_tests[@]} == 0)); then
    printf 'No tests found under %s\n' "${TESTS_DIR}" >&2
    return 1
  fi

  if [[ -n "${filter}" ]]; then
    for test_path in "${discovered_tests[@]}"; do
      if [[ "${test_path}" == *"${filter}"* ]]; then
        selected_tests+=("${test_path}")
      fi
    done
  else
    selected_tests=("${discovered_tests[@]}")
  fi

  total="${#selected_tests[@]}"
  if ((total == 0)); then
    printf 'No tests matched the current filter\n' >&2
    return 1
  fi

  printf 'Running %s test(s) in sequence\n' "${total}"

  for ((index = 0; index < total; index++)); do
    current=$((index + 1))
    remaining=$((total - current))
    started_percent="$(percentage "$((current - 1))" "${total}")"
    test_path="${selected_tests[${index}]}"
    test_rel_path="$(relative_test_path "${test_path}")"

    printf '[RUN] [%d/%d] %s%% done | remaining: %d | %s\n' "${current}" "${total}" "${started_percent}" "${remaining}" "${test_rel_path}"

    output_file="$(mktemp)"
    start_time="$(date +%s)"

    if bash "${test_path}" >"${output_file}" 2>&1; then
      passed=$((passed + 1))
      end_time="$(date +%s)"
      duration_seconds=$((end_time - start_time))
      completed_percent="$(percentage "${current}" "${total}")"
      printf '%s[OK ]%s [%d/%d] %s (%ss) | %s%% done | remaining: %d\n' "${COLOR_GREEN}" "${COLOR_RESET}" "${current}" "${total}" "${test_rel_path}" "${duration_seconds}" "${completed_percent}" "${remaining}"

      if ((verbose == 1)); then
        sed 's/^/      /' "${output_file}"
      fi
    else
      failed=$((failed + 1))
      end_time="$(date +%s)"
      duration_seconds=$((end_time - start_time))
      completed_percent="$(percentage "${current}" "${total}")"
      printf '%s[FAIL]%s [%d/%d] %s (%ss) | %s%% done | remaining: %d\n' "${COLOR_RED}" "${COLOR_RESET}" "${current}" "${total}" "${test_rel_path}" "${duration_seconds}" "${completed_percent}" "${remaining}"
      failed_tests+=("${test_rel_path}")
      sed 's/^/      /' "${output_file}"

      if ((stop_on_fail == 1)); then
        rm -f "${output_file}"
        executed=$((passed + failed))
        break
      fi
    fi

    rm -f "${output_file}"
  done

  if ((stop_on_fail == 1)); then
    executed=$((passed + failed))
  else
    executed="${total}"
  fi

  remaining=$((total - executed))

  printf '\nSummary\n'
  printf '  Total planned: %d\n' "${total}"
  printf '  Executed:      %d\n' "${executed}"
  printf '  Passed:        %d\n' "${passed}"
  printf '  Failed:        %d\n' "${failed}"
  printf '  Remaining:     %d\n' "${remaining}"
  printf '  Progress:      %s%%\n' "$(percentage "${executed}" "${total}")"
  printf '  Success rate:  %s%%\n' "$(percentage "${passed}" "${total}")"

  if ((${#failed_tests[@]} > 0)); then
    printf '  Failing tests:\n'
    for test_rel_path in "${failed_tests[@]}"; do
      printf '    - %s\n' "${test_rel_path}"
    done
  fi

  if ((failed > 0)); then
    return 1
  fi

  return 0
}

run_all_tests "$@"
