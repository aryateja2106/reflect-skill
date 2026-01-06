---
name: Reflect
description: Learn from session corrections and update AI configuration files. USE WHEN user says 'reflect', 'learn from this', 'remember this', 'teach you', 'update skills', OR user wants to persist corrections, prevent repeated mistakes, OR mentions reflection or session learnings.
---

# Reflect

Analyzes sessions for corrections and updates configuration files to prevent repeated mistakes.

## Workflow Routing

**When executing a workflow, output this notification:**

```
Running the **WorkflowName** workflow from the **Reflect** skill...
```

| Workflow | Trigger | File |
|----------|---------|------|
| **Analyze** | `/reflect`, `/reflect analyze` | `workflows/Analyze.md` |
| **Review** | After Analyze completes | `workflows/Review.md` |
| **Apply** | After Review approval | `workflows/Apply.md` |
| **Auto** | Session end (Stop hook), `/reflect auto` | `workflows/Auto.md` |
| **Process** | `/reflect process`, after CheckQueue notification | `workflows/Process.md` |

## Examples

**Example 1: Manual reflection after work session**
```
User: "/reflect"
→ Invokes Analyze workflow
→ Scans conversation for corrections ("Don't do X", "Use Y instead")
→ Presents Review UI with detected learnings
→ User selects which to apply and chooses scope (Project/Global)
→ Safely appends to target files
→ Commits changes with timestamped message
```

**Example 2: Teach AI a new rule**
```
User: "Remember: always use bun instead of npm in this project"
→ Invokes Analyze workflow (detects explicit instruction)
→ Shows: "Detected 1 learning: Use bun instead of npm"
→ User confirms, selects Project scope
→ Appends to CLAUDE.md
```

**Example 3: After being corrected multiple times**
```
User: "/reflect" (after correcting Claude on inline CSS 3 times)
→ Detects: "Don't use inline styles" (HIGH priority - repeated)
→ Shows preview of changes to CLAUDE.md
→ User approves
→ Creates constraint: "Never use inline CSS; use Tailwind"
```

## Detection Patterns

### HIGH Priority (Explicit Corrections)
- "don't" / "dont" / "do not"
- "never"
- "wrong" / "incorrect"
- "stop doing" / "stop using"
- "use X instead" / "instead use"
- "no," followed by instruction

### MEDIUM Priority (Implicit Corrections)
- "actually, ..." followed by alternative
- User provides code immediately after Claude's attempt
- Repeated clarifications (3+ times)

### LOW Priority (Preferences)
- "I prefer"
- "let's use" / "we use"
- "in this project"

## Target Files

### Project Scope (Default)
Detects and updates (in priority order):
1. `./CLAUDE.md`
2. `./.cursorrules`
3. `./.github/copilot-instructions.md`
4. `./AGENTS.md`

### Global Scope
Updates skill files:
- `~/.claude/Skills/{SkillName}/SKILL.md`

## Safety Rules

1. **Never edit existing content** - Only append new sections/entries
2. **Always preview changes** - Show diff before applying
3. **Git isolation** - Only stage/commit reflect-modified files
4. **Backup before modify** - Create .bak file before changes

## Tools

The skill uses these shell tools located in `tools/`:

| Tool | Purpose |
|------|---------|
| `DetectTarget.sh` | Find project/global config files |
| `SafeAppend.sh` | Safely append to markdown files |
| `GitSafeCommit.sh` | Isolated git commits |
| `AutoReflect.sh` | Session-end scanner (Stop hook) |
| `CheckQueue.sh` | SessionStart notification |

## Phase 2 (Implemented)

- **Auto workflow** - Automatic analysis on session end (Stop hook)
- **Process workflow** - Process queued reflections interactively
- **AutoReflect.sh** - Lightweight scanner for Stop hook
- **CheckQueue.sh** - SessionStart notification for pending items
- **Queue system** - `~/.claude/Scratchpad/reflect-queue.md`

### Hook Integration

**Stop Hook (Auto-queue):**
```bash
# Run at session end to queue corrections
# Use ${CLAUDE_PLUGIN_ROOT} for plugin installations, or ~/.claude/Skills/reflect/tools/ for manual install
${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/AutoReflect.sh "$SESSION_ID"
```

**SessionStart Hook (Notification):**
```bash
# Check for pending reflections on session start
${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/CheckQueue.sh
```
