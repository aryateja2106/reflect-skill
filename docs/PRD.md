# Product Requirements Document: Reflect Skill

**Version:** 1.0.0
**Author:** Arya Teja Rudraraju
**Created:** 2026-01-06
**Status:** Released (Phase 1 + Phase 2 Complete)

---

## Executive Summary

Reflect is a Claude Code plugin that enables AI coding agents to learn from user corrections and persist those learnings to configuration files. It solves the persistent problem of AI agents repeating the same mistakes because they don't remember feedback from previous sessions.

---

## Problem Statement

### The Core Problem

AI coding agents (Claude Code, Cursor, GitHub Copilot) make the same mistakes repeatedly because:

1. **No Session Memory** - Each session starts fresh with no knowledge of past corrections
2. **Manual Configuration** - Users must manually update CLAUDE.md or .cursorrules to teach preferences
3. **Lost Feedback** - Corrections made during sessions are forgotten when the session ends
4. **Repetitive Frustration** - Users find themselves saying "Don't use npm" or "Use TypeScript" repeatedly

### User Pain Points

| Pain Point | Frequency | Impact |
|------------|-----------|--------|
| Repeating the same correction | Multiple times per day | High frustration |
| Manually editing config files | Weekly | Time-consuming |
| Forgetting to document preferences | Often | Lost productivity |
| Inconsistent AI behavior across sessions | Every session | Reduced trust |

### Target Users

1. **Primary:** Developers using Claude Code daily
2. **Secondary:** Teams wanting consistent AI behavior across projects
3. **Tertiary:** Users of other AI coding tools (Cursor, Copilot) with similar config files

---

## Solution Overview

### Value Proposition

> "Teach your AI once, it remembers forever."

Reflect automatically detects when users correct their AI agent and offers to persist those corrections to configuration files, ensuring the AI remembers preferences in future sessions.

### Key Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Correction Detection** | Automatically identifies correction patterns in conversation | ✅ Implemented |
| **Interactive Review** | Presents detected learnings for user approval | ✅ Implemented |
| **Safe Append** | Never edits existing content, only adds new rules | ✅ Implemented |
| **Scope Selection** | Apply to current project or globally | ✅ Implemented |
| **Auto-Queue** | Captures corrections at session end for later review | ✅ Implemented |
| **Git Integration** | Isolated commits for reflect-modified files | ✅ Implemented |

---

## Detailed Requirements

### Functional Requirements

#### FR-1: Correction Detection

**Priority:** P0 (Must Have)

The system SHALL detect user corrections using pattern matching:

**HIGH Priority Patterns:**
- Explicit negation: "don't", "do not", "never"
- Error indication: "wrong", "incorrect"
- Cessation: "stop doing", "stop using"
- Replacement: "use X instead", "instead use"

**MEDIUM Priority Patterns:**
- Clarification: "actually..." followed by alternative
- Code replacement: User provides code immediately after AI attempt
- Repetition: Same topic clarified 3+ times

**LOW Priority Patterns:**
- Preference statement: "I prefer"
- Project convention: "we use", "in this project"

**Acceptance Criteria:**
- [ ] Detects all HIGH priority patterns with >95% accuracy
- [ ] Detects MEDIUM priority patterns with >80% accuracy
- [ ] Presents findings grouped by priority level
- [ ] Allows manual addition of learnings not auto-detected

#### FR-2: Interactive Review

**Priority:** P0 (Must Have)

The system SHALL present an interactive review interface:

```
SELECT LEARNINGS TO APPLY

[x] 1. [HIGH] Never use inline CSS
    Type: CONSTRAINT

[x] 2. [HIGH] Use bun instead of npm
    Type: PATTERN

[ ] 3. [MED] Prefer Flexbox over Grid
    Type: PREFERENCE

Select: 1,2 | all | none | done
```

**Acceptance Criteria:**
- [ ] Displays all detected learnings with priority and category
- [ ] Allows selection/deselection of individual items
- [ ] Supports bulk selection (all/none)
- [ ] Shows suggested rule text for each learning

#### FR-3: Scope Selection

**Priority:** P0 (Must Have)

The system SHALL allow users to choose where learnings are applied:

**Project Scope (Default):**
1. `./CLAUDE.md`
2. `./.cursorrules`
3. `./.github/copilot-instructions.md`
4. `./AGENTS.md`

**Global Scope:**
- `~/.claude/Skills/{SkillName}/SKILL.md`

**Acceptance Criteria:**
- [ ] Detects existing project configuration files
- [ ] Creates CLAUDE.md if no config file exists
- [ ] Allows user to choose between Project and Global scope
- [ ] Shows target file path before applying

#### FR-4: Safe Append

**Priority:** P0 (Must Have)

The system SHALL safely append content without corrupting existing files:

**Safety Rules:**
1. Never edit existing content lines
2. Only append new sections or entries within sections
3. Create timestamped backup before any modification
4. Use atomic write operations

**Acceptance Criteria:**
- [ ] Creates `.bak.{timestamp}` backup before modification
- [ ] Preserves all existing file content
- [ ] Appends to existing "Learnings" section if present
- [ ] Creates new "Learnings" section if not present
- [ ] Handles file creation if target doesn't exist

#### FR-5: Auto-Queue System

**Priority:** P1 (Should Have)

The system SHALL automatically capture corrections at session end:

**Queue Location:** `~/.claude/Scratchpad/reflect-queue.md`

**Queue Format:**
```markdown
## Pending from 2026-01-06T14:30:00Z

- **"Don't use npm, use bun"**
  - Suggested: Use bun instead of npm
  - Session: abc123
```

**Acceptance Criteria:**
- [ ] Runs lightweight scan at session end (Stop hook)
- [ ] Only captures HIGH priority corrections
- [ ] Silent operation (no user interaction)
- [ ] Notifies user of pending items at next session start

#### FR-6: Git Integration

**Priority:** P1 (Should Have)

The system SHALL commit changes with isolated git operations:

**Commit Format:**
```
reflect: add constraint - use bun not npm | 2026-01-06
```

**Safety Rules:**
- Only stage reflect-modified files
- Never run `git add .`
- Skip gracefully if not in git repository
- Warn about existing staged changes

**Acceptance Criteria:**
- [ ] Creates isolated commits for reflect changes only
- [ ] Uses consistent commit message format
- [ ] Handles non-git directories gracefully
- [ ] Does not interfere with user's staged changes

### Non-Functional Requirements

#### NFR-1: Performance

- Detection scan: < 2 seconds for typical session
- Auto-queue scan: < 500ms (session end must be fast)
- File append operation: < 100ms

#### NFR-2: Reliability

- Zero data loss: All backups must be created successfully
- Atomic writes: Partial writes must not corrupt files
- Graceful degradation: Failures should not crash the session

#### NFR-3: Compatibility

- Claude Code v2.0+
- macOS, Linux, Windows (WSL)
- Works alongside Cursor, Copilot configurations

#### NFR-4: Security

- No execution of user-provided content
- No network requests
- No access to files outside working directory and ~/.claude

---

## User Flows

### Flow 1: Manual Reflection

```
┌─────────────────────────────────────────────────────────────┐
│                    MANUAL REFLECTION FLOW                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User corrects AI during session                            │
│       │                                                     │
│       ▼                                                     │
│  User runs /reflect                                         │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────┐                   │
│  │        ANALYZE WORKFLOW             │                   │
│  │  - Scan conversation                │                   │
│  │  - Detect correction patterns       │                   │
│  │  - Extract learnings                │                   │
│  └─────────────────────────────────────┘                   │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────┐                   │
│  │        REVIEW WORKFLOW              │                   │
│  │  - Display selection UI             │                   │
│  │  - User selects learnings           │                   │
│  │  - User chooses scope               │                   │
│  │  - Preview changes                  │                   │
│  └─────────────────────────────────────┘                   │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────┐                   │
│  │        APPLY WORKFLOW               │                   │
│  │  - Create backup                    │                   │
│  │  - Safe append to target            │                   │
│  │  - Git commit (optional)            │                   │
│  │  - Show summary                     │                   │
│  └─────────────────────────────────────┘                   │
│       │                                                     │
│       ▼                                                     │
│  Learnings persisted to CLAUDE.md                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Flow 2: Auto-Queue and Process

```
┌─────────────────────────────────────────────────────────────┐
│                   AUTO-QUEUE FLOW                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Session ends (Stop hook triggered)                         │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────┐                   │
│  │        AUTO WORKFLOW                │                   │
│  │  - Quick scan (HIGH priority only)  │                   │
│  │  - Queue to reflect-queue.md        │                   │
│  │  - Silent operation                 │                   │
│  └─────────────────────────────────────┘                   │
│       │                                                     │
│       ▼                                                     │
│  New session starts (SessionStart hook)                     │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────┐                   │
│  │        NOTIFICATION                 │                   │
│  │  "You have 3 pending reflections"   │                   │
│  │  "Run /reflect process to review"   │                   │
│  └─────────────────────────────────────┘                   │
│       │                                                     │
│       ▼                                                     │
│  User runs /reflect process                                 │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────────────────────┐                   │
│  │        PROCESS WORKFLOW             │                   │
│  │  - Load queued items                │                   │
│  │  - Batch review UI                  │                   │
│  │  - Apply selected                   │                   │
│  │  - Clear processed items            │                   │
│  └─────────────────────────────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    REFLECT SKILL                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   SKILL.md  │  │  Commands   │  │  Workflows  │        │
│  │   (Entry)   │  │  /reflect   │  │  (Logic)    │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                │                │                │
│         └────────────────┼────────────────┘                │
│                          │                                 │
│                          ▼                                 │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                   SHELL TOOLS                        │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │  DetectTarget.sh  │  Find config files              │  │
│  │  SafeAppend.sh    │  Atomic file append             │  │
│  │  GitSafeCommit.sh │  Isolated git operations        │  │
│  │  AutoReflect.sh   │  Session-end scanner            │  │
│  │  CheckQueue.sh    │  Queue notification             │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                 │
│                          ▼                                 │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                 TARGET FILES                         │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │  Project: CLAUDE.md, .cursorrules, copilot-inst.md  │  │
│  │  Global:  ~/.claude/Skills/*/SKILL.md               │  │
│  │  Queue:   ~/.claude/Scratchpad/reflect-queue.md     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User Correction → Detection → Categorization → Review → Apply → Persist
     │                │              │            │         │
     │                │              │            │         └─► CLAUDE.md
     │                │              │            │
     │                │              │            └─► User Selection
     │                │              │
     │                │              └─► HIGH/MED/LOW + CONSTRAINT/PATTERN/PREF
     │                │
     │                └─► Pattern Matching (regex)
     │
     └─► "Don't use npm", "Use bun instead", etc.
```

---

## Success Metrics

### Key Performance Indicators

| Metric | Target | Measurement |
|--------|--------|-------------|
| Detection Accuracy | >90% | Manual review of detected vs actual corrections |
| User Adoption | >50% of sessions | Track /reflect usage |
| Time Saved | 5 min/session | Survey + task timing |
| Repeat Corrections | -70% | Before/after comparison |
| Configuration Updates | +200% | Compare manual vs reflect-assisted |

### User Satisfaction

- NPS Score: >50
- Task completion rate: >95%
- Error rate: <2%

---

## Roadmap

### Phase 1: Manual Workflow ✅ COMPLETE

- [x] Analyze workflow (correction detection)
- [x] Review workflow (selection UI)
- [x] Apply workflow (safe append)
- [x] Shell tools (DetectTarget, SafeAppend, GitSafeCommit)
- [x] Project scope support

### Phase 2: Automation ✅ COMPLETE

- [x] Auto workflow (session-end queue)
- [x] Process workflow (batch review)
- [x] Stop hook integration (AutoReflect.sh)
- [x] SessionStart notification (CheckQueue.sh)
- [x] Queue system

### Phase 3: Enhanced Detection (PLANNED)

- [ ] Machine learning-based detection
- [ ] Sentiment analysis for frustration signals
- [ ] Multi-turn conversation context
- [ ] Code diff analysis

### Phase 4: Team Features (PLANNED)

- [ ] Shared team configurations
- [ ] Export/import learnings
- [ ] Learning suggestions from community
- [ ] Conflict resolution for team configs

### Phase 5: Ecosystem Integration (PLANNED)

- [ ] VS Code extension
- [ ] Cursor native integration
- [ ] GitHub Copilot support
- [ ] API for third-party tools

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| File corruption | Low | High | Backup system, atomic writes |
| False positive detection | Medium | Medium | User review required |
| Performance degradation | Low | Medium | Lightweight scanning |
| Git conflicts | Medium | Low | Isolated commits |
| User confusion | Medium | Medium | Clear documentation |

---

## Appendices

### Appendix A: Detection Pattern Reference

See `IMPLEMENTATION_SPEC.md` Section 4.1 for complete pattern specifications.

### Appendix B: File Format Specifications

**Learnings Section Format:**
```markdown
## Learnings
<!-- Generated by /reflect | YYYY-MM-DD -->

### Constraints
- Never use inline CSS; use Tailwind utility classes
- Do not commit directly to main branch

### Patterns
- Use bun instead of npm for package management
- Always use TypeScript strict mode

### Preferences
- Prefer functional components over class components
```

### Appendix C: API Reference

See shell tool documentation in `skills/reflect/tools/` for usage details.

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-06 | Arya Teja Rudraraju | Initial release |

---

**END OF PRD**
