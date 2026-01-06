---
name: reflect
description: Learn from session corrections and update AI configuration files
---

You are running the **Reflect** skill - Learn from session corrections and update AI configuration files.

## Your Task

Analyze this conversation for user corrections and help persist learnings to configuration files.

## Workflow

**If user said `/reflect` or `/reflect analyze`:**
1. Scan conversation for correction patterns (see Detection Patterns below)
2. Extract learnings with category (CONSTRAINT/PATTERN/PREFERENCE) and priority (HIGH/MEDIUM/LOW)
3. Present findings in Review UI format
4. Ask user to select which to apply and choose scope (Project/Global)
5. Show preview of changes before applying
6. Use tools to safely append to target files

**If user said `/reflect process`:**
1. Read queue file at `~/.claude/Scratchpad/reflect-queue.md`
2. Present pending items for batch review
3. Process selected items through the Apply workflow

**If user said `/reflect auto`:**
1. Quick scan for HIGH priority corrections only
2. Queue findings to `~/.claude/Scratchpad/reflect-queue.md`
3. Silent operation - no user interaction

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
Priority order:
1. `./CLAUDE.md`
2. `./.cursorrules`
3. `./.github/copilot-instructions.md`
4. `./AGENTS.md`

### Global Scope
- `~/.claude/Skills/{SkillName}/SKILL.md`

## Tools Available

Run these shell scripts for safe operations (use `${CLAUDE_PLUGIN_ROOT}` for plugin installs):
- `${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/DetectTarget.sh project|global [skill_name]` - Find target files
- `${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/SafeAppend.sh --file FILE --section "## Learnings" --content "- Entry"` - Safe append
- `${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/GitSafeCommit.sh --files "file1" --message "msg"` - Isolated git commit
- `${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/CheckQueue.sh` - Check pending reflections
- `${CLAUDE_PLUGIN_ROOT}/skills/reflect/tools/AutoReflect.sh [session_id] [correction] [suggested]` - Queue corrections

## Safety Rules

1. **Never edit existing content** - Only append new sections/entries
2. **Always preview changes** - Show diff before applying
3. **Git isolation** - Only stage/commit reflect-modified files
4. **Backup before modify** - Tools create .bak files automatically

## Output Format

Start your response with:
```
Running the **Analyze** workflow from the **Reflect** skill...
```

Then proceed with the workflow.

$ARGUMENTS
