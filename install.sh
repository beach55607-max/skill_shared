#!/usr/bin/env bash
# install.sh — AI Engineering Skills 一鍵安裝
# Usage:
#   bash install.sh                    # 安裝全部到 .claude/skills/
#   bash install.sh --codex            # 安裝到 .codex/skills/
#   bash install.sh --list             # 列出可安裝的 skill
#   bash install.sh --skill 1 3        # 只裝 Boundary-First + Adversarial Review
#   bash install.sh --skill 5          # 只裝 Strict Harness Workflow skill
#   bash install.sh --target /my/proj  # 指定專案目錄
#   bash install.sh --profile strict-harness --target /my/proj
#   bash install.sh --profile strict-harness --hooks --target /my/proj [--repo path/to/repo]
#   bash install.sh --uninstall        # 移除已安裝的 skill

set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="."
AGENT="claude"  # claude or codex
PROFILE=""
DRY_RUN=false
INSTALL_HOOKS=false
FORCE_HOOKS=false
REVIEW_REPO=""

# --- Skill definitions ---
# Format: "id:source_dir:target_name:description"
SKILLS=(
  "0:cw-brainstorming:cw-brainstorming:Brainstorming Capture — 發想捕捉 + Discovery Gate"
  "1:claude-code/boundary-first-multi-repo-engineering:boundary-first-multi-repo-engineering:Boundary-First Engineering — 跨 repo 治理 + UGP 10 Gate"
  "2:executable-spec-planning:executable-spec-planning:Executable Spec Planning — 可執行規格書"
  "3:adversarial-code-review:adversarial-code-review:Adversarial Code Review — 證偽法審查"
  "4:usp-brainstorm:usp-brainstorm:USP Brainstorm — 產品賣點競爭分析"
  "5:strict-harness-workflow:strict-harness-workflow:Strict Harness Workflow — 自然語言喚起 ai-harness"
)

CODEX_SKILLS=(
  "0:cw-brainstorming:cw-brainstorming:Brainstorming Capture"
  "1:codex/boundary-first-multi-repo-engineering:boundary-first-multi-repo-engineering:Boundary-First Engineering"
  "2:executable-spec-planning:executable-spec-planning:Executable Spec Planning"
  "3:adversarial-code-review:adversarial-code-review:Adversarial Code Review"
  "4:usp-brainstorm:usp-brainstorm:USP Brainstorm"
  "5:strict-harness-workflow:strict-harness-workflow:Strict Harness Workflow"
)

run_or_print() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '  DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

is_absolute_path() {
  case "$1" in
    /*|[A-Za-z]:*|//*) return 0 ;;
    *) return 1 ;;
  esac
}

target_abs_dir() {
  cd "$TARGET_DIR" && pwd
}

resolve_review_repo() {
  local target_abs repo_value
  target_abs="$(target_abs_dir)"
  repo_value="${REVIEW_REPO:-$target_abs}"

  if is_absolute_path "$repo_value"; then
    cd "$repo_value" && pwd
  else
    cd "$target_abs/$repo_value" && pwd
  fi
}

exclude_strict_harness_runtime() {
  local exclude_file target_abs

  if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Note: $TARGET_DIR is not a git repo; skip local .ai-dev exclude."
    return
  fi

  target_abs="$(cd "$TARGET_DIR" && pwd)"
  exclude_file="$(cd "$TARGET_DIR" && git rev-parse --git-path info/exclude)"
  case "$exclude_file" in
    /*) ;;
    ?:*) ;;
    *) exclude_file="$target_abs/$exclude_file" ;;
  esac

  if [[ "$DRY_RUN" == true ]]; then
    echo "  DRY-RUN: ensure .ai-dev/ is listed in $exclude_file"
    return
  fi

  mkdir -p "$(dirname "$exclude_file")"
  touch "$exclude_file"
  if ! grep -qxF ".ai-dev/" "$exclude_file"; then
    {
      echo ""
      echo "# ai-dev-toolkit strict-harness local runtime"
      echo ".ai-dev/"
    } >> "$exclude_file"
    echo "Added .ai-dev/ to local git exclude: $exclude_file"
  fi
}

install_strict_harness() {
  local profile_src="$SCRIPT_DIR/harness/strict-harness"
  local target_abs install_root
  target_abs="$(target_abs_dir)"
  install_root="$target_abs/.ai-dev"
  local runtime_dir="$install_root/runtime"
  local artifacts_dir="$install_root/gate-artifacts"
  local bin_dir="$install_root/bin"
  local harness_dir="$install_root/harness/strict-harness"
  local launcher="$bin_dir/ai-harness"
  local review_repo_abs="$target_abs"

  if [[ -n "$REVIEW_REPO" ]]; then
    review_repo_abs="$(resolve_review_repo)"
  fi

  if [[ ! -d "$profile_src" ]]; then
    echo "strict-harness profile source not found: $profile_src" >&2
    exit 1
  fi

  if [[ "$UNINSTALL" == true ]]; then
    echo "Uninstalling strict-harness from $install_root ..."
    if [[ -e "$launcher" ]]; then
      run_or_print rm -f "$launcher"
    else
      echo "  - ai-harness launcher (not installed)"
    fi
    if [[ -d "$harness_dir" ]]; then
      run_or_print rm -rf "$harness_dir"
    else
      echo "  - strict-harness profile (not installed)"
    fi
    echo "Runtime data is left in place: $runtime_dir and $artifacts_dir"
    echo "Done."
    exit 0
  fi

  echo "Installing strict-harness profile to $install_root ..."
  echo ""

  run_or_print mkdir -p "$runtime_dir" "$artifacts_dir" "$bin_dir" "$(dirname "$harness_dir")"

  if [[ -d "$harness_dir" ]]; then
    run_or_print rm -rf "$harness_dir"
  fi

  run_or_print cp -r "$profile_src" "$harness_dir"
  if [[ "$DRY_RUN" == true ]]; then
    echo "  DRY-RUN: write launcher shim $launcher"
    run_or_print chmod +x "$launcher"
  else
    cat > "$launcher" <<LAUNCHER
#!/usr/bin/env bash
# ai-dev-toolkit strict-harness launcher
set -euo pipefail

export AI_DEV_PROJECT_ROOT="\${AI_DEV_PROJECT_ROOT:-$target_abs}"
export AI_DEV_DIR="\${AI_DEV_DIR:-$install_root}"
export AI_DEV_REVIEW_REPO="\${AI_DEV_REVIEW_REPO:-$review_repo_abs}"

exec "$harness_dir/bin/ai-harness.sh" "\$@"
LAUNCHER
    chmod +x "$launcher"
  fi
  exclude_strict_harness_runtime

  if [[ "$INSTALL_HOOKS" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      if [[ "$FORCE_HOOKS" == true ]]; then
        run_or_print env AI_DEV_PROJECT_ROOT="$target_abs" AI_DEV_DIR="$install_root" AI_DEV_REVIEW_REPO="$review_repo_abs" "$launcher" install-hooks --repo "$review_repo_abs" --force
      else
        run_or_print env AI_DEV_PROJECT_ROOT="$target_abs" AI_DEV_DIR="$install_root" AI_DEV_REVIEW_REPO="$review_repo_abs" "$launcher" install-hooks --repo "$review_repo_abs"
      fi
    elif [[ "$FORCE_HOOKS" == true ]]; then
      AI_DEV_PROJECT_ROOT="$target_abs" AI_DEV_DIR="$install_root" AI_DEV_REVIEW_REPO="$review_repo_abs" "$launcher" install-hooks --repo "$review_repo_abs" --force
    else
      AI_DEV_PROJECT_ROOT="$target_abs" AI_DEV_DIR="$install_root" AI_DEV_REVIEW_REPO="$review_repo_abs" "$launcher" install-hooks --repo "$review_repo_abs"
    fi
  fi

  echo ""
  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run complete. No files were changed."
  else
    echo "Installed strict-harness profile."
  fi
  echo "Runtime:   $runtime_dir"
  echo "Artifacts: $artifacts_dir"
  echo "Command:   $launcher"
  echo "Review repo: $review_repo_abs"
  echo ""
  echo "Add $bin_dir to PATH or run: $launcher smoke"
  exit 0
}

# --- Parse args ---
SELECTED_IDS=()
UNINSTALL=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex)
      AGENT="codex"
      shift
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --repo)
      REVIEW_REPO="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --hooks)
      INSTALL_HOOKS=true
      shift
      ;;
    --force-hooks)
      FORCE_HOOKS=true
      shift
      ;;
    --skill)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        SELECTED_IDS+=("$1")
        shift
      done
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --list)
      LIST_ONLY=true
      shift
      ;;
    --help|-h)
      echo "Usage: bash install.sh [options]"
      echo ""
      echo "Options:"
      echo "  --codex            Install to .codex/skills/ (default: .claude/skills/)"
      echo "  --target <dir>     Target project directory (default: current directory)"
      echo "  --skill <id...>    Install specific skills by ID (e.g., --skill 1 3)"
      echo "  --profile <name>   Install an optional workflow profile (strict-harness)"
      echo "  --repo <dir>       Review git repo for strict-harness hooks (default: target)"
      echo "  --dry-run          Print planned filesystem actions without changing files"
      echo "  --hooks            Install strict-harness repo-local git hooks"
      echo "  --force-hooks      Replace an existing unmanaged git hook when used with --hooks"
      echo "  --list             List available skills"
      echo "  --uninstall        Remove installed skills"
      echo "  --help             Show this help"
      echo ""
      echo "Examples:"
      echo "  bash install.sh                     # Install all to .claude/skills/"
      echo "  bash install.sh --codex             # Install all to .codex/skills/"
      echo "  bash install.sh --skill 1 3         # Install Boundary-First + Adversarial Review"
      echo "  bash install.sh --skill 5           # Install Strict Harness Workflow"
      echo "  bash install.sh --target ~/myproj   # Install to specific project"
      echo "  bash install.sh --profile strict-harness --target ~/myproj"
      echo "  bash install.sh --profile strict-harness --hooks --target ~/myproj"
      echo "  bash install.sh --profile strict-harness --hooks --target ~/workspace --repo service"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Use --help for usage." >&2
      exit 1
      ;;
  esac
done

if [[ -n "$PROFILE" ]]; then
  if [[ "$PROFILE" == "strict-harness" ]]; then
    if [[ ${#SELECTED_IDS[@]} -gt 0 ]]; then
      echo "--profile strict-harness cannot be combined with --skill." >&2
      exit 1
    fi
    install_strict_harness
  fi

  echo "Unknown profile: $PROFILE. Available profiles: strict-harness" >&2
  exit 1
fi

if [[ "$INSTALL_HOOKS" == true || "$FORCE_HOOKS" == true ]]; then
  echo "--hooks and --force-hooks require --profile strict-harness." >&2
  exit 1
fi

if [[ -n "$REVIEW_REPO" ]]; then
  echo "--repo requires --profile strict-harness." >&2
  exit 1
fi

# --- Select skill set ---
if [[ "$AGENT" == "codex" ]]; then
  SKILL_SET=("${CODEX_SKILLS[@]}")
  INSTALL_DIR="$TARGET_DIR/.codex/skills"
else
  SKILL_SET=("${SKILLS[@]}")
  INSTALL_DIR="$TARGET_DIR/.claude/skills"
fi

# --- List mode ---
if [[ "$LIST_ONLY" == true ]]; then
  echo "Available skills:"
  echo ""
  for entry in "${SKILL_SET[@]}"; do
    IFS=':' read -r id src name desc <<< "$entry"
    echo "  $id  $name"
    echo "     $desc"
    echo ""
  done
  exit 0
fi

# --- Filter by selected IDs ---
if [[ ${#SELECTED_IDS[@]} -gt 0 ]]; then
  FILTERED=()
  for entry in "${SKILL_SET[@]}"; do
    IFS=':' read -r id src name desc <<< "$entry"
    for sel in "${SELECTED_IDS[@]}"; do
      if [[ "$id" == "$sel" ]]; then
        FILTERED+=("$entry")
      fi
    done
  done
  SKILL_SET=("${FILTERED[@]}")
fi

# --- Uninstall mode ---
if [[ "$UNINSTALL" == true ]]; then
  echo "Uninstalling from $INSTALL_DIR ..."
  for entry in "${SKILL_SET[@]}"; do
    IFS=':' read -r id src name desc <<< "$entry"
    if [[ -d "$INSTALL_DIR/$name" ]]; then
      run_or_print rm -rf "$INSTALL_DIR/$name"
      if [[ "$DRY_RUN" == true ]]; then
        echo "  - Would remove $name"
      else
        echo "  ✓ Removed $name"
      fi
    else
      echo "  - $name (not installed)"
    fi
  done
  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run complete. No files were changed."
  else
    echo "Done."
  fi
  exit 0
fi

# --- Install ---
echo "Installing ${#SKILL_SET[@]} skill(s) to $INSTALL_DIR ..."
echo ""

run_or_print mkdir -p "$INSTALL_DIR"

INSTALLED=0
for entry in "${SKILL_SET[@]}"; do
  IFS=':' read -r id src name desc <<< "$entry"
  SRC_PATH="$SCRIPT_DIR/$src"

  if [[ ! -d "$SRC_PATH" ]]; then
    echo "  ✗ $name — source not found: $src"
    continue
  fi

  # Remove old version if exists
  if [[ -d "$INSTALL_DIR/$name" ]]; then
    run_or_print rm -rf "$INSTALL_DIR/$name"
  fi

  run_or_print cp -r "$SRC_PATH" "$INSTALL_DIR/$name"
  if [[ "$DRY_RUN" == true ]]; then
    echo "  - Would install $name"
  else
    echo "  ✓ $name"
  fi
  INSTALLED=$((INSTALLED + 1))
done

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry-run complete. $INSTALLED skill(s) would be installed to $INSTALL_DIR"
else
  echo "Installed $INSTALLED skill(s) to $INSTALL_DIR"
fi

# --- Post-install notes ---
if [[ "$DRY_RUN" == true ]]; then
  :
elif [[ "$AGENT" == "codex" ]]; then
  echo ""
  echo "Note: Restart Codex to pick up new skills."
elif [[ "$AGENT" == "claude" ]]; then
  echo ""
  echo "Skills are ready. Claude Code will auto-detect them."
fi
