#!/bin/bash
# DetectTarget.sh - Find target configuration files
#
# Usage:
#   ./DetectTarget.sh project              # Find project-level config
#   ./DetectTarget.sh global [skill_name]  # Find global skill file
#   ./DetectTarget.sh list                 # List all available targets
#
# Exit codes:
#   0 - Success, path printed to stdout
#   1 - Error (message to stderr)

set -euo pipefail

MODE="${1:-project}"
SKILL_NAME="${2:-}"
PAI_DIR="${PAI_DIR:-$HOME/.claude}"

detect_project() {
  # Priority order for project-level configs
  local targets=(
    "./CLAUDE.md"
    "./.cursorrules"
    "./.github/copilot-instructions.md"
    "./AGENTS.md"
    "./.claude/CLAUDE.md"
  )

  for target in "${targets[@]}"; do
    if [[ -f "$target" ]]; then
      echo "$target"
      return 0
    fi
  done

  # No existing file - will create CLAUDE.md
  echo "./CLAUDE.md"
  return 0
}

detect_global() {
  local skill="$1"
  
  if [[ -z "$skill" ]]; then
    echo "ERROR: Skill name required for global scope" >&2
    echo "Usage: $0 global <skill_name>" >&2
    return 1
  fi

  local skill_path="$PAI_DIR/Skills/$skill/SKILL.md"
  
  if [[ -f "$skill_path" ]]; then
    echo "$skill_path"
    return 0
  fi

  # Try case-insensitive search
  local found
  found=$(find "$PAI_DIR/Skills" -maxdepth 2 -iname "SKILL.md" -path "*/$skill/*" 2>/dev/null | head -1)
  
  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  fi

  echo "ERROR: Skill '$skill' not found in $PAI_DIR/Skills/" >&2
  return 1
}

list_targets() {
  echo "=== Project Targets ==="
  for f in "./CLAUDE.md" "./.cursorrules" "./.github/copilot-instructions.md" "./AGENTS.md"; do
    if [[ -f "$f" ]]; then
      echo "  [EXISTS] $f"
    else
      echo "  [CREATE] $f"
    fi
  done

  echo ""
  echo "=== Global Targets (Skills) ==="
  if [[ -d "$PAI_DIR/Skills" ]]; then
    find "$PAI_DIR/Skills" -maxdepth 2 -name "SKILL.md" 2>/dev/null | while read -r skill; do
      skill_name=$(dirname "$skill" | xargs basename)
      echo "  $skill_name → $skill"
    done
  else
    echo "  No skills directory found at $PAI_DIR/Skills"
  fi
}

case "$MODE" in
  project)
    detect_project
    ;;
  global)
    detect_global "$SKILL_NAME"
    ;;
  list)
    list_targets
    ;;
  *)
    echo "Usage: $0 {project|global <skill_name>|list}" >&2
    exit 1
    ;;
esac
