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
