# Process Workflow

Process pending reflections from the queue.

## Trigger
- `/reflect process`
- Suggested by CheckQueue hook on session start

## Purpose

Review and apply corrections that were auto-queued from previous sessions.

## Process

### Step 1: Load Queue

Read `~/.claude/Scratchpad/reflect-queue.md`:

```bash
QUEUE_FILE="${HOME}/.claude/scratchpad/reflect-queue.md"

if [[ ! -f "$QUEUE_FILE" ]] || [[ ! -s "$QUEUE_FILE" ]]; then
  echo "No pending reflections in queue."
  exit 0
fi
```

### Step 2: Parse Pending Items

Extract all pending corrections:

```
## Pending from {timestamp}
- **"{quote}"**
  - Suggested: {rule}
  - Session: {session_id}
```

Group by timestamp for context.

### Step 3: Display Review UI

Present all queued items for batch review:

```
┌─────────────────────────────────────────────────────────────────┐
│ PENDING REFLECTIONS                                             │
│                                                                 │
│ From 2026-01-05T14:30:00 (2 items):                            │
│                                                                 │
│ [✓] 1. "Don't use npm, use bun"                                │
│     └─ Use bun instead of npm for package management           │
│                                                                 │
│ [✓] 2. "Never use inline styles"                               │
│     └─ Use Tailwind utility classes instead of inline CSS      │
│                                                                 │
│ From 2026-01-04T09:15:00 (1 item):                             │
│                                                                 │
│ [ ] 3. "Wrong - use TypeScript strict mode"                    │
│     └─ Always enable strict mode in tsconfig.json              │
│     ⚠️  Older entry - consider if still relevant               │
│                                                                 │
│ Enter numbers to toggle, or 'all' / 'none' / 'done'            │
└─────────────────────────────────────────────────────────────────┘
```

### Step 4: Scope Selection

For selected items, proceed to standard Review workflow for scope selection:
- Project scope → CLAUDE.md
- Global scope → Skill files

### Step 5: Apply Changes

Use the Apply workflow for each approved item.

### Step 6: Clear Processed Items

After successful apply:

```bash
# Remove processed entries from queue
# Keep unprocessed/skipped entries

# If all processed, archive the queue
if [[ -z "$REMAINING" ]]; then
  # Archive to history
  mv "$QUEUE_FILE" "${HOME}/.claude/History/reflect-queue-$(date +%Y%m%d).md"
  echo "Queue cleared and archived."
else
  # Rewrite with remaining items
  echo "$REMAINING" > "$QUEUE_FILE"
  echo "Processed items removed from queue."
fi
```

### Step 7: Output Summary

```
┌─────────────────────────────────────────────────────────────────┐
│ ✅ QUEUE PROCESSING COMPLETE                                    │
│                                                                 │
│ Applied: 2 learnings                                            │
│ Skipped: 1 learning                                             │
│                                                                 │
│ Modified: ./CLAUDE.md                                           │
│ Queue: Archived to History/reflect-queue-20260105.md            │
│                                                                 │
│ Remaining in queue: 0                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Edge Cases

| Situation | Action |
|-----------|--------|
| Queue file missing | "No pending reflections" |
| Queue file empty | "No pending reflections" |
| All items skipped | Keep in queue for next time |
| Partial apply failure | Keep failed items in queue |
| Duplicate entries | Show warning, allow dedup |

## Deduplication

Before showing UI, check for near-duplicates:

```
Detected 2 similar entries:
- "Don't use npm" (Jan 5)
- "Use bun not npm" (Jan 4)

Consolidate into single rule? [Y/n]
```
