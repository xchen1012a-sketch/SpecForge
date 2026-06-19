#!/usr/bin/env bash
set -euo pipefail

TARGET_ROOT=""
TOOLS="generic"
ONBOARD=0
SYNC=0
APPLY=0

usage() {
  cat <<'USAGE'
SpecForge lightweight installer for macOS/Linux.

Usage:
  scripts/install.sh --target <project> [--tools codex,generic] [--onboard] [--sync] [--apply]

Notes:
  --sync updates core SpecForge files only and never overwrites ai-spec.yaml, business/, stacks/, or adapters/.
  --onboard performs a safe copy baseline; advanced slimming remains implemented in scripts/install.ps1.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET_ROOT="${2:-}"
      shift 2
      ;;
    --tools)
      TOOLS="${2:-generic}"
      shift 2
      ;;
    --onboard)
      ONBOARD=1
      shift
      ;;
    --sync)
      SYNC=1
      shift
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -z "$TARGET_ROOT" ]; then
  echo "Missing --target" >&2
  usage
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd)"
SPEC_ROOT="$TARGET_ROOT/.ai-spec"

copy_file() {
  local src="$1"
  local dst="$2"
  if [ -e "$dst" ]; then
    echo "SKIP existing $dst"
    return
  fi
  echo "CREATE $dst"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
}

sync_file() {
  local rel="$1"
  local src="$SOURCE_ROOT/$rel"
  local dst="$SPEC_ROOT/$rel"
  [ -f "$src" ] || return
  echo "SYNC $dst"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
}

if [ "$SYNC" -eq 1 ]; then
  for rel in AI-START.md README.md scripts/validate.ps1; do
    sync_file "$rel"
  done
  for dir in core core-lite contracts governance skills workflows; do
    if [ -d "$SOURCE_ROOT/$dir" ]; then
      while IFS= read -r file; do
        rel="${file#$SOURCE_ROOT/}"
        sync_file "$rel"
      done < <(find "$SOURCE_ROOT/$dir" -type f)
    fi
  done
  echo "Sync plan complete. Apply=$APPLY"
  exit 0
fi

copy_file "$SOURCE_ROOT/AI-START.md" "$SPEC_ROOT/AI-START.md"
copy_file "$SOURCE_ROOT/README.md" "$SPEC_ROOT/README.md"
copy_file "$SOURCE_ROOT/ai-spec.example.yaml" "$SPEC_ROOT/ai-spec.yaml"

for dir in adapters business contracts core core-lite governance scripts skills stacks workflows; do
  if [ -d "$SOURCE_ROOT/$dir" ]; then
    while IFS= read -r file; do
      rel="${file#$SOURCE_ROOT/}"
      copy_file "$file" "$SPEC_ROOT/$rel"
    done < <(find "$SOURCE_ROOT/$dir" -type f)
  fi
done

echo "Install plan complete. Tools=$TOOLS Onboard=$ONBOARD Apply=$APPLY"
