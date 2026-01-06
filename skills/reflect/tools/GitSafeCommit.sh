#!/bin/bash
# GitSafeCommit.sh - Safely commit only specific files
#
# Usage:
#   ./GitSafeCommit.sh --files "file1 file2 ..." --message "commit message"
#
# Safety:
#   - Only stages specified files (never git add .)
#   - Warns about existing staged changes
#   - Skips gracefully if not in git repo

set -euo pipefail

FILES=""
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --files)
      FILES="$2"
      shift 2
      ;;
    --message)
      MESSAGE="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Check if in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "NOTE: Not a git repository. Skipping commit."
  exit 0
fi

# Check for existing staged changes
EXISTING_STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
if [[ "$EXISTING_STAGED" -gt 0 ]]; then
  echo "NOTE: You have $EXISTING_STAGED other files already staged."
  echo "      These will NOT be included in the reflect commit."
fi

# Stage only our specific files
STAGED_COUNT=0
for file in $FILES; do
  if [[ -f "$file" ]]; then
    git add "$file"
    echo "Staged: $file"
    STAGED_COUNT=$((STAGED_COUNT + 1))
  else
    echo "WARNING: File not found, skipping: $file"
  fi
done

if [[ $STAGED_COUNT -eq 0 ]]; then
  echo "ERROR: No files to commit"
  exit 1
fi

# Create commit with only our files
git commit -m "$MESSAGE"

# Get commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)

echo ""
echo "Committed: $COMMIT_HASH"
echo "Message: $MESSAGE"
echo "Files: $STAGED_COUNT"
