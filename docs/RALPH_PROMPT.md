# Ralph Prompt: Implement /reflect Skill

## Command to Run

```bash
/ralph-loop "$(cat ~/.claude/Skills/Reflect/RALPH_PROMPT.md)" --max-iterations 30 --completion-promise "REFLECT_SKILL_COMPLETE"
```

---

## Task: Implement the /reflect Skill

You are implementing the `/reflect` skill for Claude Code based on a comprehensive specification.

### Authoritative Source

**READ FIRST:** `~/.claude/Skills/Reflect/IMPLEMENTATION_SPEC.md`

This file contains the complete specification including:
- Architecture decisions
- File specifications with exact content
- Shell tool implementations
- Workflow logic
- Edge cases and error handling
- Testing criteria

### Implementation Phases

Work through these phases sequentially. Check off each item by verifying the file exists and works.

---

## Phase 1: Core Skill File

**Goal:** Create the main SKILL.md with proper USE WHEN triggers

**Tasks:**
- [ ] Read IMPLEMENTATION_SPEC.md Section 4.1 for exact content
- [ ] Create `~/.claude/Skills/Reflect/SKILL.md`
- [ ] Verify YAML frontmatter has `USE WHEN` keyword
- [ ] Verify TitleCase naming throughout
- [ ] Verify `## Workflow Routing` section exists
- [ ] Verify `## Examples` section has 3 examples

**Verification:**
```bash
# Check file exists and has required sections
grep -q "USE WHEN" ~/.claude/Skills/Reflect/SKILL.md && \
grep -q "## Workflow Routing" ~/.claude/Skills/Reflect/SKILL.md && \
grep -q "## Examples" ~/.claude/Skills/Reflect/SKILL.md && \
echo "Phase 1 PASSED" || echo "Phase 1 FAILED"
```

---

## Phase 2: Shell Tools

**Goal:** Create robust shell tools for file operations

**Tasks:**
- [ ] Read IMPLEMENTATION_SPEC.md Section 5 for exact implementations
- [ ] Create `~/.claude/Skills/Reflect/tools/detect_target.sh`
- [ ] Create `~/.claude/Skills/Reflect/tools/safe_append.sh`
- [ ] Create `~/.claude/Skills/Reflect/tools/git_safe_commit.sh`
- [ ] Create `~/.claude/Skills/Reflect/tools/parse_corrections.sh`
- [ ] Make all scripts executable: `chmod +x ~/.claude/Skills/Reflect/tools/*.sh`
- [ ] Test each tool independently

**Verification:**
```bash
# Check tools exist and are executable
ls -la ~/.claude/Skills/Reflect/tools/*.sh && \
test -x ~/.claude/Skills/Reflect/tools/detect_target.sh && \
test -x ~/.claude/Skills/Reflect/tools/safe_append.sh && \
test -x ~/.claude/Skills/Reflect/tools/git_safe_commit.sh && \
echo "Phase 2 PASSED" || echo "Phase 2 FAILED"
```

**Tool Tests:**
```bash
# Test detect_target.sh
cd /tmp && ~/.claude/Skills/Reflect/tools/detect_target.sh project
# Should output: ./CLAUDE.md

# Test safe_append.sh (dry run)
echo "# Test" > /tmp/test.md
~/.claude/Skills/Reflect/tools/safe_append.sh --file /tmp/test.md --section "## New" --content "- Item"
cat /tmp/test.md | grep -q "## New" && echo "safe_append works"
```

---

## Phase 3: Workflow Files

**Goal:** Create all workflow markdown files

**Tasks:**
- [ ] Read IMPLEMENTATION_SPEC.md Section 4.2-4.6 for exact content
- [ ] Create `~/.claude/Skills/Reflect/workflows/Analyze.md`
- [ ] Create `~/.claude/Skills/Reflect/workflows/Review.md`
- [ ] Create `~/.claude/Skills/Reflect/workflows/Apply.md`
- [ ] Create `~/.claude/Skills/Reflect/workflows/Auto.md`
- [ ] Create `~/.claude/Skills/Reflect/workflows/Process.md`

**Verification:**
```bash
# Check all workflows exist
ls ~/.claude/Skills/Reflect/workflows/*.md | wc -l | grep -q "5" && \
echo "Phase 3 PASSED" || echo "Phase 3 FAILED"
```

---

## Phase 4: Templates

**Goal:** Create content templates

**Tasks:**
- [ ] Read IMPLEMENTATION_SPEC.md Appendix A for templates
- [ ] Create `~/.claude/Skills/Reflect/templates/LearningsSection.md`
- [ ] Create `~/.claude/Skills/Reflect/templates/ConstraintEntry.md`
- [ ] Create `~/.claude/Skills/Reflect/templates/HookifyRule.md`

**Verification:**
```bash
ls ~/.claude/Skills/Reflect/templates/*.md | wc -l | grep -q "3" && \
echo "Phase 4 PASSED" || echo "Phase 4 FAILED"
```

---

## Phase 5: Hook Integration

**Goal:** Create automation hooks for Stop and SessionStart

**Tasks:**
- [ ] Read IMPLEMENTATION_SPEC.md Section 7 for hook config
- [ ] Create `~/.claude/Skills/Reflect/tools/auto_reflect.sh` (Stop hook)
- [ ] Create `~/.claude/Skills/Reflect/tools/check_queue.sh` (SessionStart)
- [ ] Make scripts executable
- [ ] Create hookify notification rule (optional)

**Verification:**
```bash
test -x ~/.claude/Skills/Reflect/tools/auto_reflect.sh && \
test -x ~/.claude/Skills/Reflect/tools/check_queue.sh && \
echo "Phase 5 PASSED" || echo "Phase 5 FAILED"
```

---

## Phase 6: Integration Testing

**Goal:** Verify end-to-end functionality

**Tasks:**
- [ ] Create a test CLAUDE.md file in /tmp
- [ ] Run detect_target.sh and verify correct detection
- [ ] Run safe_append.sh and verify content added correctly
- [ ] Verify no file corruption (YAML frontmatter preserved)
- [ ] Test git_safe_commit.sh in a test repo

**Test Script:**
```bash
#!/bin/bash
# Integration test for /reflect skill

set -e
TEST_DIR="/tmp/reflect_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Test 1: detect_target creates CLAUDE.md path
echo "Test 1: detect_target..."
result=$(~/.claude/Skills/Reflect/tools/detect_target.sh project)
[[ "$result" == "./CLAUDE.md" ]] || { echo "FAIL: detect_target"; exit 1; }
echo "PASS"

# Test 2: safe_append creates new section
echo "Test 2: safe_append new section..."
echo "# Project" > CLAUDE.md
~/.claude/Skills/Reflect/tools/safe_append.sh \
  --file CLAUDE.md \
  --section "## Learnings" \
  --content "- Test constraint"
grep -q "## Learnings" CLAUDE.md || { echo "FAIL: safe_append"; exit 1; }
grep -q "Test constraint" CLAUDE.md || { echo "FAIL: safe_append content"; exit 1; }
echo "PASS"

# Test 3: safe_append appends to existing section
echo "Test 3: safe_append existing section..."
~/.claude/Skills/Reflect/tools/safe_append.sh \
  --file CLAUDE.md \
  --section "## Learnings" \
  --content "- Another constraint"
grep -q "Another constraint" CLAUDE.md || { echo "FAIL: safe_append append"; exit 1; }
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "ALL INTEGRATION TESTS PASSED"
```

---

## Completion Criteria

All phases must pass verification. When complete:

1. Directory structure matches spec:
```
~/.claude/Skills/Reflect/
├── SKILL.md
├── IMPLEMENTATION_SPEC.md
├── workflows/
│   ├── Analyze.md
│   ├── Review.md
│   ├── Apply.md
│   ├── Auto.md
│   └── Process.md
├── tools/
│   ├── detect_target.sh (executable)
│   ├── safe_append.sh (executable)
│   ├── git_safe_commit.sh (executable)
│   ├── parse_corrections.sh (executable)
│   ├── auto_reflect.sh (executable)
│   └── check_queue.sh (executable)
└── templates/
    ├── LearningsSection.md
    ├── ConstraintEntry.md
    └── HookifyRule.md
```

2. All shell tools are executable and pass individual tests
3. Integration test script passes
4. SKILL.md has valid USE WHEN triggers

---

## Self-Correction Instructions

After each phase:
1. Run the verification command
2. If FAILED, read the error and fix
3. Re-run verification until PASSED
4. Only then proceed to next phase

If stuck for 3+ iterations on same issue:
1. Re-read the relevant section of IMPLEMENTATION_SPEC.md
2. Check file permissions
3. Check bash syntax with `bash -n script.sh`
4. Document what's blocking and try alternative approach

---

## Output When Complete

When ALL phases pass and integration tests succeed, output:

```
<promise>REFLECT_SKILL_COMPLETE</promise>

Summary:
- SKILL.md: Created with USE WHEN triggers
- Tools: 6 executable shell scripts
- Workflows: 5 workflow files
- Templates: 3 template files
- Integration: All tests passing

The /reflect skill is ready for use.
Run `/reflect` to analyze your session for corrections.
```

---

## Important Notes

- **DO NOT** modify IMPLEMENTATION_SPEC.md - it's the authoritative source
- **DO** create the tmp/ directory: `mkdir -p ~/.claude/Skills/Reflect/tmp`
- **DO** use exact content from spec for shell tools (they're battle-tested)
- **DO** test each tool before moving to next phase
- **DO NOT** skip verification steps

Begin implementation now. Start with Phase 1.
