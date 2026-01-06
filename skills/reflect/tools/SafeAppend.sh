#!/bin/bash
# SafeAppend.sh - Safely append content to markdown files
#
# Usage:
#   ./SafeAppend.sh --file FILE --content CONTENT [--section HEADER]
#
# Strategy:
#   1. If --section given and section exists: Append AFTER section content
#   2. If --section given but doesn't exist: Create section at file end
#   3. If no --section: Append to file end
#
# CRITICAL: This script NEVER edits existing lines. Only appends.

set -euo pipefail

# Parse arguments
FILE=""
SECTION=""
CONTENT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      FILE="$2"
      shift 2
      ;;
    --section)
      SECTION="$2"
      shift 2
      ;;
    --content)
      CONTENT="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      echo "Usage: $0 --file FILE --content CONTENT [--section HEADER]" >&2
      exit 1
      ;;
  esac
done

# Validate required args
if [[ -z "$FILE" || -z "$CONTENT" ]]; then
  echo "ERROR: --file and --content are required" >&2
  exit 1
fi

# SECURITY: Validate path to prevent traversal attacks
validate_path() {
  local path="$1"
  local resolved
  resolved=$(realpath -m "$path" 2>/dev/null || echo "$path")
  
  # Block paths outside home directory
  if [[ ! "$resolved" =~ ^"$HOME" ]]; then
    echo "ERROR: Path '$path' is outside home directory. Refusing to modify." >&2
    exit 1
  fi
  
  # Block sensitive system paths
  local blocked_patterns=(
    "^/etc"
    "^/var"
    "^/usr"
    "^/bin"
    "^/sbin"
    "^/System"
    "/\.ssh/"
    "/\.gnupg/"
    "/\.aws/"
  )
  
  for pattern in "${blocked_patterns[@]}"; do
    if [[ "$resolved" =~ $pattern ]]; then
      echo "ERROR: Path '$path' matches blocked pattern. Refusing to modify." >&2
      exit 1
    fi
  done
}

validate_path "$FILE"

# Create file if doesn't exist
if [[ ! -f "$FILE" ]]; then
  echo "Creating new file: $FILE"
  mkdir -p "$(dirname "$FILE")"
  touch "$FILE"
fi

# Create backup with secure permissions
BACKUP="${FILE}.bak.$(date +%s)"
cp "$FILE" "$BACKUP"
chmod 600 "$BACKUP"
echo "Backup created: $BACKUP"

# Temp file for atomic write
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

if [[ -z "$SECTION" ]]; then
  # No section specified - simple append to end
  cat "$FILE" > "$TEMP_FILE"
  echo "" >> "$TEMP_FILE"
  echo "$CONTENT" >> "$TEMP_FILE"
else
  # Section specified - find it or create it
  if grep -q "^${SECTION}$" "$FILE"; then
    # Section EXISTS - find where it ends and append there
    # Section ends at: next "## " header OR end of file
    
    SECTION_LINE=$(grep -n "^${SECTION}$" "$FILE" | head -1 | cut -d: -f1)
    TOTAL_LINES=$(wc -l < "$FILE" | tr -d ' ')
    
    # Find next section header after our section (|| true prevents pipefail exit)
    NEXT_SECTION_LINE=$(tail -n +$((SECTION_LINE + 1)) "$FILE" | grep -n "^## " | head -1 | cut -d: -f1 || true)
    
    if [[ -n "$NEXT_SECTION_LINE" ]]; then
      # Insert BEFORE the next section (which means AFTER our section's content)
      INSERT_AT=$((SECTION_LINE + NEXT_SECTION_LINE - 1))
      
      # Content before insertion point
      head -n "$INSERT_AT" "$FILE" > "$TEMP_FILE"
      # New content
      echo "" >> "$TEMP_FILE"
      echo "$CONTENT" >> "$TEMP_FILE"
      echo "" >> "$TEMP_FILE"
      # Rest of file
      tail -n +$((INSERT_AT + 1)) "$FILE" >> "$TEMP_FILE"
    else
      # No next section - append to end of file
      cat "$FILE" > "$TEMP_FILE"
      echo "" >> "$TEMP_FILE"
      echo "$CONTENT" >> "$TEMP_FILE"
    fi
  else
    # Section DOESN'T EXIST - create it at end of file
    cat "$FILE" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "$SECTION" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "$CONTENT" >> "$TEMP_FILE"
  fi
fi

# Atomic write
mv "$TEMP_FILE" "$FILE"
echo "Successfully updated: $FILE"
