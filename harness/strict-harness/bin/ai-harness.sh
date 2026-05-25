#!/usr/bin/env bash
set -euo pipefail

VERSION="strict-harness foundation-v0"

usage() {
  cat <<'USAGE'
ai-harness - strict AI workflow harness

Usage:
  ai-harness help
  ai-harness smoke
  ai-harness init
  ai-harness g4-start   # stub in foundation-v0
  ai-harness g4-status  # stub in foundation-v0
  ai-harness g4-close   # stub in foundation-v0
  ai-harness g5-package # stub in foundation-v0

Environment:
  AI_DEV_PROJECT_ROOT   Project root. Defaults to current working directory.
  AI_DEV_DIR            Runtime root. Defaults to <project>/.ai-dev.
USAGE
}

script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
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
  else
    pwd
  fi
}

ai_dev_dir() {
  local root
  root="$(project_root)"
  echo "${AI_DEV_DIR:-$root/.ai-dev}"
}

not_implemented() {
  local command_name="$1"
  echo "BLOCKED: '$command_name' is not implemented in $VERSION." >&2
  echo "This foundation release installs the harness skeleton only." >&2
  exit 2
}

cmd_init() {
  local dir
  dir="$(ai_dev_dir)"
  mkdir -p "$dir/runtime" "$dir/gate-artifacts"
  echo "Initialized strict harness runtime at $dir"
}

cmd_smoke() {
  local dir home failed
  dir="$(ai_dev_dir)"
  home="$(harness_home)"
  failed=0

  echo "strict-harness smoke"
  echo "version: $VERSION"
  echo "ai_dev_dir: $dir"
  echo "harness_home: ${home:-NOT_FOUND}"

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

  if [[ "$failed" -ne 0 ]]; then
    exit 1
  fi

  echo "PASS strict-harness foundation smoke"
}

command_name="${1:-help}"

case "$command_name" in
  help|--help|-h)
    usage
    ;;
  init)
    cmd_init
    ;;
  smoke)
    cmd_smoke
    ;;
  g4-start|g4-status|g4-close|g5-package)
    not_implemented "$command_name"
    ;;
  *)
    echo "Unknown command: $command_name" >&2
    usage >&2
    exit 64
    ;;
esac
