#!/usr/bin/env bash
# install.sh — AI Engineering Skills 一鍵安裝
# Usage:
#   bash install.sh                    # 安裝全部到 .claude/skills/
#   bash install.sh --codex            # 安裝到 .codex/skills/
#   bash install.sh --list             # 列出可安裝的 skill
#   bash install.sh --skill 1 3        # 只裝 Boundary-First + Adversarial Review
#   bash install.sh --target /my/proj  # 指定專案目錄
#   bash install.sh --profile strict-harness --target /my/proj
#   bash install.sh --uninstall        # 移除已安裝的 skill

set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="."
AGENT="claude"  # claude or codex
PROFILE=""
DRY_RUN=false

# --- Skill definitions ---
# Format: "id:source_dir:target_name:description"
SKILLS=(
  "0:cw-brainstorming:cw-brainstorming:Brainstorming Capture — 發想捕捉 + Discovery Gate"
  "1:claude-code/boundary-first-multi-repo-engineering:boundary-first-multi-repo-engineering:Boundary-First Engineering — 跨 repo 治理 + UGP 10 Gate"
  "2:executable-spec-planning:executable-spec-planning:Executable Spec Planning — 可執行規格書"
  "3:adversarial-code-review:adversarial-code-review:Adversarial Code Review — 證偽法審查"
  "4:usp-brainstorm:usp-brainstorm:USP Brainstorm — 產品賣點競爭分析"
)

CODEX_SKILLS=(
  "0:cw-brainstorming:cw-brainstorming:Brainstorming Capture"
  "1:codex/boundary-first-multi-repo-engineering:boundary-first-multi-repo-engineering:Boundary-First Engineering"
  "2:executable-spec-planning:executable-spec-planning:Executable Spec Planning"
  "3:adversarial-code-review:adversarial-code-review:Adversarial Code Review"
  "4:usp-brainstorm:usp-brainstorm:USP Brainstorm"
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

install_strict_harness() {
  local profile_src="$SCRIPT_DIR/harness/strict-harness"
  local install_root="$TARGET_DIR/.ai-dev"
  local runtime_dir="$install_root/runtime"
  local artifacts_dir="$install_root/gate-artifacts"
  local bin_dir="$install_root/bin"
  local harness_dir="$install_root/harness/strict-harness"
  local launcher="$bin_dir/ai-harness"

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
  run_or_print cp "$profile_src/bin/ai-harness.sh" "$launcher"
  run_or_print chmod +x "$launcher"

  echo ""
  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run complete. No files were changed."
  else
    echo "Installed strict-harness profile."
  fi
  echo "Runtime:   $runtime_dir"
  echo "Artifacts: $artifacts_dir"
  echo "Command:   $launcher"
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
    --dry-run)
      DRY_RUN=true
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
      echo "  --dry-run          Print planned filesystem actions without changing files"
      echo "  --list             List available skills"
      echo "  --uninstall        Remove installed skills"
      echo "  --help             Show this help"
      echo ""
      echo "Examples:"
      echo "  bash install.sh                     # Install all to .claude/skills/"
      echo "  bash install.sh --codex             # Install all to .codex/skills/"
      echo "  bash install.sh --skill 1 3         # Install Boundary-First + Adversarial Review"
      echo "  bash install.sh --target ~/myproj   # Install to specific project"
      echo "  bash install.sh --profile strict-harness --target ~/myproj"
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
