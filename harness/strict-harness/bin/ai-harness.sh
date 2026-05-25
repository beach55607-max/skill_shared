#!/usr/bin/env bash
set -euo pipefail

VERSION="strict-harness v1"
REVIEW_REPO_OVERRIDE="${AI_DEV_REVIEW_REPO:-}"

usage() {
  cat <<'USAGE'
ai-harness - strict AI workflow harness

Usage:
  ai-harness help
  ai-harness init
  ai-harness smoke
  ai-harness install-hooks [--repo path/to/repo] [--force]
  ai-harness hook pre-commit [--repo path/to/repo]

  ai-harness run \
    [--repo path/to/repo] \
    [--d-level D1] \
    --objective "..." \
    --allowed path[,path] \
    --forbidden "..." \
    --verify "command" \
    --stop "..." \
    --command "implementation command"

  ai-harness g4-start \
    [--repo path/to/repo] \
    [--d-level D1] \
    --objective "..." \
    --allowed path[,path] \
    --forbidden "..." \
    --verify "command" \
    --stop "..."

  ai-harness g4-status --packet <packet-id-or-path>
  ai-harness g4-role-evidence --packet <packet> --role implementer|spec_reviewer|quality_reviewer --status PASS --evidence path/to/evidence.md [--notes "..."]

  ai-harness g4-close \
    [--repo path/to/repo] \
    --packet <packet-id-or-path> \
    --return-status DONE \
    --verification-status PASS \
    --verification-evidence path/to/evidence.log

  ai-harness g5-package [--repo path/to/repo] [--packet <g4-packet>] --base <sha> --head <sha> [--scope path[,path]]
  ai-harness g5-review --package <review-package> [--cmd "reviewer command {package}"]
  ai-harness full-review [--repo path/to/repo] [--packet <g4-packet>] --base <sha> --head <sha> [--scope path[,path]] [--cmd "..."]

Environment:
  AI_DEV_PROJECT_ROOT   Project root. Defaults to git top-level or current directory.
  AI_DEV_DIR            Runtime root. Defaults to <project>/.ai-dev.
  AI_DEV_REVIEW_REPO    Git repo whose diff/staged files are reviewed. Defaults to project root.
  AI_REVIEWER_CMD       Command used by g5-review. Use {package} as placeholder.
  AI_HARNESS_SKIP       Set to 1 to bypass local hooks with an explicit reason.
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

is_allowed_d_level() {
  case "$1" in
    D0|D1|D2|D3) return 0 ;;
    *) return 1 ;;
  esac
}

is_allowed_role() {
  case "$1" in
    implementer|spec_reviewer|quality_reviewer) return 0 ;;
    *) return 1 ;;
  esac
}

is_allowed_role_status() {
  case "$1" in
    PASS|REJECTED|NOT_CHECKED|NEEDS_CONTEXT|BLOCKED) return 0 ;;
    *) return 1 ;;
  esac
}

d_level_requires_role_loop() {
  case "$1" in
    D2|D3) return 0 ;;
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

is_absolute_path() {
  case "$1" in
    /*|[A-Za-z]:*|//*) return 0 ;;
    *) return 1 ;;
  esac
}

set_review_repo_override() {
  REVIEW_REPO_OVERRIDE="$1"
}

review_repo_root() {
  local project target resolved
  project="$(project_root)"
  target="${REVIEW_REPO_OVERRIDE:-$project}"

  if is_absolute_path "$target"; then
    resolved="$target"
  else
    resolved="$project/$target"
  fi

  if ! resolved="$(cd "$resolved" 2>/dev/null && pwd)"; then
    die "review repo not found: $target"
  fi
  printf '%s\n' "$resolved"
}

review_repo_relpath() {
  local project review
  project="$(project_root)"
  review="$(review_repo_root)"

  if [[ "$review" == "$project" ]]; then
    printf '.\n'
    return
  fi

  case "$review" in
    "$project"/*) printf '%s\n' "${review#"$project"/}" ;;
    *) printf '%s\n' "$review" ;;
  esac
}

maybe_set_review_repo_from_packet() {
  local packet="$1"
  local packet_review_root
  if [[ -n "${REVIEW_REPO_OVERRIDE:-}" ]]; then
    return
  fi
  packet_review_root="$(packet_value "$packet" review_repo_root || true)"
  if [[ -n "$packet_review_root" ]]; then
    set_review_repo_override "$packet_review_root"
  fi
}

resolve_existing_file_path() {
  local file="$1"
  local dir base
  [[ -f "$file" ]] || die "file does not exist: $file"
  if is_absolute_path "$file"; then
    (cd "$(dirname "$file")" && printf '%s/%s\n' "$(pwd)" "$(basename "$file")")
  else
    dir="$(dirname "$file")"
    base="$(basename "$file")"
    (cd "$dir" && printf '%s/%s\n' "$(pwd)" "$base")
  fi
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

g4_role_evidence_dir() {
  echo "$(runtime_dir)/g4-role-evidence"
}

review_package_dir() {
  echo "$(artifact_dir)/review-packages"
}

review_result_dir() {
  echo "$(artifact_dir)/reviews"
}

run_evidence_dir() {
  echo "$(runtime_dir)/run-evidence"
}

state_dir() {
  echo "$(runtime_dir)/state"
}

ensure_dirs() {
  mkdir -p "$(runtime_dir)" "$(artifact_dir)" "$(g4_packet_dir)" "$(g4_role_evidence_dir)" "$(review_package_dir)" "$(review_result_dir)" "$(run_evidence_dir)" "$(state_dir)"
}

require_git_repo() {
  local root
  root="$(review_repo_root)"
  git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "review repo is not a git repository: $root"
}

git_head_sha() {
  local root
  root="$(review_repo_root)"
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
  local d_level
  [[ -f "$packet" ]] || die "packet file does not exist: $packet"
  grep -q '^packet_version: 1$' "$packet" || die "packet is missing packet_version: $packet"
  grep -q '^packet_id: ' "$packet" || die "packet is missing packet_id: $packet"
  grep -q '^base_sha: ' "$packet" || die "packet is missing base_sha: $packet"
  grep -q '^status: ' "$packet" || die "packet is missing status: $packet"
  grep -q '^objective: ' "$packet" || die "packet is missing objective: $packet"
  grep -q '^verification_command: ' "$packet" || die "packet is missing verification_command: $packet"
  d_level="$(packet_value "$packet" d_level || true)"
  if [[ -n "$d_level" ]]; then
    is_allowed_d_level "$d_level" || die "packet has invalid d_level: $packet"
  fi
  list_has_items "$packet" "allowed_files:" || die "packet has no allowed_files entries: $packet"
  list_has_items "$packet" "forbidden_scope:" || die "packet has no forbidden_scope entries: $packet"
  list_has_items "$packet" "stop_conditions:" || die "packet has no stop_conditions entries: $packet"
}

packet_value() {
  local packet="$1"
  local key="$2"
  awk -F': ' -v key="$key" '$1 == key { print substr($0, length(key) + 3); exit }' "$packet"
}

list_section_values() {
  local file="$1"
  local header="$2"
  awk -v header="$header" '
    $0 == header { in_list = 1; next }
    /^[A-Za-z0-9_]+:/ { in_list = 0 }
    in_list && /^- / { sub(/^- /, ""); print }
  ' "$file"
}

packet_d_level() {
  local packet="$1"
  local value
  value="$(packet_value "$packet" d_level || true)"
  if [[ -z "$value" ]]; then
    value="D1"
  fi
  is_allowed_d_level "$value" || die "packet has invalid d_level: $packet"
  printf '%s\n' "$value"
}

required_g4_roles() {
  printf '%s\n' implementer spec_reviewer quality_reviewer
}

role_evidence_path() {
  local packet_id="$1"
  local role="$2"
  echo "$(g4_role_evidence_dir)/$packet_id/$role.evidence.md"
}

validate_role_evidence_file() {
  local evidence_file="$1"
  local role status source_file evidence_hash current_hash
  [[ -f "$evidence_file" ]] || die "role evidence file does not exist: $evidence_file"
  grep -q '^role_evidence_version: 1$' "$evidence_file" || die "role evidence missing version: $evidence_file"
  grep -q '^packet_id: ' "$evidence_file" || die "role evidence missing packet_id: $evidence_file"
  grep -q '^role: ' "$evidence_file" || die "role evidence missing role: $evidence_file"
  grep -q '^status: ' "$evidence_file" || die "role evidence missing status: $evidence_file"
  grep -q '^evidence_head_sha: ' "$evidence_file" || die "role evidence missing evidence_head_sha: $evidence_file"
  grep -q '^evidence_file: ' "$evidence_file" || die "role evidence missing evidence_file: $evidence_file"
  grep -q '^evidence_hash: ' "$evidence_file" || die "role evidence missing evidence_hash: $evidence_file"
  role="$(packet_value "$evidence_file" role)"
  status="$(packet_value "$evidence_file" status)"
  source_file="$(packet_value "$evidence_file" evidence_file)"
  evidence_hash="$(packet_value "$evidence_file" evidence_hash)"
  is_allowed_role "$role" || die "role evidence has invalid role: $evidence_file"
  is_allowed_role_status "$status" || die "role evidence has invalid status: $evidence_file"
  [[ -f "$source_file" ]] || die "role evidence source file missing: $source_file"
  current_hash="$(git hash-object "$source_file")"
  [[ "$current_hash" == "$evidence_hash" ]] || die "role evidence source hash changed: $source_file"
}

assert_g4_role_loop_passed() {
  local packet_file="$1"
  local expected_head="${2:-}"
  local packet_id role evidence_file status current_head evidence_head
  packet_id="$(packet_value "$packet_file" packet_id)"
  sanitize_id "$packet_id"
  current_head="${expected_head:-$(git_head_sha)}"

  while IFS= read -r role; do
    evidence_file="$(role_evidence_path "$packet_id" "$role")"
    validate_role_evidence_file "$evidence_file"
    status="$(packet_value "$evidence_file" status)"
    evidence_head="$(packet_value "$evidence_file" evidence_head_sha)"
    [[ "$evidence_head" == "$current_head" ]] || die "D2/D3 G4 role evidence was captured for a different HEAD for $role"
    if [[ "$status" != "PASS" ]]; then
      die "D2/D3 G4 role evidence is not PASS for $role: $status"
    fi
  done < <(required_g4_roles)
}

path_is_covered_by_allowed() {
  local path="$1"
  shift
  local allowed
  for allowed in "$@"; do
    allowed="${allowed%/}"
    if [[ "$path" == "$allowed" || "$path" == "$allowed/"* ]]; then
      return 0
    fi
  done
  return 1
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

cmd_install_hooks() {
  local force=false
  local repo=""
  local project root hook_path launcher_abs ai_dir

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
      --force)
        force=true
        shift
        ;;
      *)
        die "unknown install-hooks option: $1"
        ;;
    esac
  done

  require_git_repo
  ensure_dirs
  project="$(project_root)"
  root="$(review_repo_root)"
  hook_path="$(git -C "$root" rev-parse --git-path hooks/pre-commit)"
  case "$hook_path" in
    /*|[A-Za-z]:*|//*) ;;
    *) hook_path="$root/$hook_path" ;;
  esac
  ai_dir="$(ai_dev_dir)"
  launcher_abs="$ai_dir/bin/ai-harness"

  if [[ ! -x "$launcher_abs" ]]; then
    die "ai-harness launcher is missing or not executable: $launcher_abs"
  fi

  if [[ -e "$hook_path" ]] && ! grep -q "ai-dev-toolkit strict-harness managed hook" "$hook_path"; then
    if [[ "$force" != true ]]; then
      die "existing unmanaged pre-commit hook found; rerun with --force to replace it"
    fi
  fi

  mkdir -p "$(dirname "$hook_path")"
  cat > "$hook_path" <<HOOK
#!/usr/bin/env bash
# ai-dev-toolkit strict-harness managed hook
set -euo pipefail

if [[ "\${AI_HARNESS_SKIP:-}" == "1" ]]; then
  echo "strict-harness: AI_HARNESS_SKIP=1, bypassing pre-commit hook" >&2
  exit 0
fi

exec env AI_DEV_PROJECT_ROOT="$project" AI_DEV_DIR="$ai_dir" AI_DEV_REVIEW_REPO="$root" "$launcher_abs" hook pre-commit
HOOK
  chmod +x "$hook_path"
  echo "Installed strict-harness pre-commit hook: $hook_path"
}

cmd_hook_pre_commit() {
  local repo=""
  local root packet_dir packet latest=""
  local -a staged_files=()
  local -a allowed_files=()
  local file
  local covered=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
      *)
        die "unknown hook pre-commit option: $1"
        ;;
    esac
  done

  require_git_repo
  ensure_dirs
  root="$(review_repo_root)"
  packet_dir="$(g4_packet_dir)"

  while IFS= read -r file; do
    [[ -n "$file" ]] && staged_files+=("$file")
  done < <(git -C "$root" diff --cached --name-only)

  if [[ ${#staged_files[@]} -eq 0 ]]; then
    echo "strict-harness: no staged files"
    return 0
  fi

  if [[ ! -d "$packet_dir" ]]; then
    die "no G4 packet directory found; run ai-harness g4-start/g4-close before committing"
  fi

  while IFS= read -r packet; do
    validate_packet_file "$packet"
    if [[ "$(packet_value "$packet" status)" == "CLOSED" && "$(packet_value "$packet" verification_status)" == "PASS" ]]; then
      latest="$packet"
      break
    fi
  done < <(find "$packet_dir" -type f -name '*.packet.md' 2>/dev/null | sort -r)

  [[ -n "$latest" ]] || die "no CLOSED/PASS G4 packet found for staged changes"

  while IFS= read -r file; do
    [[ -n "$file" ]] && allowed_files+=("$file")
  done < <(list_section_values "$latest" "allowed_files:")

  [[ ${#allowed_files[@]} -gt 0 ]] || die "latest CLOSED/PASS G4 packet has no allowed files: $latest"

  for file in "${staged_files[@]}"; do
    if path_is_covered_by_allowed "$file" "${allowed_files[@]}"; then
      covered=$((covered + 1))
    else
      echo "staged file not covered by latest CLOSED/PASS G4 packet: $file" >&2
      echo "packet: $latest" >&2
      die "staged changes exceed G4 packet allowed_files"
    fi
  done

  echo "strict-harness: pre-commit PASS ($covered staged file(s), packet: $(basename "$latest"))"
}

cmd_hook() {
  local hook_name="${1:-}"
  if [[ $# -gt 0 ]]; then
    shift
  fi

  case "$hook_name" in
    pre-commit)
      cmd_hook_pre_commit "$@"
      ;;
    *)
      die "unknown hook command: ${hook_name:-MISSING}"
      ;;
  esac
}

cmd_g4_start() {
  local objective=""
  local verify_cmd=""
  local id=""
  local output=""
  local repo=""
  local d_level="D1"
  local -a allowed_files=()
  local -a forbidden_scope=()
  local -a stop_conditions=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
      --d-level)
        require_arg_value "$1" "${2:-}"
        d_level="$2"
        shift 2
        ;;
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
  is_allowed_d_level "$d_level" || die "invalid --d-level: $d_level"

  require_git_repo
  ensure_dirs

  if [[ -z "$id" ]]; then
    id="g4-$(timestamp_utc)-$$"
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
    echo "review_repo: $(review_repo_relpath)"
    echo "review_repo_root: $(review_repo_root)"
    echo "d_level: $d_level"
    if d_level_requires_role_loop "$d_level"; then
      echo "role_loop_required: true"
    else
      echo "role_loop_required: false"
    fi
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
    echo "required_roles:"
    if d_level_requires_role_loop "$d_level"; then
      required_g4_roles | while IFS= read -r role; do
        printf -- '- %s\n' "$role"
      done
    else
      echo "- NOT_REQUIRED"
    fi
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
  grep -E '^(packet_id|created_at_utc|review_repo|d_level|role_loop_required|base_sha|status|objective|verification_command|return_status|verification_status|closed_at_utc): ' "$packet" || true
}

cmd_g4_role_evidence() {
  local packet=""
  local role=""
  local status=""
  local evidence=""
  local notes=""
  local packet_file packet_id d_level output_dir output_file
  local evidence_abs evidence_hash evidence_head_sha

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --packet)
        require_arg_value "$1" "${2:-}"
        packet="$2"
        shift 2
        ;;
      --role)
        require_arg_value "$1" "${2:-}"
        role="$2"
        shift 2
        ;;
      --status)
        require_arg_value "$1" "${2:-}"
        status="$2"
        shift 2
        ;;
      --evidence)
        require_arg_value "$1" "${2:-}"
        evidence="$2"
        shift 2
        ;;
      --notes)
        require_arg_value "$1" "${2:-}"
        notes="$2"
        shift 2
        ;;
      *)
        die "unknown g4-role-evidence option: $1"
        ;;
    esac
  done

  [[ -n "$packet" ]] || die "g4-role-evidence requires --packet"
  [[ -n "$role" ]] || die "g4-role-evidence requires --role"
  [[ -n "$status" ]] || die "g4-role-evidence requires --status"
  [[ -n "$evidence" ]] || die "g4-role-evidence requires --evidence"
  is_allowed_role "$role" || die "invalid --role: $role"
  is_allowed_role_status "$status" || die "invalid --status: $status"
  evidence_abs="$(resolve_existing_file_path "$evidence")"
  evidence_hash="$(git hash-object "$evidence_abs")"

  ensure_dirs
  packet_file="$(packet_path_from_id "$packet")"
  validate_packet_file "$packet_file"
  maybe_set_review_repo_from_packet "$packet_file"
  require_git_repo
  d_level="$(packet_d_level "$packet_file")"
  if ! d_level_requires_role_loop "$d_level"; then
    die "g4-role-evidence is only required for D2/D3 packets; packet d_level is $d_level"
  fi
  grep -q '^status: OPEN$' "$packet_file" || die "role evidence can only be added before G4 close: $packet_file"

  packet_id="$(packet_value "$packet_file" packet_id)"
  sanitize_id "$packet_id"
  evidence_head_sha="$(git_head_sha)"
  output_dir="$(g4_role_evidence_dir)/$packet_id"
  output_file="$(role_evidence_path "$packet_id" "$role")"
  mkdir -p "$output_dir"

  {
    echo "# G4 Role Evidence"
    echo
    echo "role_evidence_version: 1"
    echo "created_at_utc: $(timestamp_utc)"
    echo "packet_id: $packet_id"
    echo "packet_file: $packet_file"
    echo "role: $role"
    echo "status: $status"
    echo "evidence_head_sha: $evidence_head_sha"
    echo "evidence_file: $evidence_abs"
    echo "evidence_hash: $evidence_hash"
    echo "notes: ${notes:-NONE}"
  } > "$output_file"

  validate_role_evidence_file "$output_file"
  echo "$output_file"
}

cmd_g4_close() {
  local packet=""
  local repo=""
  local return_status=""
  local verification_status=""
  local verification_evidence=""
  local packet_file tmp_file
  local d_level

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
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
  maybe_set_review_repo_from_packet "$packet_file"
  grep -q '^status: OPEN$' "$packet_file" || die "packet is not OPEN: $packet_file"

  if [[ "$return_status" == "DONE" && "$verification_status" != "PASS" ]]; then
    die "DONE requires --verification-status PASS"
  fi

  if [[ "$verification_status" == "PASS" ]]; then
    [[ -n "$verification_evidence" ]] || die "PASS requires --verification-evidence"
    [[ -f "$verification_evidence" ]] || die "verification evidence file does not exist: $verification_evidence"
  fi

  require_git_repo
  d_level="$(packet_d_level "$packet_file")"
  if [[ "$return_status" == "DONE" && "$verification_status" == "PASS" ]] && d_level_requires_role_loop "$d_level"; then
    assert_g4_role_loop_passed "$packet_file"
  fi

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

cmd_run() {
  local objective=""
  local verify_cmd=""
  local run_cmd=""
  local id=""
  local packet=""
  local repo=""
  local d_level="D1"
  local review_root
  local evidence_dir run_log verify_log summary_log
  local run_exit verify_exit close_status verification_status
  local -a allowed_files=()
  local -a forbidden_scope=()
  local -a stop_conditions=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
      --d-level)
        require_arg_value "$1" "${2:-}"
        d_level="$2"
        shift 2
        ;;
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
      --command)
        require_arg_value "$1" "${2:-}"
        run_cmd="$2"
        shift 2
        ;;
      --id)
        require_arg_value "$1" "${2:-}"
        id="$2"
        shift 2
        ;;
      --)
        shift
        run_cmd="$*"
        break
        ;;
      *)
        die "unknown run option: $1"
        ;;
    esac
  done

  [[ -n "$objective" ]] || die "run requires --objective"
  [[ ${#allowed_files[@]} -gt 0 ]] || die "run requires at least one --allowed entry"
  [[ ${#forbidden_scope[@]} -gt 0 ]] || die "run requires at least one --forbidden entry"
  [[ -n "$verify_cmd" ]] || die "run requires --verify"
  [[ ${#stop_conditions[@]} -gt 0 ]] || die "run requires at least one --stop entry"
  [[ -n "$run_cmd" ]] || die "run requires --command or -- command"
  is_allowed_d_level "$d_level" || die "invalid --d-level: $d_level"

  require_git_repo
  ensure_dirs
  review_root="$(review_repo_root)"

  if [[ -z "$id" ]]; then
    id="run-$(timestamp_utc)-$$"
  fi
  sanitize_id "$id"

  evidence_dir="$(run_evidence_dir)/$id"
  [[ ! -e "$evidence_dir" ]] || die "run evidence directory already exists: $evidence_dir"
  mkdir -p "$evidence_dir"
  run_log="$evidence_dir/run.log"
  verify_log="$evidence_dir/verify.log"
  summary_log="$evidence_dir/summary.log"

  packet="$(
    cmd_g4_start \
      --id "$id" \
      --d-level "$d_level" \
      --objective "$objective" \
      --allowed "$(IFS=,; echo "${allowed_files[*]}")" \
      --forbidden "$(IFS=,; echo "${forbidden_scope[*]}")" \
      --verify "$verify_cmd" \
      --stop "$(IFS=,; echo "${stop_conditions[*]}")"
  )"

  {
    echo "run_id: $id"
    echo "packet: $packet"
    echo "started_at_utc: $(timestamp_utc)"
    echo "project_root: $(project_root)"
    echo "review_repo: $(review_repo_relpath)"
    echo "review_repo_root: $review_root"
    echo "d_level: $d_level"
    echo "command: $run_cmd"
    echo "verification_command: $verify_cmd"
  } > "$summary_log"

  set +e
  bash -lc "cd \"$review_root\" && $run_cmd" > "$run_log" 2>&1
  run_exit=$?
  set -e

  {
    echo
    echo "run_exit_code: $run_exit"
    echo "run_finished_at_utc: $(timestamp_utc)"
  } >> "$summary_log"

  if [[ "$run_exit" -eq 0 ]]; then
    set +e
    bash -lc "cd \"$review_root\" && $verify_cmd" > "$verify_log" 2>&1
    verify_exit=$?
    set -e
  else
    verify_exit=127
    {
      echo "verification skipped because implementation command failed"
      echo "run_exit_code: $run_exit"
    } > "$verify_log"
  fi

  {
    echo "verification_exit_code: $verify_exit"
    echo "verification_finished_at_utc: $(timestamp_utc)"
    echo "run_log: $run_log"
    echo "verify_log: $verify_log"
  } >> "$summary_log"

  if [[ "$run_exit" -eq 0 && "$verify_exit" -eq 0 ]]; then
    close_status="DONE"
    verification_status="PASS"
  elif [[ "$run_exit" -eq 0 ]]; then
    close_status="DONE_WITH_CONCERNS"
    verification_status="FAIL"
  else
    close_status="BLOCKED"
    verification_status="FAIL"
  fi

  if [[ "$close_status" == "DONE" && "$verification_status" == "PASS" ]] && d_level_requires_role_loop "$d_level"; then
    {
      echo "role_loop_status: REQUIRED_BEFORE_G4_CLOSE"
      echo "role_loop_required: true"
      echo "required_roles: implementer,spec_reviewer,quality_reviewer"
    } >> "$summary_log"
    echo "$summary_log"
    die "D2/D3 run completed verification, but G4 remains OPEN until implementer/spec_reviewer/quality_reviewer role evidence is recorded and g4-close is run"
  fi

  cmd_g4_close \
    --packet "$packet" \
    --return-status "$close_status" \
    --verification-status "$verification_status" \
    --verification-evidence "$verify_log" >/dev/null

  echo "$summary_log"

  if [[ "$run_exit" -ne 0 ]]; then
    exit "$run_exit"
  fi
  if [[ "$verify_exit" -ne 0 ]]; then
    exit "$verify_exit"
  fi
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
  local repo=""
  local packet=""
  local packet_file=""
  local packet_d_level=""
  local packet_base_sha=""
  local packet_closed_head_sha=""
  local root
  local base_sha head_sha
  local -a scope_files=()
  local -a actual_diff_files=()
  local -a package_scope=()
  local tmp_dir diff_file body_file package_hash full_diff_hash file file_hash content_hash

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
      --packet)
        require_arg_value "$1" "${2:-}"
        packet="$2"
        shift 2
        ;;
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

  if [[ -n "$packet" ]]; then
    packet_file="$(packet_path_from_id "$packet")"
    validate_packet_file "$packet_file"
    maybe_set_review_repo_from_packet "$packet_file"
    grep -q '^status: CLOSED$' "$packet_file" || die "g5-package --packet requires CLOSED G4 packet"
    grep -q '^verification_status: PASS$' "$packet_file" || die "g5-package --packet requires PASS G4 packet"
    packet_d_level="$(packet_d_level "$packet_file")"
    packet_base_sha="$(packet_value "$packet_file" base_sha)"
    packet_closed_head_sha="$(packet_value "$packet_file" closed_head_sha || true)"
    [[ -n "$packet_closed_head_sha" ]] || die "g5-package --packet requires packet closed_head_sha"
    if d_level_requires_role_loop "$packet_d_level"; then
      assert_g4_role_loop_passed "$packet_file" "$packet_closed_head_sha"
    fi
  fi

  require_git_repo
  ensure_dirs
  root="$(review_repo_root)"

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
  if [[ -n "$packet_file" ]]; then
    [[ "$base_sha" == "$packet_base_sha" ]] || die "g5-package --packet BASE_SHA does not match G4 packet base_sha"
    [[ "$head_sha" == "$packet_closed_head_sha" ]] || die "g5-package --packet HEAD_SHA does not match G4 packet closed_head_sha"
  fi

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
    output="$(review_package_dir)/g5-review-$(timestamp_utc)-$$.md"
  fi
  [[ ! -e "$output" ]] || die "review package already exists: $output"

  body_file="$tmp_dir/package-body.md"
  {
    echo "# G5 Review Evidence Package"
    echo
    echo "review_package_version: 1"
    echo "created_at_utc: $(timestamp_utc)"
    echo "project_root: $(project_root)"
    echo "review_repo: $(review_repo_relpath)"
    echo "review_repo_root: $root"
    echo "g4_packet: ${packet_file:-NOT_BOUND}"
    echo "g4_d_level: ${packet_d_level:-NOT_BOUND}"
    if [[ -n "$packet_d_level" ]] && d_level_requires_role_loop "$packet_d_level"; then
      echo "g4_role_loop_required: true"
    else
      echo "g4_role_loop_required: false"
    fi
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
  output_file="$(review_result_dir)/g5-review-$(timestamp_utc)-$$.md"

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

cmd_full_review() {
  local base=""
  local head="HEAD"
  local reviewer_cmd="${AI_REVIEWER_CMD:-}"
  local package=""
  local repo=""
  local packet=""
  local -a scope_files=()
  local -a package_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        require_arg_value "$1" "${2:-}"
        repo="$2"
        set_review_repo_override "$repo"
        shift 2
        ;;
      --packet)
        require_arg_value "$1" "${2:-}"
        packet="$2"
        shift 2
        ;;
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
      --cmd)
        require_arg_value "$1" "${2:-}"
        reviewer_cmd="$2"
        shift 2
        ;;
      *)
        die "unknown full-review option: $1"
        ;;
    esac
  done

  [[ -n "$base" ]] || die "full-review requires --base"
  package_args=(--base "$base" --head "$head")
  if [[ -n "$packet" ]]; then
    package_args+=(--packet "$packet")
  fi
  if [[ ${#scope_files[@]} -gt 0 ]]; then
    package_args+=(--scope "$(IFS=,; echo "${scope_files[*]}")")
  fi

  package="$(cmd_g5_package "${package_args[@]}")"
  if [[ -n "$reviewer_cmd" ]]; then
    cmd_g5_review --package "$package" --cmd "$reviewer_cmd"
  else
    cmd_g5_review --package "$package"
  fi
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
  local d2_base d2_head
  local nested_workspace nested_repo nested_base nested_head nested_package nested_evidence nested_packet nested_hook
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

  if [[ -z "$home" || ! -f "$home/templates/g4-role-evidence.md" ]]; then
    echo "FAIL G4 role evidence template missing"
    failed=1
  else
    echo "PASS G4 role evidence template exists"
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

  echo "gamma" >> "$root/app.txt"
  git -C "$root" add app.txt
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" hook pre-commit >/dev/null
  echo "PASS pre-commit hook accepts staged files covered by CLOSED/PASS G4 packet"
  echo "other" > "$root/other.txt"
  git -C "$root" add other.txt
  expect_exit 2 "pre-commit hook rejects staged files outside packet allowed_files" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" hook pre-commit || failed=1
  git -C "$root" reset -q HEAD other.txt app.txt
  rm -f "$root/other.txt"

  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" run \
    --id smoke-run \
    --objective "run wrapper smoke" \
    --allowed app.txt \
    --forbidden "other files" \
    --verify "grep -q wrapper app.txt" \
    --stop "unexpected scope" \
    --command "echo wrapper >> app.txt" >/dev/null
  grep -q '^return_status: DONE$' "$root/.ai-dev/runtime/g4-packets/smoke-run.packet.md" || { echo "FAIL run wrapper did not close DONE"; failed=1; }
  grep -q '^verification_status: PASS$' "$root/.ai-dev/runtime/g4-packets/smoke-run.packet.md" || { echo "FAIL run wrapper did not close PASS"; failed=1; }
  echo "PASS run wrapper creates and closes G4 packet"
  git -C "$root" add app.txt
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" hook pre-commit >/dev/null
  git -C "$root" reset -q HEAD app.txt
  echo "PASS hook accepts changes produced by run wrapper"

  expect_exit 1 "run wrapper fails closed when verification fails" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" run \
      --id smoke-run-fail \
      --objective "run wrapper failure smoke" \
      --allowed app.txt \
      --forbidden "other files" \
      --verify "grep -q missing-token app.txt" \
      --stop "unexpected scope" \
      --command "echo noverify >> app.txt" || failed=1
  grep -q '^return_status: DONE_WITH_CONCERNS$' "$root/.ai-dev/runtime/g4-packets/smoke-run-fail.packet.md" || { echo "FAIL run wrapper failure did not close with concerns"; failed=1; }
  grep -q '^verification_status: FAIL$' "$root/.ai-dev/runtime/g4-packets/smoke-run-fail.packet.md" || { echo "FAIL run wrapper failure did not record FAIL"; failed=1; }
  echo "PASS run wrapper records failed verification"

  git -C "$root" reset --hard -q "$head"
  d2_base="$(git -C "$root" rev-parse HEAD)"
  packet="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-start \
      --id smoke-d2-packet \
      --d-level D2 \
      --objective "D2 role loop smoke task" \
      --allowed app.txt \
      --forbidden "anything outside app.txt" \
      --verify "cat verify.log" \
      --stop "unexpected scope"
  )"
  echo "d2 role loop change" >> "$root/app.txt"
  git -C "$root" add app.txt
  git -C "$root" commit -q -m "d2 role loop change"
  d2_head="$(git -C "$root" rev-parse HEAD)"
  expect_exit 2 "D2 G4 close without role evidence fails closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-close \
      --packet "$packet" \
      --return-status DONE \
      --verification-status PASS \
      --verification-evidence "$evidence" || failed=1
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence \
    --packet "$packet" \
    --role implementer \
    --status PASS \
    --evidence "$evidence" \
    --notes "implementation checked" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence \
    --packet "$packet" \
    --role spec_reviewer \
    --status PASS \
    --evidence "$evidence" \
    --notes "spec checked" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence \
    --packet "$packet" \
    --role quality_reviewer \
    --status PASS \
    --evidence "$evidence" \
    --notes "quality checked" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-close \
    --packet "$packet" \
    --return-status DONE \
    --verification-status PASS \
    --verification-evidence "$evidence" >/dev/null
  grep -q '^d_level: D2$' "$root/.ai-dev/runtime/g4-packets/smoke-d2-packet.packet.md" || { echo "FAIL D2 packet did not record d_level"; failed=1; }
  echo "PASS D2 G4 closes only after all role evidence PASS"

  packet="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-start \
      --id smoke-d2-reject-packet \
      --d-level D2 \
      --objective "D2 role reject smoke task" \
      --allowed app.txt \
      --forbidden "anything outside app.txt" \
      --verify "cat verify.log" \
      --stop "unexpected scope"
  )"
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role implementer --status PASS --evidence "$evidence" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role spec_reviewer --status REJECTED --evidence "$evidence" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role quality_reviewer --status PASS --evidence "$evidence" >/dev/null
  expect_exit 2 "D2 G4 rejected role evidence blocks PASS close" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-close \
      --packet "$packet" \
      --return-status DONE \
      --verification-status PASS \
      --verification-evidence "$evidence" || failed=1
  echo "PASS D2 G4 role evidence rejects non-PASS role"

  local tamper_evidence
  tamper_evidence="$root/tamper-evidence.log"
  echo "tamper evidence v1" > "$tamper_evidence"
  packet="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-start \
      --id smoke-d2-tamper-packet \
      --d-level D2 \
      --objective "D2 role tamper smoke task" \
      --allowed app.txt \
      --forbidden "anything outside app.txt" \
      --verify "cat verify.log" \
      --stop "unexpected scope"
  )"
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role implementer --status PASS --evidence "$tamper_evidence" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role spec_reviewer --status PASS --evidence "$tamper_evidence" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role quality_reviewer --status PASS --evidence "$tamper_evidence" >/dev/null
  echo "tamper evidence v2" > "$tamper_evidence"
  expect_exit 2 "D2 G4 role evidence hash tamper blocks PASS close" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-close \
      --packet "$packet" \
      --return-status DONE \
      --verification-status PASS \
      --verification-evidence "$evidence" || failed=1
  echo "PASS D2 G4 role evidence hash tamper is blocked"

  packet="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-start \
      --id smoke-d2-head-mismatch-packet \
      --d-level D2 \
      --objective "D2 role head mismatch smoke task" \
      --allowed app.txt \
      --forbidden "anything outside app.txt" \
      --verify "cat verify.log" \
      --stop "unexpected scope"
  )"
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role implementer --status PASS --evidence "$evidence" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role spec_reviewer --status PASS --evidence "$evidence" >/dev/null
  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-role-evidence --packet "$packet" --role quality_reviewer --status PASS --evidence "$evidence" >/dev/null
  echo "head mismatch change" >> "$root/app.txt"
  git -C "$root" add app.txt
  git -C "$root" commit -q -m "head mismatch change"
  expect_exit 2 "D2 G4 role evidence HEAD mismatch blocks PASS close" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g4-close \
      --packet "$packet" \
      --return-status DONE \
      --verification-status PASS \
      --verification-evidence "$evidence" || failed=1
  git -C "$root" reset --hard -q "$d2_head"
  echo "PASS D2 G4 role evidence HEAD mismatch is blocked"

  expect_exit 2 "D2 run wrapper leaves packet open until role evidence" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" run \
      --id smoke-d2-run-open \
      --d-level D2 \
      --objective "D2 run wrapper smoke" \
      --allowed app.txt \
      --forbidden "other files" \
      --verify "grep -q d2run app.txt" \
      --stop "unexpected scope" \
      --command "echo d2run >> app.txt" || failed=1
  grep -q '^status: OPEN$' "$root/.ai-dev/runtime/g4-packets/smoke-d2-run-open.packet.md" || { echo "FAIL D2 run wrapper did not leave packet OPEN"; failed=1; }
  echo "PASS D2 run wrapper does not fake-close without role evidence"

  expect_exit 2 "g5-package same base/head fails closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package --base "$head" --head "$head" || failed=1

  expect_exit 2 "g5-package scope mismatch fails closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package --base "$base" --head "$head" --scope app.txt,README.md || failed=1

  expect_exit 2 "g5-package packet range mismatch fails closed" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package --packet smoke-d2-packet --base "$base" --head "$head" --scope app.txt || failed=1

  package="$(
    AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-package \
      --packet smoke-d2-packet \
      --base "$d2_base" \
      --head "$d2_head" \
      --scope app.txt
  )"
  grep -q '^g4_d_level: D2$' "$package" || { echo "FAIL review package did not bind G4 d_level"; failed=1; }
  grep -q '^g4_role_loop_required: true$' "$package" || { echo "FAIL review package did not bind G4 role loop"; failed=1; }
  grep -q '^embedded_truncated: false$' "$package" || { echo "FAIL review package truncation marker"; failed=1; }
  grep -q '^+d2 role loop change$' "$package" || { echo "FAIL review package does not embed packet-bound full diff"; failed=1; }
  echo "PASS g5 package embeds full untruncated diff and binds G4 packet"

  expect_exit 2 "g5-review unavailable reviewer is blocked" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-review --package "$package" || failed=1

  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" g5-review \
    --package "$package" \
    --cmd "printf 'PASS\n'" >/dev/null
  echo "PASS g5-review normalizes PASS"

  expect_exit 2 "full-review unavailable reviewer is blocked" \
    env AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" full-review --base "$base" --head "$head" --scope app.txt || failed=1

  AI_DEV_PROJECT_ROOT="$root" AI_DEV_DIR="$root/.ai-dev" bash "$self" full-review \
    --base "$base" \
    --head "$head" \
    --scope app.txt \
    --cmd "printf 'PASS\n'" >/dev/null
  echo "PASS full-review packages diff and normalizes reviewer verdict"

  nested_workspace="$tmp/workspace"
  nested_repo="$nested_workspace/service"
  mkdir -p "$nested_repo"
  git -C "$nested_repo" init -q
  git -C "$nested_repo" config user.email "ai-harness-smoke@example.invalid"
  git -C "$nested_repo" config user.name "AI Harness Smoke"
  echo "nested alpha" > "$nested_repo/app.txt"
  git -C "$nested_repo" add app.txt
  git -C "$nested_repo" commit -q -m "nested base"
  nested_base="$(git -C "$nested_repo" rev-parse HEAD)"
  echo "nested beta" >> "$nested_repo/app.txt"
  git -C "$nested_repo" add app.txt
  git -C "$nested_repo" commit -q -m "nested change"
  nested_head="$(git -C "$nested_repo" rev-parse HEAD)"

  AI_DEV_PROJECT_ROOT="$nested_workspace" AI_DEV_DIR="$nested_workspace/.ai-dev" bash "$self" init >/dev/null
  nested_package="$(
    AI_DEV_PROJECT_ROOT="$nested_workspace" AI_DEV_DIR="$nested_workspace/.ai-dev" bash "$self" g5-package \
      --repo service \
      --base "$nested_base" \
      --head "$nested_head" \
      --scope app.txt
  )"
  grep -q '^review_repo: service$' "$nested_package" || { echo "FAIL nested review package did not bind review_repo"; failed=1; }
  grep -q '^+nested beta$' "$nested_package" || { echo "FAIL nested review package did not use nested repo diff"; failed=1; }
  case "$nested_package" in
    "$nested_workspace/.ai-dev/gate-artifacts/review-packages/"*) echo "PASS nested review repo keeps artifacts in workspace runtime" ;;
    *) echo "FAIL nested review package escaped workspace runtime: $nested_package"; failed=1 ;;
  esac
  echo "PASS nested review repo uses child repo diff"

  mkdir -p "$nested_workspace/.ai-dev/bin"
  cp "$self" "$nested_workspace/.ai-dev/bin/ai-harness"
  chmod +x "$nested_workspace/.ai-dev/bin/ai-harness"
  AI_DEV_PROJECT_ROOT="$nested_workspace" AI_DEV_DIR="$nested_workspace/.ai-dev" bash "$self" install-hooks --repo service --force >/dev/null
  nested_hook="$(git -C "$nested_repo" rev-parse --git-path hooks/pre-commit)"
  case "$nested_hook" in
    /*|[A-Za-z]:*|//*) ;;
    *) nested_hook="$nested_repo/$nested_hook" ;;
  esac
  [[ -x "$nested_hook" ]] || { echo "FAIL nested review repo hook was not installed"; failed=1; }
  nested_evidence="$nested_workspace/nested-verify.log"
  echo "nested verification ok" > "$nested_evidence"
  nested_packet="$(
    AI_DEV_PROJECT_ROOT="$nested_workspace" AI_DEV_DIR="$nested_workspace/.ai-dev" bash "$self" g4-start \
      --repo service \
      --id nested-smoke-packet \
      --objective "nested repo smoke task" \
      --allowed app.txt \
      --forbidden "anything outside app.txt" \
      --verify "cat ../nested-verify.log" \
      --stop "unexpected scope"
  )"
  AI_DEV_PROJECT_ROOT="$nested_workspace" AI_DEV_DIR="$nested_workspace/.ai-dev" bash "$self" g4-close \
    --packet "$nested_packet" \
    --return-status DONE \
    --verification-status PASS \
    --verification-evidence "$nested_evidence" >/dev/null
  echo "nested gamma" >> "$nested_repo/app.txt"
  git -C "$nested_repo" add app.txt
  (cd "$nested_repo" && "$nested_hook") >/dev/null
  git -C "$nested_repo" reset -q HEAD app.txt
  echo "PASS nested review repo hook checks child repo staged files"

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
  run)
    cmd_run "$@"
    ;;
  g4-start)
    cmd_g4_start "$@"
    ;;
  g4-status)
    cmd_g4_status "$@"
    ;;
  g4-role-evidence)
    cmd_g4_role_evidence "$@"
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
  full-review)
    cmd_full_review "$@"
    ;;
  install-hooks)
    cmd_install_hooks "$@"
    ;;
  hook)
    cmd_hook "$@"
    ;;
  *)
    echo "Unknown command: $command_name" >&2
    usage >&2
    exit 64
    ;;
esac
