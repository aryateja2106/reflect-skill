# /reflect Skill - Phase 1 Implementation Specification

**Version:** 2.0 (Minimal Phase 1)
**Created:** 2026-01-05
**Status:** Ready for Implementation
**Scope:** Manual workflow only (Analyze → Review → Apply)
**Estimated Effort:** 2-3 hours

---

## Table of Contents

1. [Overview](#1-overview)
2. [Directory Structure](#2-directory-structure)
3. [SKILL.md Specification](#3-skillmd-specification)
4. [Workflow Specifications](#4-workflow-specifications)
5. [Shell Tool Specifications](#5-shell-tool-specifications)
6. [Templates](#6-templates)
7. [Implementation Checklist](#7-implementation-checklist)
8. [Testing Guide](#8-testing-guide)
9. [Phase 2 Preview](#9-phase-2-preview)

---

## 1. Overview

### Purpose
Enable AI coding agents to learn from user corrections and persist learnings to configuration files.

### Phase 1 Scope (This Spec)
- **Manual trigger only** (`/reflect`)
- **3 workflows**: Analyze → Review → Apply
- **Shell-based tools** (no TypeScript/Python dependencies)
- **Simple sed templates** (no Handlebars)
- **Project-level storage** for easy testing

### Out of Scope (Phase 2)
- Automatic analysis on session end (Stop hook)
- Queue system for pending reflections
- SessionStart notifications
- History logging to PAI system

### Design Principles
1. **Shell First** - Pure bash, no external dependencies
2. **Safe Append** - Never edit existing lines, only append
3. **Always Confirm** - Show preview before any file changes
4. **Git Isolated** - Only commit specific reflect files

---

## 2. Directory Structure

```
~/.claude/Skills/Reflect/
├── SKILL.md                          # Main skill file
├── IMPLEMENTATION_SPEC.md            # This document
│
├── workflows/
│   ├── Analyze.md                    # Detect corrections in session
│   ├── Review.md                     # User selection UI
│   └── Apply.md                      # Safe file updates
│
├── tools/
│   ├── DetectTarget.sh               # Find target config files
│   ├── SafeAppend.sh                 # Robust markdown append
│   └── GitSafeCommit.sh              # Isolated git commit
│
└── templates/
    └── LearningsSection.txt          # Simple text template
```

**Project-level hooks (Phase 2):**
```
.claude/
├── hooks/
│   ├── AutoReflect.sh                # Stop hook (Phase 2)
│   └── CheckQueue.sh                 # SessionStart hook (Phase 2)
└── hookify.*.local.md                # Generated rules
```

---

## 3. SKILL.md Specification

Create `~/.claude/Skills/Reflect/SKILL.md`:

```markdown
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
```

---

## 4. Workflow Specifications

### 4.1 workflows/Analyze.md

```markdown
# Analyze Workflow

Scans the current conversation for user corrections.

## Trigger
- `/reflect`
- `/reflect analyze`

## Process

### Step 1: Gather Conversation Context

Read the current conversation to find correction patterns. Look for:

**HIGH Priority - Explicit Corrections:**
- Messages containing: "don't", "never", "wrong", "stop", "instead"
- Pattern: User corrects Claude's action with explicit instruction

**MEDIUM Priority - Implicit Corrections:**
- User says "actually" and provides alternative
- User immediately rewrites Claude's code
- Same topic clarified 3+ times

**LOW Priority - Preferences:**
- "I prefer X over Y"
- "We use X in this project"

### Step 2: Extract Learnings

For each detected correction, extract:
1. **Raw quote**: User's exact words
2. **Category**: CONSTRAINT (don't do) | PATTERN (always do) | PREFERENCE
3. **Priority**: HIGH | MEDIUM | LOW
4. **Suggested rule**: Natural language rule

### Step 3: Output Format

Present findings for Review workflow:

```
## Session Analysis Results

Found **{N}** corrections in this session:

### HIGH Priority

1. **"Don't use inline styles"**
   - Category: CONSTRAINT
   - Suggested: Never use inline CSS; use Tailwind utility classes

2. **"Use bun, not npm"**
   - Category: PATTERN  
   - Suggested: Use bun instead of npm for package management

### MEDIUM Priority

3. **User replaced Grid with Flexbox**
   - Category: PREFERENCE
   - Suggested: Prefer Flexbox over CSS Grid for layouts

---

Proceed to Review workflow for approval.
```

### Step 4: No Corrections Found

If no corrections detected:

```
## Session Analysis Results

No corrections detected in this session.

This could mean:
- Great session with no issues!
- Corrections were too subtle to detect
- Try `/reflect "your specific learning"` to add manually
```

## Error Handling

| Situation | Response |
|-----------|----------|
| No conversation context | "Run /reflect after some interaction" |
| All corrections are LOW priority | Show them but note they're preferences |
```

---

### 4.2 workflows/Review.md

```markdown
# Review Workflow

Interactive review for selecting and scoping learnings.

## Trigger
- Automatically after Analyze workflow

## Input
- List of detected corrections from Analyze

## Process

### Step 1: Display Selection UI

For each learning, show:

```
┌─────────────────────────────────────────────────────────────────┐
│ SELECT LEARNINGS TO APPLY                                       │
│                                                                 │
│ [✓] 1. [HIGH] Never use inline CSS                              │
│     └─ Type: CONSTRAINT                                         │
│                                                                 │
│ [✓] 2. [HIGH] Use bun instead of npm                            │
│     └─ Type: PATTERN                                            │
│                                                                 │
│ [ ] 3. [MED] Prefer Flexbox over Grid                           │
│     └─ Type: PREFERENCE (skipped - too specific?)               │
│                                                                 │
│ Enter numbers to toggle, or 'all' / 'none' / 'done'             │
└─────────────────────────────────────────────────────────────────┘
```

### Step 2: Scope Selection

For each selected learning:

```
┌─────────────────────────────────────────────────────────────────┐
│ SCOPE: "Never use inline CSS"                                   │
│                                                                 │
│ Where should this apply?                                        │
│                                                                 │
│ [P] Project (Default) ← Recommended                             │
│     Target: ./CLAUDE.md                                         │
│     Affects: This project only                                  │
│                                                                 │
│ [G] Global                                                      │
│     Target: ~/.claude/Skills/FrontendDesign/SKILL.md            │
│     Affects: All projects using this skill                      │
│     ⚠️  Use only for truly universal rules                      │
│                                                                 │
│ [S] Skip this learning                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Step 3: Target Detection

Run `tools/DetectTarget.sh` to find the right file:

```bash
# For Project scope
./tools/DetectTarget.sh project
# Returns: ./CLAUDE.md (or .cursorrules, etc.)

# For Global scope  
./tools/DetectTarget.sh global "FrontendDesign"
# Returns: ~/.claude/Skills/FrontendDesign/SKILL.md
```

### Step 4: Preview Changes

Show exactly what will be added and where:

```
┌─────────────────────────────────────────────────────────────────┐
│ PREVIEW: ./CLAUDE.md                                            │
│                                                                 │
│ Current file ends with:                                         │
│ ───────────────────────────────────────────────────────────────│
│ 45: - Use TypeScript strict mode                                │
│ 46: - Run tests before committing                               │
│ 47:                                                             │
│ ───────────────────────────────────────────────────────────────│
│                                                                 │
│ Will append:                                                    │
│ ───────────────────────────────────────────────────────────────│
│ +                                                               │
│ + ## Learnings                                                  │
│ + <!-- Generated by /reflect | 2026-01-05 -->                   │
│ +                                                               │
│ + ### Constraints                                               │
│ + - Never use inline CSS; use Tailwind utility classes          │
│ +                                                               │
│ + ### Patterns                                                  │
│ + - Use bun instead of npm for package management               │
│ ───────────────────────────────────────────────────────────────│
│                                                                 │
│ [Apply] [Edit First] [Cancel]                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Step 5: Conflict Check

If target already has a Learnings section:

```
┌─────────────────────────────────────────────────────────────────┐
│ ℹ️  EXISTING LEARNINGS FOUND                                    │
│                                                                 │
│ File already has a Learnings section with:                      │
│ - Never commit directly to main                                 │
│ - Always use conventional commits                               │
│                                                                 │
│ New entries will be appended to existing section.               │
│                                                                 │
│ [Proceed] [View Full Section] [Cancel]                          │
└─────────────────────────────────────────────────────────────────┘
```

### Step 6: Output

Pass approved learnings to Apply workflow:

```
APPROVED_LEARNINGS:
- learning: "Never use inline CSS; use Tailwind utility classes"
  category: CONSTRAINT
  scope: PROJECT
  target: ./CLAUDE.md

- learning: "Use bun instead of npm for package management"
  category: PATTERN
  scope: PROJECT
  target: ./CLAUDE.md

SKIPPED:
- "Prefer Flexbox over Grid" (user declined)
```
```

---

### 4.3 workflows/Apply.md

```markdown
# Apply Workflow

Safely applies approved learnings to target files.

## Trigger
- After Review workflow approval
- Never runs without explicit user confirmation

## Input
- Approved learnings with scope and target from Review workflow

## Process

### Step 1: Pre-flight Checks

```bash
# For each target file:

# 1. Check if file exists or can be created
if [[ ! -f "$TARGET" ]]; then
  echo "Creating new file: $TARGET"
fi

# 2. Check write permissions
if [[ -f "$TARGET" && ! -w "$TARGET" ]]; then
  echo "ERROR: $TARGET is not writable"
  exit 1
fi

# 3. Create backup
cp "$TARGET" "${TARGET}.bak.$(date +%s)" 2>/dev/null || true
```

### Step 2: Generate Content

Use simple template substitution:

```bash
ISO_DATE=$(date +%Y-%m-%d)

# For new Learnings section:
CONTENT="
## Learnings
<!-- Generated by /reflect | $ISO_DATE -->

### Constraints
$CONSTRAINTS

### Patterns  
$PATTERNS
"

# For appending to existing section:
CONTENT="
- $LEARNING_TEXT
"
```

### Step 3: Safe Append

Run `tools/SafeAppend.sh`:

```bash
./tools/SafeAppend.sh \
  --file "$TARGET" \
  --section "## Learnings" \
  --content "$CONTENT"
```

**Critical**: This tool APPENDS to sections, never edits existing lines.

### Step 4: Git Commit (Optional)

If in a git repository:

```bash
./tools/GitSafeCommit.sh \
  --files "$TARGET" \
  --message "reflect: add $CATEGORY - $SUMMARY | $ISO_DATE"
```

### Step 5: Output Summary

```
┌─────────────────────────────────────────────────────────────────┐
│ ✅ REFLECTION COMPLETE                                          │
│                                                                 │
│ Applied 2 learnings:                                            │
│ ├─ CONSTRAINT: Never use inline CSS                             │
│ └─ PATTERN: Use bun instead of npm                              │
│                                                                 │
│ Modified: ./CLAUDE.md                                           │
│ Backup: ./CLAUDE.md.bak.1704412800                              │
│                                                                 │
│ Git commit: abc1234                                             │
│ Message: reflect: add constraints and patterns | 2026-01-05     │
└─────────────────────────────────────────────────────────────────┘
```

### Rollback

If anything fails after partial changes:

```bash
# Restore from backup
if [[ -f "${TARGET}.bak."* ]]; then
  BACKUP=$(ls -t "${TARGET}.bak."* | head -1)
  mv "$BACKUP" "$TARGET"
  echo "Rolled back to: $BACKUP"
fi
```

## Error Handling

| Error | Action |
|-------|--------|
| File not writable | Show error, suggest chmod |
| Git commit fails | Skip git, keep file changes |
| Partial failure | Rollback all changes |
```

---

## 5. Shell Tool Specifications

### 5.1 tools/DetectTarget.sh

```bash
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
```

---

### 5.2 tools/SafeAppend.sh

```bash
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

# Create file if doesn't exist
if [[ ! -f "$FILE" ]]; then
  echo "Creating new file: $FILE"
  mkdir -p "$(dirname "$FILE")"
  touch "$FILE"
fi

# Create backup
BACKUP="${FILE}.bak.$(date +%s)"
cp "$FILE" "$BACKUP"
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
    
    # Find next section header after our section
    NEXT_SECTION_LINE=$(tail -n +$((SECTION_LINE + 1)) "$FILE" | grep -n "^## " | head -1 | cut -d: -f1)
    
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
```

---

### 5.3 tools/GitSafeCommit.sh

```bash
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
# Use -- to separate options from file paths
git commit -m "$MESSAGE"

# Get commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)

echo ""
echo "Committed: $COMMIT_HASH"
echo "Message: $MESSAGE"
echo "Files: $STAGED_COUNT"
```

---

## 6. Templates

### 6.1 templates/LearningsSection.txt

Simple text template using shell variable substitution:

```
## Learnings
<!-- Generated by /reflect | __ISO_DATE__ -->

### Constraints
__CONSTRAINTS__

### Patterns
__PATTERNS__

### Preferences
__PREFERENCES__
```

**Usage in shell:**
```bash
ISO_DATE=$(date +%Y-%m-%d)
CONSTRAINTS="- Never use inline CSS; use Tailwind"
PATTERNS="- Use bun instead of npm"
PREFERENCES=""

CONTENT=$(cat templates/LearningsSection.txt | \
  sed "s/__ISO_DATE__/$ISO_DATE/g" | \
  sed "s/__CONSTRAINTS__/$CONSTRAINTS/g" | \
  sed "s/__PATTERNS__/$PATTERNS/g" | \
  sed "s/__PREFERENCES__/$PREFERENCES/g")
```

**Alternative - inline template:**
```bash
generate_learnings_section() {
  local iso_date=$(date +%Y-%m-%d)
  local constraints="$1"
  local patterns="$2"
  
  cat << EOF
## Learnings
<!-- Generated by /reflect | $iso_date -->

### Constraints
$constraints

### Patterns
$patterns
EOF
}

# Usage:
CONTENT=$(generate_learnings_section \
  "- Never use inline CSS" \
  "- Use bun instead of npm")
```

---

## 7. Implementation Checklist

### Phase 1 Implementation Order

**Step 1: Create Directory Structure** (5 min)
```bash
mkdir -p ~/.claude/Skills/Reflect/{workflows,tools,templates}
```

**Step 2: Create SKILL.md** (10 min)
- [ ] Copy SKILL.md content from Section 3
- [ ] Verify YAML frontmatter is valid
- [ ] Check USE WHEN triggers match user's language

**Step 3: Create Shell Tools** (30 min)
- [ ] Create `tools/DetectTarget.sh` from Section 5.1
- [ ] Create `tools/SafeAppend.sh` from Section 5.2
- [ ] Create `tools/GitSafeCommit.sh` from Section 5.3
- [ ] Make all executable: `chmod +x tools/*.sh`
- [ ] Test each tool independently

**Step 4: Create Workflows** (20 min)
- [ ] Create `workflows/Analyze.md` from Section 4.1
- [ ] Create `workflows/Review.md` from Section 4.2
- [ ] Create `workflows/Apply.md` from Section 4.3

**Step 5: Create Templates** (5 min)
- [ ] Create `templates/LearningsSection.txt` from Section 6.1

**Step 6: Test End-to-End** (20 min)
- [ ] Run `/reflect` in a test session
- [ ] Verify Analyze detects corrections
- [ ] Verify Review shows correct UI
- [ ] Verify Apply creates content correctly
- [ ] Verify git commit works (if in repo)

### Verification Commands

```bash
# Check directory structure
ls -la ~/.claude/Skills/Reflect/
ls -la ~/.claude/Skills/Reflect/workflows/
ls -la ~/.claude/Skills/Reflect/tools/

# Check tools are executable
file ~/.claude/Skills/Reflect/tools/*.sh

# Test DetectTarget
cd /your/project
~/.claude/Skills/Reflect/tools/DetectTarget.sh project
~/.claude/Skills/Reflect/tools/DetectTarget.sh list

# Test SafeAppend (on test file)
echo "# Test" > /tmp/test.md
~/.claude/Skills/Reflect/tools/SafeAppend.sh \
  --file /tmp/test.md \
  --section "## Learnings" \
  --content "- Test entry"
cat /tmp/test.md

# Test GitSafeCommit (in git repo)
cd /your/git/project
echo "test" >> CLAUDE.md
~/.claude/Skills/Reflect/tools/GitSafeCommit.sh \
  --files "CLAUDE.md" \
  --message "test: reflect commit"
```

---

## 8. Testing Guide

### Test Case 1: First Reflection (No Existing Learnings)

**Setup:**
- Create empty `CLAUDE.md` in project
- Have conversation where you correct Claude

**Test:**
```
User: "/reflect"
```

**Expected:**
1. Analyze shows detected corrections
2. Review presents selection UI
3. Apply creates new `## Learnings` section
4. CLAUDE.md now has learnings at end

---

### Test Case 2: Append to Existing Learnings

**Setup:**
- CLAUDE.md already has `## Learnings` section

**Test:**
```
User: "/reflect"
```

**Expected:**
1. Analyze detects new corrections
2. Review shows existing + new
3. Apply appends to existing section (doesn't duplicate header)

---

### Test Case 3: No Corrections Found

**Test:**
```
User: "/reflect"  (with no corrections in session)
```

**Expected:**
- "No corrections detected in this session"
- No file changes

---

### Test Case 4: Global Scope Selection

**Test:**
1. During Review, select "Global" scope
2. Provide skill name when prompted

**Expected:**
- DetectTarget finds skill's SKILL.md
- Content appended to skill file, not project CLAUDE.md

---

### Test Case 5: Git Commit in Non-Git Directory

**Setup:**
- Directory without `.git`

**Test:**
- Run full /reflect flow

**Expected:**
- File changes applied
- Git step skipped gracefully
- "NOTE: Not a git repository. Skipping commit."

---

## 9. Phase 2 Preview

After Phase 1 is working, Phase 2 will add:

### Automatic Analysis (Stop Hook)
```bash
# .claude/hooks/AutoReflect.sh
# Triggered on session end
# Quick scan for HIGH priority corrections only
# Queues findings to scratchpad/reflect-queue.md
```

### Queue System
```markdown
# ~/.claude/scratchpad/reflect-queue.md
## Pending from 2026-01-05T14:30:00
- "Don't use npm" (HIGH)
- "Avoid inline styles" (HIGH)
```

### Session Start Notification
```bash
# .claude/hooks/CheckQueue.sh
# Triggered on session start
# Checks queue, notifies user of pending reflections
```

### New Workflow: Process
```
User: "/reflect process"
→ Reads pending queue
→ Review UI for each item
→ Apply approved
→ Clear processed items
```

---

## Summary

**Phase 1 delivers:**
- Manual `/reflect` command
- Detect corrections in conversation
- Interactive review with scope selection
- Safe append to CLAUDE.md, .cursorrules, etc.
- Isolated git commits

**What it doesn't do (Phase 2):**
- Auto-detect on session end
- Queue pending reflections
- Notify on session start

**Files to create:**
1. `~/.claude/Skills/Reflect/SKILL.md`
2. `~/.claude/Skills/Reflect/workflows/Analyze.md`
3. `~/.claude/Skills/Reflect/workflows/Review.md`
4. `~/.claude/Skills/Reflect/workflows/Apply.md`
5. `~/.claude/Skills/Reflect/tools/DetectTarget.sh`
6. `~/.claude/Skills/Reflect/tools/SafeAppend.sh`
7. `~/.claude/Skills/Reflect/tools/GitSafeCommit.sh`
8. `~/.claude/Skills/Reflect/templates/LearningsSection.txt`

**Estimated time:** 2-3 hours for experienced developer

---

**END OF PHASE 1 SPECIFICATION**
