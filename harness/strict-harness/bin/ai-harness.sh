#!/usr/bin/env bash
set -euo pipefail

VERSION="strict-harness v1"

usage() {
  cat <<'USAGE'
ai-harness - strict AI workflow harness

Usage:
  ai-harness help
  ai-harness init
  ai-harness smoke

  ai-harness g4-start \
    --objective "..." \
    --allowed path[,path] \
    --forbidden "..." \
    --verify "command" \
    --stop "..."

  ai-harness g4-status --packet <packet-id-or-path>

  ai-harness g4-close \
    --packet <packet-id-or-path> \
    --return-status DONE \
    --verification-status PASS \
    --verification-evidence path/to/evidence.log

  ai-harness g5-package --base <sha> --head <sha> [--scope path[,path]]
  ai-harness g5-review --package <review-package> [--cmd "reviewer command {package}"]

Environment:
  AI_DEV_PROJECT_ROOT   Project root. Defaults to git top-level or current directory.
  AI_DEV_DIR            Runtime root. Defaults to <project>/.ai-dev.
  AI_REVIEWER_CMD       Command used by g5-review. Use {package} as placeholder.
USAGE
}

die() {
  echo "BLOCKED: $*" >&2
  exit 2
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

trim() {
  local value="$*"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

append_csv_values() {
  local target_name="$1"
  local raw="$2"
  local item

  IFS=',' read -r -a split_values <<< "$raw"
  for item in "${split_values[@]}"; do
    item="$(trim "$item")"
    if [[ -n "$item" ]]; then
      eval "$target_name+=(\"\$item\")"
    fi
  done
}

require_arg_value() {
  local name="${1:-}"
  local value="${2:-}"
  if [[ -z "$value" || "$value" == --* ]]; then
    die "$name requires a value"
  fi
}

is_allowed_return_status() {
  case "$1" in
    DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED) return 0 ;;
    *) return 1 ;;
  esac
}

is_allowed_verification_status() {
  case "$1" in
    PASS|FAIL|SKIPPED) return 0 ;;
    *) return 1 ;;
  esac
}

timestamp_utc() {
  date -u +"%Y%m%dT%H%M%SZ"
}

script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

self_path() {
  local dir
  dir="$(script_dir)"
  printf '%s/%s\n' "$dir" "$(basename "${BASH_SOURCE[0]}")"
}

harness_home() {
  local dir
  dir="$(script_dir)"

  if [[ -d "$dir/../templates" ]]; then
    cd "$dir/.." && pwd
    return
  fi

  if [[ -d "$dir/../harness/strict-harness/templates" ]]; then
    cd "$dir/../harness/strict-harness" && pwd
    return
  fi

  echo ""
}

project_root() {
  if [[ -n "${AI_DEV_PROJECT_ROOT:-}" ]]; then
    cd "$AI_DEV_PROJECT_ROOT" && pwd
    return
  fi

  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
    return
  fi

  pwd
}

ai_dev_dir() {
  local root
  root="$(project_root)"
  echo "${AI_DEV_DIR:-$root/.ai-dev}"
}

runtime_dir() {
  echo "$(ai_dev_dir)/runtime"
}

artifact_dir() {
  echo "$(ai_dev_dir)/gate-artifacts"
}

g4_packet_dir() {
  echo "$(runtime_dir)/g4-packets"
}

review_package_dir() {
  echo "$(artifact_dir)/review-packages"
}

review_result_dir() {
  echo "$(artifact_dir)/reviews"
}

ensure_dirs() {
  mkdir -p "$(runtime_dir)" "$(artifact_dir)" "$(g4_packet_dir)" "$(review_package_dir)" "$(review_result_dir)"
}

require_git_repo() {
  local root
  root="$(project_root)"
  git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "project root is not a git repository: $root"
}

git_head_sha() {
  local root
  root="$(project_root)"
  git -C "$root" rev-parse HEAD
}

sanitize_id() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || die "id may contain only letters, numbers, dot, underscore, or dash: $value"
}

packet_path_from_id() {
  local packet="$1"
  if [[ -f "$packet" ]]; then
    printf '%s\n' "$packet"
    return
  fi

  if [[ "$packet" == */* || "$packet" == *\\* ]]; then
    die "packet not found: $packet"
  fi

  local candidate
  candidate="$(g4_packet_dir)/$packet.packet.md"
  [[ -f "$candidate" ]] || die "packet not found: $packet"
  printf '%s\n' "$candidate"
}

list_has_items() {
  local file="$1"
  local header="$2"
  awk -v header="$header" '
    $0 == header { in_list = 1; next }
    /^[A-Za-z0-9_]+:/ { in_list = 0 }
    in_list && /^- / { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

validate_packet_file() {
  local packet="$1"
  [[ -f "$packet" ]] || die "packet file does not exist: $packet"
  grep -q '^packet_version: 1$' "$packet" || die "packet is missing packet_version: $packet"
  grep -q '^packet_id: ' "$packet" || die "packet is missing packet_id: $packet"
  grep -q '^base_sha: ' "$packet" || die "packet is missing base_sha: $packet"
  grep -q '^status: ' "$packet" || die "packet is missing status: $packet"
  grep -q '^objective: ' "$packet" || die "packet is missing objective: $packet"
  grep -q '^verification_command: ' "$packet" || die "packet is missing verification_command: $packet"
  list_has_items "$packet" "allowed_files:" || die "packet has no allowed_files entries: $packet"
  list_has_items "$packet" "forbidden_scope:" || die "packet has no forbidden_scope entries: $packet"
  list_has_items "$packet" "stop_conditions:" || die "packet has no stop_conditions entries: $packet"
}

write_list() {
  local item
  for item in "$@"; do
    printf -- '- %s\n' "$item"
  done
}

cmd_init() {
  ensure_dirs
  echo "Initialized strict harness runtime at $(ai_dev_dir)"
}

cmd_g4_start() {
  local objective=""
  local verify_cmd=""
  local id=""
  local output=""
  local -a allowed_files=()
  local -a forbidden_scope=()
  local -a stop_conditions=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --objective)
        require_arg_value "$1" "${2:-}"
        objective="$2"
        shift 2
        ;;
      --allowed)
        require_arg_value "$1" "${2:-}"
        append_csv_values allowed_files "$2"
        shift 2
        ;;
      --forbidden)
        require_arg_value "$1" "${2:-}"
        append_csv_values forbidden_scope "$2"
        shift 2
        ;;
      --verify)
        require_arg_value "$1" "${2:-}"
        verify_cmd="$2"
        shift 2
        ;;
      --stop)
        require_arg_value "$1" "${2:-}"
        append_csv_values stop_conditions "$2"
        shift 2
        ;;
      --id)
        require_arg_value "$1" "${2:-}"
        id="$2"
        shift 2
        ;;
      --output)
        require_arg_value "$1" "${2:-}"
        output="$2"
        shift 2
        ;;
      *)
        die "unknown g4-start option: $1"
        ;;
    esac
  done

  [[ -n "$objective" ]] || die "g4-start requires --objective"
  [[ ${#allowed_files[@]} -gt 0 ]] || die "g4-start requires at least one --allowed entry"
  [[ ${#forbidden_scope[@]} -gt 0 ]] || die "g4-start requires at least one --forbidden entry"
  [[ -n "$verify_cmd" ]] || die "g4-start requires --verify"
  [[ ${#stop_conditions[@]} -gt 0 ]] || die "g4-start requires at least one --stop entry"

  require_git_repo
  ensure_dirs

  if [[ -z "$id" ]]; then
    id="g4-$(timestamp_utc)"
  fi
  sanitize_id "$id"

  if [[ -z "$output" ]]; then
    output="$(g4_packet_dir)/$id.packet.md"
  fi
  [[ ! -e "$output" ]] || die "packet already exists: $output"

  {
    echo "# G4 Subtask Execution Packet"
    echo
    echo "packet_version: 1"
    echo "packet_id: $id"
    echo "created_at_utc: $(timestamp_utc)"
    echo "project_root: $(project_root)"
    echo "base_sha: $(git_head_sha)"
    echo "status: OPEN"
    echo "objective: $objective"
    echo "verification_command: $verify_cmd"
    echo
    echo "allowed_files:"
    write_list "${allowed_files[@]}"
    echo
    echo "forbidden_scope:"
    write_list "${forbidden_scope[@]}"
    echo
    echo "stop_conditions:"
    write_list "${stop_conditions[@]}"
    echo
    echo "return_status_contract:"
    echo "- DONE"
    echo "- DONE_WITH_CONCERNS"
    echo "- NEEDS_CONTEXT"
    echo "- BLOCKED"
  } > "$output"

  validate_packet_file "$output"
  echo "$output"
}

cmd_g4_status() {
  local packet=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --packet)
        require_arg_value "$1" "${2:-}"
        packet="$2"
        shift 2
        ;;
      *)
        die "unknown g4-status option: $1"
        ;;
    esac
  done

  [[ -n "$packet" ]] || die "g4-status requires --packet"
  packet="$(packet_path_from_id "$packet")"
  validate_packet_file "$packet"
  grep -E '^(packet_id|created_at_utc|base_sha|status|objective|verification_command|return_status|verification_status|closed_at_utc): ' "$packet" || true
}

cmd_g4_close() {
  local packet=""
  local return_status=""
  local verification_status=""
  local verification_evidence=""
  local packet_file tmp_file

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --packet)
        require_arg_value "$1" "${2:-}"
        packet="$2"
        shift 2
        ;;
      --return-status)
        require_arg_value "$1" "${2:-}"
        return_status="$2"
        shift 2
        ;;
      --verification-status)
        require_arg_value "$1" "${2:-}"
        verification_status="$2"
        shift 2
        ;;
      --verification-evidence)
        require_arg_value "$1" "${2:-}"
        verification_evidence="$2"
        shift 2
        ;;
      *)
        die "unknown g4-close option: $1"
        ;;
    esac
  done

  [[ -n "$packet" ]] || die "g4-close requires --packet"
  [[ -n "$return_status" ]] || die "g4-close requires --return-status"
  [[ -n "$verification_status" ]] || die "g4-close requires --verification-status"
  is_allowed_return_status "$return_status" || die "invalid return status: $return_status"
  is_allowed_verification_status "$verification_status" || die "invalid verification status: $verification_status"

  packet_file="$(packet_path_from_id "$packet")"
  validate_packet_file "$packet_file"
  grep -q '^status: OPEN$' "$packet_file" || die "packet is not OPEN: $packet_file"

  if [[ "$return_status" == "DONE" && "$verification_status" != "PASS" ]]; then
    die "DONE requires --verification-status PASS"
  fi

  if [[ "$verification_status" == "PASS" ]]; then
    [[ -n "$verification_evidence" ]] || die "PASS requires --verification-evidence"
    [[ -f "$verification_evidence" ]] || die "verification evidence file does not exist: $verification_evidence"
  fi

  require_git_repo
  tmp_file="$packet_file.tmp.$$"
  awk '
    BEGIN { replaced = 0 }
    /^status: / && replaced == 0 {
      print "status: CLOSED"
      replaced = 1
      next
    }
    { print }
  ' "$packet_file" > "$tmp_file"

  {
    echo
    echo "## Closeout"
    echo
    echo "closed_at_utc: $(timestamp_utc)"
    echo "closed_head_sha: $(git_head_sha)"
    echo "return_status: $return_status"
    echo "verification_status: $verification_status"
    echo "verification_evidence: ${verification_evidence:-NOT_REQUIRED}"
  } >> "$tmp_file"

  mv "$tmp_file" "$packet_file"
  echo "$packet_file"
}

resolve_commit() {
  local root="$1"
  local ref="$2"
  git -C "$root" rev-parse --verify "${ref}^{commit}" 2>/dev/null || return 1
}

collect_diff_files() {
  local root="$1"
  local base="$2"
  local head="$3"
  shift 3
  git -C "$root" diff --name-only "$base..$head" -- "$@"
}

hash_stream() {
  git hash-object --stdin
}

cmd_g5_package() {
  local base=""
  local head="HEAD"
  local output=""
  local root
  local base_sha head_sha
  local -a scope_files=()
  local -a actual_diff_files=()
  local -a package_scope=()
  local tmp_dir diff_file body_file package_hash full_diff_hash file file_hash content_hash

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)
        require_arg_value "$1" "${2:-}"
        base="$2"
        shift 2
        ;;
      --head)
        require_arg_value "$1" "${2:-}"
        head="$2"
        shift 2
        ;;
      --scope)
        require_arg_value "$1" "${2:-}"
        append_csv_values scope_files "$2"
        shift 2
        ;;
      --output)
        require_arg_value "$1" "${2:-}"
        output="$2"
        shift 2
        ;;
      *)
        die "unknown g5-package option: $1"
        ;;
    esac
  done

  require_git_repo
  ensure_dirs
  root="$(project_root)"

  if [[ -z "$base" ]]; then
    if git -C "$root" rev-parse --verify "HEAD~1^{commit}" >/dev/null 2>&1; then
      base="HEAD~1"
    else
      die "g5-package requires --base when HEAD~1 is unavailable"
    fi
  fi

  base_sha="$(resolve_commit "$root" "$base")" || die "invalid --base commit: $base"
  head_sha="$(resolve_commit "$root" "$head")" || die "invalid --head commit: $head"
  [[ "$base_sha" != "$head_sha" ]] || die "BASE_SHA and HEAD_SHA must be different"

  if [[ ${#scope_files[@]} -gt 0 ]]; then
    while IFS= read -r file; do
      actual_diff_files+=("$file")
    done < <(collect_diff_files "$root" "$base_sha" "$head_sha" "${scope_files[@]}")
  else
    while IFS= read -r file; do
      actual_diff_files+=("$file")
    done < <(collect_diff_files "$root" "$base_sha" "$head_sha")
    scope_files=("${actual_diff_files[@]}")
  fi

  [[ ${#actual_diff_files[@]} -gt 0 ]] || die "review package has empty diff"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  printf '%s\n' "${scope_files[@]}" | sort > "$tmp_dir/scope.txt"
  printf '%s\n' "${actual_diff_files[@]}" | sort > "$tmp_dir/actual.txt"
  if ! cmp -s "$tmp_dir/scope.txt" "$tmp_dir/actual.txt"; then
    echo "scope_files:" >&2
    cat "$tmp_dir/scope.txt" >&2
    echo "actual_diff_files:" >&2
    cat "$tmp_dir/actual.txt" >&2
    die "scope_files must exactly match actual_diff_files"
  fi

  package_scope=("${actual_diff_files[@]}")
  diff_file="$tmp_dir/full.diff"
  git -C "$root" diff --binary --full-index "$base_sha..$head_sha" -- "${package_scope[@]}" > "$diff_file"
  [[ -s "$diff_file" ]] || die "full scoped diff is empty"
  full_diff_hash="$(git hash-object "$diff_file")"

  if [[ -z "$output" ]]; then
    output="$(review_package_dir)/g5-review-$(timestamp_utc).md"
  fi
  [[ ! -e "$output" ]] || die "review package already exists: $output"

  body_file="$tmp_dir/package-body.md"
  {
    echo "# G5 Review Evidence Package"
    echo
    echo "review_package_version: 1"
    echo "created_at_utc: $(timestamp_utc)"
    echo "project_root: $root"
    echo "BASE_SHA: $base_sha"
    echo "HEAD_SHA: $head_sha"
    echo "full_diff_hash: $full_diff_hash"
    echo "embedded_truncated: false"
    echo
    echo "scope_files:"
    write_list "${scope_files[@]}"
    echo
    echo "actual_diff_files:"
    write_list "${actual_diff_files[@]}"
    echo
    echo "## Per-File Diff Hashes"
    echo
    echo "| File | Diff Hash | HEAD Content Hash |"
    echo "|------|-----------|-------------------|"
    for file in "${actual_diff_files[@]}"; do
      file_hash="$(git -C "$root" diff --binary --full-index "$base_sha..$head_sha" -- "$file" | hash_stream)"
      if git -C "$root" cat-file -e "$head_sha:$file" 2>/dev/null; then
        content_hash="$(git -C "$root" show "$head_sha:$file" | hash_stream)"
      else
        content_hash="DELETED"
      fi
      echo "| $file | $file_hash | $content_hash |"
    done
    echo
    echo "## Reviewer Anti-Trust Rule"
    echo
    echo "Do not trust the implementer report. Review the actual diff, relevant code,"
    echo "and stated spec. Mark unchecked areas as NOT_CHECKED, UNCERTAIN, or OUT_OF_SCOPE."
    echo
    echo "## Full Scoped Diff"
    echo
    echo '```diff'
    cat "$diff_file"
    echo '```'
  } > "$body_file"

  package_hash="$(git hash-object "$body_file")"
  {
    echo "review_package_hash: $package_hash"
    cat "$body_file"
  } > "$output"

  grep -q '^embedded_truncated: false$' "$output" || die "review package truncation marker missing"
  grep -q '^BASE_SHA: ' "$output" || die "review package missing BASE_SHA"
  grep -q '^HEAD_SHA: ' "$output" || die "review package missing HEAD_SHA"
  echo "$output"
}

cmd_g5_review() {
  local package=""
  local reviewer_cmd="${AI_REVIEWER_CMD:-}"
  local tmp_dir output_file exit_code verdict command_to_run

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --package)
        require_arg_value "$1" "${2:-}"
        package="$2"
        shift 2
        ;;
      --cmd)
        require_arg_value "$1" "${2:-}"
        reviewer_cmd="$2"
        shift 2
        ;;
      *)
        die "unknown g5-review option: $1"
        ;;
    esac
  done

  [[ -n "$package" ]] || die "g5-review requires --package"
  [[ -f "$package" ]] || die "review package not found: $package"
  [[ -n "$reviewer_cmd" ]] || die "reviewer unavailable: set AI_REVIEWER_CMD or pass --cmd"

  ensure_dirs
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  output_file="$(review_result_dir)/g5-review-$(timestamp_utc).md"

  if [[ "$reviewer_cmd" == *"{package}"* ]]; then
    command_to_run="${reviewer_cmd//\{package\}/\"$package\"}"
  else
    command_to_run="$reviewer_cmd \"$package\""
  fi

  set +e
  bash -lc "$command_to_run" > "$tmp_dir/reviewer.out" 2> "$tmp_dir/reviewer.err"
  exit_code=$?
  set -e

  if [[ "$exit_code" -ne 0 ]]; then
    verdict="BLOCKED"
  elif grep -Eq '\bREJECT\b' "$tmp_dir/reviewer.out"; then
    verdict="REJECT"
  elif grep -Eq '\bBLOCKED\b' "$tmp_dir/reviewer.out"; then
    verdict="BLOCKED"
  elif grep -Eq '\bUNCERTAIN\b' "$tmp_dir/reviewer.out"; then
    verdict="UNCERTAIN"
  elif grep -Eq '\bPASS\b' "$tmp_dir/reviewer.out"; then
    verdict="PASS"
  else
    verdict="UNCERTAIN"
  fi

  {
    echo "# G5 Reviewer Result"
    echo
    echo "review_result_version: 1"
    echo "created_at_utc: $(timestamp_utc)"
    echo "package: $package"
    echo "reviewer_command: $reviewer_cmd"
    echo "reviewer_exit_code: $exit_code"
    echo "verdict: $verdict"
    echo
    echo "## stdout"
    echo
    echo '```text'
    cat "$tmp_dir/reviewer.out"
    echo '```'
    echo
    echo "## stderr"
    echo
    echo '```text'
    cat "$tmp_dir/reviewer.err"
    echo '```'
  } > "$output_file"

  echo "$output_file"
  case "$verdict" in
    PASS) exit 0 ;;
    REJECT) exit 1 ;;
    BLOCKED) exit 2 ;;
    UNCERTAIN) exit 3 ;;
  esac
}

expect_exit() {
  local expected="$1"
  local label="$2"
  shift 2
  set +e
  "$@" >/tmp/ai-harness-smoke.out 2>/tmp/ai-harness-smoke.err
  local code=$?
  set -e
  if [[ "$code" -ne "$expected" ]]; then
    echo "FAIL $label expected exit $expected got $code"
    cat /tmp/ai-harness-smoke.out || true
    cat /tmp/ai-harness-smoke.err || true
    return 1
  fi
  echo "PASS $label"
}

cmd_smoke() {
  local dir home failed tmp root self base head package evidence
  dir="$(ai_dev_dir)"
  home="$(harness_home)"
  failed=0

  echo "strict-harness smoke"
  echo "version: $VERSION"
  echo "ai_dev_dir: $dir"
  echo "harness_home: ${home:-NOT_FOUND}"

  cmd_init >/dev/null

  if [[ ! -d "$dir/runtime" ]]; then
    echo "FAIL runtime directory missing: $dir/runtime"
    failed=1
  else
    echo "PASS runtime directory exists"
  fi

  if [[ ! -d "$dir/gate-artifacts" ]]; then
    echo "FAIL gate artifact directory missing: $dir/gate-artifacts"
    failed=1
  else
    echo "PASS gate artifact directory exists"
  fi

  if [[ -z "$home" || ! -f "$home/templates/g4-packet.md" ]]; then
    echo "FAIL G4 packet template missing"
    failed=1
  else
    echo "PASS G4 packet template exists"
  fi

  if [[ -z "$home" || ! -f "$home/templates/review-package.md" ]]; then
    echo "FAIL review package template missing"
    failed=1
  else
    echo "PASS review package template exists"
  fi

  self="$(self_path)"
  tmp="$(mktemp -d)"
  root="$tmp/repo"
  mkdir -p "$root"
  git -C "$root" init -q
  git -C "$root" config user.email "ai-harness-smoke@example.invalid"
  git -C "$root" config user.name "AI Harness Smoke"
  echo "alpha" > "$root/app.txt"
  git -C "$root" add app.txt
  git -C "$root" commit -q -m "base"
  base="$(git -C "$root" rev-parse HEAD)"
  echo "beta" >> "$root/app.txt"
  git -C "$root" add app.txt
  git -C "$root" commit -q -m "change"
  head="$(git -C "$root" rev-parse HEAD)"

  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" init >/dev/null

  expect_exit 2 "g4-start missing packet fields fail closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-start --allowed app.txt || failed=1

  evidence="$root/verify.log"
  echo "verification ok" > "$evidence"
  packet="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-start \
      --id smoke-packet \
      --objective "smoke task" \
      --allowed app.txt \
      --forbidden "anything outside app.txt" \
      --verify "cat verify.log" \
      --stop "unexpected scope"
  )"
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-close \
    --packet "$packet" \
    --return-status DONE \
    --verification-status PASS \
    --verification-evidence "$evidence" >/dev/null
  echo "PASS g4 packet close requires evidence"

  expect_exit 2 "g5-package same base/head fails closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package --base "$head" --head "$head" || failed=1

  expect_exit 2 "g5-package scope mismatch fails closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package --base "$base" --head "$head" --scope app.txt,README.md || failed=1

  package="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package \
      --base "$base" \
      --head "$head" \
      --scope app.txt
  )"
  grep -q '^embedded_truncated: false$' "$package" || { echo "FAIL review package truncation marker"; failed=1; }
  grep -q '^+beta$' "$package" || { echo "FAIL review package does not embed full diff"; failed=1; }
  echo "PASS g5 package embeds full untruncated diff"

  expect_exit 2 "g5-review unavailable reviewer is blocked" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-review --package "$package" || failed=1

  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-review \
    --package "$package" \
    --cmd "printf 'PASS\n'" >/dev/null
  echo "PASS g5-review normalizes PASS"

  rm -rf "$tmp"

  if [[ "$failed" -ne 0 ]]; then
    exit 1
  fi

  echo "PASS strict-harness smoke"
}

command_name="${1:-help}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$command_name" in
  help|--help|-h)
    usage
    ;;
  init)
    cmd_init "$@"
    ;;
  smoke)
    cmd_smoke "$@"
    ;;
  g4-start)
    cmd_g4_start "$@"
    ;;
  g4-status)
    cmd_g4_status "$@"
    ;;
  g4-close)
    cmd_g4_close "$@"
    ;;
  g5-package)
    cmd_g5_package "$@"
    ;;
  g5-review)
    cmd_g5_review "$@"
    ;;
  *)
    echo "Unknown command: $command_name" >&2
    usage >&2
    exit 64
    ;;
esac
