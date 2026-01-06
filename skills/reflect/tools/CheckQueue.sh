#!/bin/bash
# CheckQueue.sh - SessionStart notification for pending reflections
#
# Usage:
#   ./CheckQueue.sh
#
# Purpose:
#   - Checks for pending reflections in queue
#   - Outputs notification for user
#   - Called by SessionStart hook
#
# Output:
#   - Notification message if queue has items
#   - Empty/silent if no pending items
#
# Exit codes:
#   0 - Success
#   1 - Error

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.claude}"
QUEUE_FILE="${PAI_DIR}/Scratchpad/reflect-queue.md"

# Check if queue file exists and has content
if [[ ! -f "$QUEUE_FILE" ]]; then
  exit 0
fi

# Count pending items (lines starting with "- **")
PENDING_COUNT=$(grep -c '^- \*\*' "$QUEUE_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
PENDING_COUNT="${PENDING_COUNT:-0}"

if [[ "$PENDING_COUNT" -eq 0 ]]; then
  exit 0
fi

# Get the oldest pending date
OLDEST_DATE=$(grep -m1 '^## Pending from' "$QUEUE_FILE" 2>/dev/null | sed 's/## Pending from //' || echo "unknown")

# Get the most recent pending date
NEWEST_DATE=$(grep '^## Pending from' "$QUEUE_FILE" 2>/dev/null | tail -1 | sed 's/## Pending from //' || echo "unknown")

# Output notification
cat << EOF

┌─────────────────────────────────────────────────────────────────┐
│ 📝 PENDING REFLECTIONS                                          │
│                                                                 │
│ You have $PENDING_COUNT correction(s) queued from previous sessions.
│                                                                 │
│ Oldest: $OLDEST_DATE
│ Newest: $NEWEST_DATE
│                                                                 │
│ Run '/reflect process' to review and apply them.                │
└─────────────────────────────────────────────────────────────────┘

EOF

exit 0
