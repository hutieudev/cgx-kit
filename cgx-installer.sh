#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CGX — CK × GSD Hybrid Kit
# Standalone Installer v0.1.0
#
# Usage:
#   bash cgx-installer.sh                  # Install CGX (detect CK + GSD)
#   bash cgx-installer.sh --fetch-latest   # Install CGX + auto-fetch CK & GSD
#   bash cgx-installer.sh --fetch-gsd      # Install CGX + fetch latest GSD
#   bash cgx-installer.sh --fetch-ck       # Install CGX + update CK deps
#   bash cgx-installer.sh --uninstall      # Remove CGX kit
#
# Prerequisites: Node.js, npm
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Parse flags
FETCH_LATEST=false
FETCH_GSD=false
FETCH_CK=false
UNINSTALL=false
for arg in "$@"; do
  case "$arg" in
    --fetch-latest) FETCH_LATEST=true; FETCH_GSD=true; FETCH_CK=true ;;
    --fetch-gsd)    FETCH_GSD=true ;;
    --fetch-ck)     FETCH_CK=true ;;
    --uninstall)    UNINSTALL=true ;;
    --help|-h)
      echo "Usage: bash cgx-installer.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --fetch-latest   Auto-fetch latest CK + GSD"
      echo "  --fetch-gsd      Fetch/update GSD only"
      echo "  --fetch-ck       Fetch/update CK only"
      echo "  --uninstall      Remove CGX kit entirely"
      echo "  --help, -h       Show this help"
      exit 0
      ;;
  esac
done

# Paths
CGX_DIR="$HOME/.claude/cgx"
CGX_COMMANDS="$HOME/.claude/commands/cgx"
CK_SKILLS="$HOME/.claude/skills"
GSD_DIR="$HOME/.claude/get-shit-done"
GSD_COMMANDS="$HOME/.claude/commands/gsd"
CGX_VERSION="0.8.2"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Uninstall
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ "$UNINSTALL" = true ]; then
  echo -e "${CYAN}${BOLD}Uninstalling CGX...${NC}"
  rm -rf "$CGX_DIR" "$CGX_COMMANDS"
  # Remove CGX rules from CLAUDE.md
  CLAUDE_MD="$HOME/.claude/CLAUDE.md"
  if [ -f "$CLAUDE_MD" ]; then
    sed '/<!-- CGX-AUTO-ROUTING -->/,/<!-- \/CGX-AUTO-ROUTING -->/d' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
  fi
  echo -e "${GREEN}✓${NC} CGX removed. CK and GSD are untouched."
  exit 0
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Banner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}  CGX — CK × GSD Hybrid Kit v${CGX_VERSION}${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
  echo -e "${RED}✗ Node.js not found. Please install Node.js first.${NC}"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1: Create directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[1/7] Creating directories...${NC}"
mkdir -p "$CGX_DIR" "$CGX_COMMANDS"
echo -e "  ${GREEN}✓${NC} $CGX_DIR"
echo -e "  ${GREEN}✓${NC} $CGX_COMMANDS"

# Copy installer to CGX dir for self-reference
cp "$0" "$CGX_DIR/install.sh" 2>/dev/null || true
chmod +x "$CGX_DIR/install.sh" 2>/dev/null || true

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Write runtime utilities
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[2/7] Writing runtime utilities...${NC}"

# check-prerequisites.cjs
cat > "$CGX_DIR/check-prerequisites.cjs" << 'UTILEOF'
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const CONFIG_PATH = path.join(__dirname, 'config.json');
const flag = process.argv[2] || '--summary';
let config;
try { config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')); }
catch { config = { ck: { detected: false }, gsd: { detected: false }, integrations: {} }; }
const ck = config.ck?.detected || false;
const gsd = config.gsd?.detected || false;
let mode = 'none';
if (ck && gsd) mode = 'hybrid';
else if (ck) mode = 'ck-only';
else if (gsd) mode = 'gsd-only';
if (flag === '--json') {
  console.log(JSON.stringify({ ck, gsd, mode, version: config.version || '0.1.0' }));
} else {
  const status = [`CGX mode: ${mode}`];
  if (ck) status.push(`CK: ${config.ck.skillCount || '?'} skills`);
  if (gsd) status.push(`GSD: v${config.gsd.version || '?'}`);
  console.log(status.join(' | '));
}
UTILEOF
echo -e "  ${GREEN}✓${NC} check-prerequisites.cjs"

# output-format.md — shared output guidelines for all CGX commands
cat > "$CGX_DIR/output-format.md" << 'FMTEOF'
# CGX Output Format Guidelines

ALL CGX command outputs MUST follow these rules:

## 1. Use Tables for Multi-Item Results
```
| Step     | Status   | Details             |
|----------|----------|---------------------|
| Review   | ✓ Pass   | 3 issues fixed      |
| Test     | ✓ Pass   | 85% coverage        |
| Verify   | ✓ Pass   | Goal achieved       |
```

## 2. Use Progress Bars for % Values
```
Understanding: 73% ████████████████░░░░░░
Coverage:      85% █████████████████████░
```

## 3. Use Status Icons
- ✓ = passed/done/yes
- ✗ = failed/no
- ⟳ = in progress
- ⚠ = warning
- → = next action

## 4. Use Section Headers with Lines
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Section Title
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 5. Keep Text Minimal
- Lead with data, not prose
- One-line summaries, not paragraphs
- Use `key: value` format for properties
- List actions as `→ /cgx:next-command`

## 6. Report Template
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:<command> — Result
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Step      | Status | Details    |
|-----------|--------|------------|
| ...       | ✓/✗    | ...        |

Summary: <one line>
→ Next: /cgx:<suggested>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
FMTEOF
echo -e "  ${GREEN}✓${NC} output-format.md"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: Detect CK + GSD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[3/7] Detecting installed systems...${NC}"

CK_FOUND=false
CK_SKILL_COUNT=0
if [ -d "$CK_SKILLS" ] && [ "$(ls -A "$CK_SKILLS" 2>/dev/null | head -1)" ]; then
  CK_SKILL_COUNT=$(ls -d "$CK_SKILLS"/*/ 2>/dev/null | wc -l | tr -d ' ')
  CK_FOUND=true
  echo -e "  ${GREEN}✓${NC} ClaudeKit — ${CK_SKILL_COUNT} skills"
else
  echo -e "  ${YELLOW}✗${NC} ClaudeKit not found"
fi

GSD_FOUND=false
GSD_VERSION="unknown"
GSD_COMMAND_COUNT=0
if [ -d "$GSD_DIR" ] && [ -f "$GSD_DIR/VERSION" ]; then
  GSD_VERSION=$(cat "$GSD_DIR/VERSION" 2>/dev/null || echo "unknown")
  GSD_COMMAND_COUNT=$(find "$GSD_COMMANDS" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  GSD_FOUND=true
  echo -e "  ${GREEN}✓${NC} GSD v${GSD_VERSION} — ${GSD_COMMAND_COUNT} commands"
else
  echo -e "  ${YELLOW}✗${NC} GSD not found"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 4: Auto-fetch if requested
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[4/7] Fetching latest versions...${NC}"

if [ "$FETCH_GSD" = true ]; then
  echo -e "  ${CYAN}↓${NC} Fetching latest GSD via npm..."
  GSD_LATEST=$(npm view get-shit-done-cc version 2>/dev/null || echo "unknown")
  echo -e "  ${CYAN}↓${NC} Latest: ${BOLD}v${GSD_LATEST}${NC}"
  npx -y get-shit-done-cc@latest --claude --global 2>&1 | tail -3
  if [ -f "$GSD_DIR/VERSION" ]; then
    GSD_VERSION=$(cat "$GSD_DIR/VERSION")
    GSD_COMMAND_COUNT=$(find "$GSD_COMMANDS" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    GSD_FOUND=true
    echo -e "  ${GREEN}✓${NC} GSD installed → v${GSD_VERSION}"
  fi
elif [ "$GSD_FOUND" = true ]; then
  GSD_LATEST=$(npm view get-shit-done-cc version 2>/dev/null || echo "")
  if [ -n "$GSD_LATEST" ] && [ "$GSD_LATEST" != "$GSD_VERSION" ]; then
    echo -e "  ${YELLOW}↑${NC} GSD update: v${GSD_VERSION} → v${GSD_LATEST} ${DIM}(re-run with --fetch-gsd)${NC}"
  else
    echo -e "  ${GREEN}✓${NC} GSD up to date"
  fi
fi

if [ "$FETCH_CK" = true ]; then
  CK_GLOBAL="$HOME/.claude/skills"
  CK_LOCAL=".claude/skills"
  if [ -f "$CK_GLOBAL/install.sh" ]; then
    echo -e "  ${CYAN}↓${NC} Updating CK dependencies (global)..."
    cd "$CK_GLOBAL" && bash install.sh -y 2>&1 | tail -3
    cd - > /dev/null
    CK_SKILL_COUNT=$(ls -d "$CK_GLOBAL"/*/ 2>/dev/null | wc -l | tr -d ' ')
    CK_FOUND=true
    echo -e "  ${GREEN}✓${NC} CK updated — ${CK_SKILL_COUNT} skills"
  elif [ -f "$CK_LOCAL/install.sh" ]; then
    echo -e "  ${CYAN}↓${NC} Updating CK dependencies (local)..."
    cd "$CK_LOCAL" && bash install.sh -y 2>&1 | tail -3
    cd - > /dev/null
    CK_FOUND=true
    echo -e "  ${GREEN}✓${NC} CK updated"
  else
    echo -e "  ${YELLOW}⚠${NC} CK install.sh not found — install CK manually first"
  fi
elif [ "$CK_FOUND" = false ] && [ "$FETCH_LATEST" = false ]; then
  echo -e "  ${DIM}CK: skipped (not found, use --fetch-ck)${NC}"
else
  echo -e "  ${GREEN}✓${NC} CK check complete"
fi

# Validate
if [ "$CK_FOUND" = false ] && [ "$GSD_FOUND" = false ]; then
  echo ""
  echo -e "  ${RED}✗ Neither CK nor GSD found.${NC}"
  echo -e "  Re-run with ${BOLD}--fetch-latest${NC} to auto-install both."
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 5: Write all CGX commands (guided pipeline — no Skill delegation)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[5/7] Installing CGX commands...${NC}"

# --- cgx:install ---
cat > "$CGX_COMMANDS/install.md" << 'CMD_EOF'
---
name: cgx:install
description: Detect CK + GSD installations and setup CGX hybrid kit
allowed-tools: [Bash, Read, AskUserQuestion]
---
<objective>Run CGX installer to detect systems and verify readiness.</objective>
<process>
## 1. Run Installer
```bash
bash "$HOME/.claude/cgx/install.sh"
```
## 2. Verify
```bash
node "$HOME/.claude/cgx/check-prerequisites.cjs" --json
```
Report detected mode. Show commands with `/cgx:help`.
<format>Follow ~/.claude/cgx/output-format.md — use tables, status icons, progress bars. No prose paragraphs.</format>
</process>
CMD_EOF

# --- cgx:help ---
cat > "$CGX_COMMANDS/help.md" << 'CMD_EOF'
---
name: cgx:help
description: Show all CGX hybrid commands and usage guide
---
<objective>Display CGX command reference.</objective>
<process>
```bash
node "$HOME/.claude/cgx/check-prerequisites.cjs" --summary
```
Then display the command table:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CGX v0.8.0 — Guided Pipeline Kit

DISCOVERY
  /cgx:think <topic>    Clarify → Research → Brainstorm → Vision (--quick for clarify only)

WORKFLOW
  /cgx:new              Init project structure + roadmap
  /cgx:plan <phase>     Research + plan (--research-only for standalone)
  /cgx:execute <phase>  Build + review + test + verify
  /cgx:autonomous       Auto-loop all phases

QUICK
  /cgx:do <text>        Smart router
  /cgx:quick <task>     Bug/feature auto-detect + commit + test
  /cgx:debug <issue>    Root cause analysis + fix

QUALITY
  /cgx:review <phase>   Review + test + simplify (--test-only, --simplify)
  /cgx:ui <phase>       UI design + build + 6-pillar audit (--from-image, --audit, --optimize)

KNOWLEDGE
  /cgx:docs [action]    Documentation sync

SESSION
  /cgx:progress         Dashboard (--pause, --resume)

SETUP
  /cgx:install          Detect CK + GSD
  /cgx:update           Fetch latest versions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:update ---
cat > "$CGX_COMMANDS/update.md" << 'CMD_EOF'
---
name: cgx:update
description: Update CK + GSD to latest versions and refresh CGX config
argument-hint: "[--ck-only] [--gsd-only]"
allowed-tools: [Bash, Read, AskUserQuestion]
---
<objective>Fetch latest CK and GSD, refresh config.</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Check current versions
```bash
node "$HOME/.claude/cgx/check-prerequisites.cjs" --json
```
## 2. Update GSD (skip if --ck-only)
```bash
npx -y get-shit-done-cc@latest --claude --global
```
## 3. Update CK (skip if --gsd-only)
```bash
bash "$HOME/.claude/cgx/install.sh" --fetch-ck
```
## 4. Refresh CGX config
```bash
bash "$HOME/.claude/cgx/install.sh"
```
Display before/after versions table.
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:do ---
cat > "$CGX_COMMANDS/do.md" << 'CMD_EOF'
---
name: cgx:do
description: Smart router — describe what you want, routes to the best CGX command
argument-hint: "<description>"
allowed-tools: [Read, Bash, AskUserQuestion]
---
<objective>Analyze text → route to best CGX command. Show routing table, then invoke.</objective>
<context>$ARGUMENTS</context>
<process>
If empty, ask user what they want to do.
Route by first match:
| Intent                          | Route                      |
|---------------------------------|----------------------------|
| Unclear, vague, discuss         | /cgx:think --quick         |
| Strategy, vision, evaluate      | /cgx:think                 |
| New project, initialize         | /cgx:new                   |
| Quick fix, small bug            | /cgx:quick --fix           |
| Complex bug, investigate        | /cgx:debug                 |
| Plan, research, approach        | /cgx:plan                  |
| Build, implement                | /cgx:execute               |
| Review, quality, test           | /cgx:review                |
| UI, frontend, design            | /cgx:ui                    |
| Documentation                   | /cgx:docs                  |
| Progress, status                | /cgx:progress              |
| Auto all phases                 | /cgx:autonomous            |
| Small task                      | /cgx:quick                 |
If ambiguous: ask user with 2-3 options via AskUserQuestion.
Display: `→ Routing to /cgx:<match>` then invoke.
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:new ---
cat > "$CGX_COMMANDS/new.md" << 'CMD_EOF'
---
name: cgx:new
description: New project — guided setup with direct tool operations
argument-hint: "[project description]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Set up new project with guided pipeline. CGX stays in control throughout — no skill delegation.
</objective>
<context>$ARGUMENTS</context>
<process>
## GUIDED PIPELINE — CGX stays in control

### Step 1: Gather Requirements
Use AskUserQuestion to ask:
- Project name and description?
- Tech stack (frontend, backend, database)?
- Key features (list 3-5 core features)?
- Target users?
- Any constraints (timeline, existing code, team size)?

Show understanding % after answers.

### Step 2: Create Project Structure
Using Write tool, create:
```
.planning/
├── PROJECT.md      ← from user answers
├── ROADMAP.md      ← 5-8 phases max
└── STATE.md        ← "Phase 1 - not started"

docs/
├── project-overview-pdr.md
├── system-architecture.md
├── code-standards.md
└── codebase-summary.md
```

ROADMAP.md rules:
- MAX 8 phases (gộp nếu cần)
- Each phase = 1 deliverable rõ ràng
- Phase 1 always = project setup + config

### Step 3: Research (optional)
Spawn 1 researcher Agent to check latest docs for chosen tech stack.

### Step 4: Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:new — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Item        | Status | Details           |
|-------------|--------|-------------------|
| PROJECT.md  | ✓      | Created           |
| ROADMAP.md  | ✓      | N phases          |
| docs/       | ✓      | 4 files           |

→ Next: /cgx:plan 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:plan ---
cat > "$CGX_COMMANDS/plan.md" << 'CMD_EOF'
---
name: cgx:plan
description: Research + Plan — guided pipeline with direct operations
argument-hint: "<phase-number> [--research-only] [--skip-research] [--deep]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Plan a phase with integrated research. CGX stays in control — uses tools directly.
</objective>
<context>$ARGUMENTS</context>
<process>
## GUIDED PIPELINE

### Step 1: Read Context
- Read .planning/ROADMAP.md to get phase description
- Read .planning/PROJECT.md for project context
- Read .planning/STATE.md for current status
- Scan codebase with Glob/Grep for related existing code

### Step 2: Research (skip if --skip-research)
- Spawn researcher Agent to look up latest docs for technologies in this phase
- If --deep: spawn 2 researcher Agents for different aspects
- Scan codebase for patterns, existing implementations
- Output research findings as table

If --research-only: output report and STOP.

### Step 3: Create Plan
Using Write tool, create `.planning/phase-N/PLAN.md`:
- Tasks breakdown (numbered, specific)
- Files to create/modify
- Dependencies between tasks
- Success criteria
- Estimated complexity per task

### Step 4: Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:plan Phase N — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Step     | Status | Details              |
|----------|--------|----------------------|
| Context  | ✓      | Read 3 files         |
| Research | ✓      | N findings           |
| Plan     | ✓      | N tasks              |

→ Next: /cgx:execute N
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:execute ---
cat > "$CGX_COMMANDS/execute.md" << 'CMD_EOF'
---
name: cgx:execute
description: Execute phase — build + review + test + verify with guided pipeline
argument-hint: "<phase-number> [--skip-review] [--skip-test]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Build phase code, then quality gates. CGX stays in control throughout.
</objective>
<context>Phase: $ARGUMENTS</context>
<process>
## GUIDED PIPELINE

### Step 1: Read Plan
- Read `.planning/phase-N/PLAN.md` for tasks
- Show task checklist to user

### Step 2: Build
- Implement each task from the plan
- Use Edit/Write tools directly
- After each task: run compile/lint check via Bash
- Mark tasks done in checklist
- Commit after each logical unit (git add + commit)

### Step 3: Review (skip if --skip-review)
- Spawn code-reviewer Agent on changed files
- Fix critical issues found
- Show review results table

### Step 4: Test (skip if --skip-test)
- Spawn tester Agent to run tests
- Fix failing tests
- Show test results table

### Step 5: Verify
- Read phase plan success criteria
- Check each criterion against implementation
- Update .planning/STATE.md

### Step 6: Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:execute Phase N — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Step    | Status | Details            |
|---------|--------|--------------------|
| Build   | ✓      | N tasks done       |
| Review  | ✓      | N issues fixed     |
| Test    | ✓      | N/N passed         |
| Verify  | ✓      | Criteria met       |

→ Next: /cgx:plan N+1 or /cgx:progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:quick ---
cat > "$CGX_COMMANDS/quick.md" << 'CMD_EOF'
---
name: cgx:quick
description: Quick task — auto-detect bug/feature, implement + commit + test
argument-hint: "<task or bug description> [--fix] [--feature] [--no-test]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Quick action with direct implementation. No skill delegation.
</objective>
<context>$ARGUMENTS</context>
<process>
## GUIDED PIPELINE

### Step 1: Detect Intent
- Bug keywords (fix, bug, error, crash, broken, wrong, fail, issue, not working) → bug mode
- Everything else → feature mode
- Or use --fix / --feature flag

### Step 2: Analyze (bug mode — enhanced with CK fix methodology)
Apply systematic root cause analysis:
1. **Reproduce**: Try to trigger the bug via Bash (run command, test, curl)
2. **Collect evidence**: Read error messages, stack traces, logs
3. **Trace the chain**: Grep for error origin → follow call chain through files
4. **Identify root cause**: Classify the bug type:
   | Type           | Look for                              |
   |----------------|---------------------------------------|
   | Logic error    | Wrong condition, missing case          |
   | Type mismatch  | null/undefined, wrong type passed      |
   | State bug      | Race condition, stale state            |
   | Integration    | API contract mismatch, wrong endpoint  |
   | Config         | Wrong env var, missing setting         |
5. **Check for related bugs**: Grep for similar patterns elsewhere — same bug might exist in multiple places

### Step 2b: Analyze (feature mode)
- Understand requirement from description
- Scan codebase with Glob/Grep for where to implement
- Check existing patterns to follow (consistency)

### Step 3: Plan Fix/Feature
Before implementing, outline:
```
Root cause: <what's wrong>
Fix: <what to change>
Files: <which files>
Risk: <what could break>
```

### Step 4: Implement
- Make changes using Edit/Write tools
- Run compile/lint check via Bash
- If fix doesn't work on first attempt:
  - Re-analyze with different hypothesis
  - Check if fix introduced new issues
  - Apply problem-solving techniques: simplify the problem, isolate variables

### Step 5: Commit
```bash
git add <changed files>
git commit -m "<type>: <description>"
```

### Step 6: Verify (skip if --no-test)
- **Reproduce test**: Re-run the original failing scenario → must pass now
- **Regression test**: Run full test suite → no new failures
- **Edge cases**: Test boundary conditions related to the fix
- If tests fail: go back to Step 4, fix again

### Step 7: Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:quick — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Item       | Details               |
|------------|-----------------------|
| Mode       | bug/feature           |
| Root cause | <if bug>              |
| Changes    | N files modified      |
| Commit     | abc1234               |
| Tests      | ✓ N/N passed          |
| Related    | N similar spots checked|
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:debug ---
cat > "$CGX_COMMANDS/debug.md" << 'CMD_EOF'
---
name: cgx:debug
description: Systematic debug — root cause analysis + fix + verify
argument-hint: "<issue description>"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Debug with scientific method. CGX stays in control.
</objective>
<context>$ARGUMENTS</context>
<process>
## GUIDED PIPELINE

### Step 1: Reproduce
- Understand the issue from description
- Try to reproduce via Bash (run commands, tests)
- Collect error messages, stack traces

### Step 2: Investigate
- Grep codebase for related code
- Read relevant files
- Form hypothesis about root cause
- Save checkpoint: Write findings to .planning/DEBUG.md

### Step 3: Fix
- Implement fix using Edit tool
- Run compile check

### Step 4: Verify
- Re-run the reproduction steps
- Run related tests
- Confirm issue is resolved

### Step 5: Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:debug — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Item       | Details               |
|------------|-----------------------|
| Issue      | <description>         |
| Root cause | <what was wrong>      |
| Fix        | <what was changed>    |
| Verified   | ✓                     |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:progress ---
cat > "$CGX_COMMANDS/progress.md" << 'CMD_EOF'
---
name: cgx:progress
description: Progress dashboard + session management (--pause, --resume)
argument-hint: "[--pause [notes]] [--resume]"
allowed-tools: [Read, Write, Glob, Grep, Bash, AskUserQuestion]
---
<objective>
Show project progress using direct file reads. No skill delegation.
</objective>
<context>$ARGUMENTS</context>
<process>
## If --pause:
1. Check uncommitted changes: `git status`
2. Write handoff file: `.planning/HANDOFF.md` with current context
3. Show session summary (git log, files changed)
→ STOP

## If --resume:
1. Read `.planning/HANDOFF.md` if exists
2. Check `git status`, recent `git log`
3. Read `.planning/STATE.md` for current phase
4. Suggest next action
→ STOP

## Default — Dashboard:
1. Read `.planning/ROADMAP.md` → show phase table with status
2. Read `.planning/STATE.md` → current phase
3. Check `git log --oneline -10` → recent activity
4. Check `git status` → uncommitted work
5. Show dashboard:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Phase | Name          | Status      |
|-------|---------------|-------------|
| 1     | Setup         | ✓ Done      |
| 2     | Database      | ⟳ Building  |
| 3     | API           | — Planned   |

Current: Phase 2 | Git: clean
→ Next: /cgx:execute 2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:review ---
cat > "$CGX_COMMANDS/review.md" << 'CMD_EOF'
---
name: cgx:review
description: Quality gate — review + test + simplify + verify
argument-hint: "<phase-number|file-path> [--test-only] [--simplify] [--coverage]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Quality checks with direct operations and Agent subagents.
</objective>
<context>$ARGUMENTS</context>
<process>
## Determine scope: phase number → find changed files, file path → specific file

## If --simplify:
1. Read target files, identify simplification opportunities
2. Apply simplifications using Edit tool
3. Run tests via Bash
4. Commit: `git commit -m "refactor: simplify"`
5. Report table
→ STOP

## If --test-only:
1. Run test suite via Bash
2. Show pass/fail table
3. If --coverage: analyze coverage output
→ STOP

## Full review (default):
1. Spawn code-reviewer Agent on changed files
2. Fix critical issues from review
3. Run tests via Bash
4. Check phase success criteria from .planning/
5. Report:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:review — Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Check    | Status | Details         |
|----------|--------|-----------------|
| Review   | ✓ Pass | 0 critical      |
| Tests    | ✓ Pass | 12/12           |
| Criteria | ✓ Met  | 3/3             |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:autonomous ---
cat > "$CGX_COMMANDS/autonomous.md" << 'CMD_EOF'
---
name: cgx:autonomous
description: Full auto — loop plan + execute for all remaining phases
argument-hint: "[--from N]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Auto-execute remaining phases. CGX stays in control — runs plan + execute inline.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Read .planning/ROADMAP.md → find incomplete phases
## 2. For each phase N (starting from --from or first incomplete):
  a. Show: `⟳ Phase N: <name>`
  b. Run plan steps inline (read context, create PLAN.md)
  c. Run execute steps inline (build, review, test, verify)
  d. Show phase result table
  e. If failure: ask user to fix or skip
## 3. After all phases: show final summary
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:autonomous — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Phase | Name      | Status |
|-------|-----------|--------|
| 1     | Setup     | ✓ Done |
| 2     | Database  | ✓ Done |
| ...   | ...       | ...    |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:ui ---
cat > "$CGX_COMMANDS/ui.md" << 'CMD_EOF'
---
name: cgx:ui
description: UI phase — design + build + audit with full frontend intelligence
argument-hint: "<phase-number|file-path> [--from-image <path>] [--audit] [--optimize]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Full frontend pipeline with design intelligence. CGX stays in control.
Modes: design+build (default), clone from image, audit existing, optimize.
</objective>
<context>$ARGUMENTS</context>
<process>
## GUIDED PIPELINE

### Step 0: Detect Mode
- Default (phase number): full design → build → audit
- --from-image <path>: clone UI from screenshot/design
- --audit: audit existing UI code only
- --optimize: performance optimization only

### Step 1: Design Spec (skip if --audit or --optimize)

**If --from-image:**
- Read the image file using Read tool
- Analyze: layout structure, colors, typography, spacing, components
- Generate UI-SPEC.md from image analysis
- Ask user to confirm/adjust via AskUserQuestion

**Default:**
- Read phase plan from .planning/
- Ask user via AskUserQuestion:
  - Design style? (options: minimalist, glassmorphism, brutalism, bento grid, neumorphism, flat, material)
  - Color palette? (options: monochrome, ocean, sunset, forest, neon, pastel, custom)
  - Component library? (detect from package.json: shadcn/ui, MUI, Tailwind, vanilla CSS)
  - Font pairing preference? (modern, classic, playful, technical)
  - Dark mode support? (yes/no/both)
  - Mobile-first? (yes/no)

- Write UI-SPEC.md to .planning/phase-N/:
  ```
  # UI-SPEC: Phase N
  Style: <chosen>
  Palette: <colors with hex>
  Components: <library>
  Fonts: <primary> + <secondary>
  Breakpoints: mobile 640px, tablet 768px, desktop 1024px
  Dark mode: <yes/no>
  ```

### Step 2: Build (skip if --audit or --optimize)
- Scan existing components: Glob for *.tsx, *.vue, *.svelte in src/
- Implement components following UI-SPEC.md:
  - Use correct component library syntax (shadcn/ui, MUI, etc.)
  - Apply chosen palette colors consistently
  - Implement responsive breakpoints
  - Add dark mode variants if specified
- After each component: run build check via Bash
- Commit after each logical component group

### Step 3: Audit (always runs, or standalone with --audit)
Run 6-pillar UI audit directly:

**Pillar 1 — Accessibility (A11y):**
- Grep for missing alt, aria-*, role attributes
- Check color contrast ratios (WCAG AA: 4.5:1)
- Verify keyboard navigation (tabIndex, focus states)
- Check form labels and error messages

**Pillar 2 — Responsive:**
- Grep for hardcoded px values (should use rem/em or responsive units)
- Check for mobile breakpoints in CSS/Tailwind
- Verify no horizontal scroll on mobile viewport

**Pillar 3 — Performance:**
- Check image optimization (next/image, lazy loading)
- Look for large bundle imports (lodash full, moment.js)
- Verify dynamic imports / code splitting for heavy components
- Check for unnecessary re-renders (memo, useMemo, useCallback)

**Pillar 4 — Consistency:**
- Verify design tokens used consistently (colors, spacing, typography)
- Check component naming conventions
- Verify consistent spacing system (4px/8px grid)

**Pillar 5 — UX Patterns:**
- Loading states (skeleton, spinner)
- Error states (error boundaries, fallbacks)
- Empty states (placeholder content)
- Hover/focus/active states on interactive elements

**Pillar 6 — Code Quality:**
- Component size (< 200 lines each)
- Props interface defined (TypeScript)
- Separation of concerns (logic vs presentation)

### Step 4: Optimize (if --optimize or issues found in audit)
- Fix critical audit findings
- Add missing accessibility attributes
- Replace heavy imports with lighter alternatives
- Add missing responsive styles
- Implement missing loading/error states

### Step 5: Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:ui — Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Pillar       | Score | Issues |
|--------------|-------|--------|
| Accessibility| 90%   | 2 minor|
| Responsive   | 95%   | 1 fix  |
| Performance  | 85%   | 3 opts |
| Consistency  | 100%  | —      |
| UX Patterns  | 80%   | 2 miss |
| Code Quality | 95%   | 1 split|

Overall: 91% ██████████████████████░░
Fixes applied: 5 | Remaining: 4 minor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# Remove old merged commands
rm -f "$CGX_COMMANDS/fix.md" "$CGX_COMMANDS/research.md" "$CGX_COMMANDS/test.md" \
      "$CGX_COMMANDS/simplify.md" "$CGX_COMMANDS/pause.md" "$CGX_COMMANDS/resume.md" \
      "$CGX_COMMANDS/clarify.md"

# --- cgx:think --- (kept as-is — already uses AskUserQuestion directly)
cat > "$CGX_COMMANDS/think.md" << 'CMD_EOF'
---
name: cgx:think
description: Deep thinking — clarify (100%) → research → brainstorm → strategic vision
argument-hint: "<topic or problem> [--quick] [--skip-clarify] [--no-log]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Full thinking pipeline. CGX stays in control — uses AskUserQuestion and Agent directly.
Use --quick for clarify-only mode.
</objective>
<context>$ARGUMENTS</context>
<process>
## Activity Log
Maintain running log after EACH phase:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:think — Activity Log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| #  | Phase     | Status | Key Finding              |
|----|-----------|--------|--------------------------|
| 1  | Clarify   | ✓ Done | 100% understanding       |
| 2  | Research  | ⟳ Now  | searching docs...        |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Mode (--quick)
Run ONLY Phase 1 → output brief → route. Skip rest.

## Phase 1: Clarify (skip if --skip-clarify)
Ask questions via AskUserQuestion until 100% understanding:
- Core problem/opportunity?
- Success outcome?
- Constraints (tech, time, team)?
- Who benefits?
- Prior attempts?

Show understanding % bar after each answer. Keep asking until 100%.

## Phase 2: Research
- Spawn 1-2 researcher Agents (via Agent tool) for:
  - Latest docs and best practices
  - Similar implementations
- Scan codebase with Glob/Grep for related code
- Output findings table

## Phase 3: Brainstorm
- Generate 3 approaches based on research
- Evaluate each: pros, cons, effort, risk
- Output comparison table

## Phase 4: Vision
Write strategic vision document:
- Target summary
- Recommended approach + rationale
- Implementation roadmap table (5-8 phases max)
- Key risks + mitigations
- Success metrics

Save to plans/reports/ unless --no-log.

## Phase 5: Final Log
Show complete activity log + artifacts.
```
→ Next: /cgx:plan <phase>
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

# --- cgx:docs ---
cat > "$CGX_COMMANDS/docs.md" << 'CMD_EOF'
---
name: cgx:docs
description: Documentation sync — analyze codebase + update docs/
argument-hint: "[init|update|sync|summary]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion]
---
<objective>
Manage docs/ directory using direct file operations.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Detect action
- init: Create docs/ structure from scratch
- update: Update based on recent code changes
- sync: Align docs/ with .planning/ state
- summary: Show docs coverage overview

## 2. Analyze
- Read existing docs/ files
- Scan codebase structure (Glob)
- Read .planning/ files if exist
- Identify gaps between code and docs

## 3. Update
- Write/Edit docs files directly
- Update architecture, changelog, roadmap as needed

## 4. Report
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CGX:docs — Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| File                | Status  |
|---------------------|---------|
| system-architecture | ✓ Updated|
| project-changelog   | ✓ Updated|
| code-standards      | — Skip   |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
<format>Follow ~/.claude/cgx/output-format.md</format>
</process>
CMD_EOF

echo -e "  ${GREEN}✓${NC} 15 commands installed"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 6: Install CGX auto-routing rules
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[6/7] Installing auto-routing rules...${NC}"

# Write CGX rules file
cat > "$CGX_DIR/cgx-rules.md" << 'RULESEOF'
# CGX Auto-Routing Rules

When CGX commands are installed (`~/.claude/commands/cgx/`), automatically use them:

## Auto-Route Table
Match user intent → invoke the CGX command via `Skill(skill="cgx:<cmd>")`:

| User says / intent                                    | Invoke                          |
|-------------------------------------------------------|---------------------------------|
| Unclear request, vague, "I want to..."                | `Skill(skill="cgx:think", args="--quick")`  |
| Strategy, vision, evaluate options, big picture       | `Skill(skill="cgx:think")`      |
| New project, start fresh, initialize                  | `Skill(skill="cgx:new")`        |
| Plan, design, architect, research approach            | `Skill(skill="cgx:plan")`       |
| Build, implement, execute a phase                     | `Skill(skill="cgx:execute")`    |
| Quick fix, small bug, minor change                    | `Skill(skill="cgx:quick")`      |
| Complex bug, crash, investigation                     | `Skill(skill="cgx:debug")`      |
| Review code, check quality, run tests                 | `Skill(skill="cgx:review")`     |
| UI work, frontend, design                             | `Skill(skill="cgx:ui")`         |
| Update docs, sync documentation                       | `Skill(skill="cgx:docs")`       |
| Check progress, status, what's done                   | `Skill(skill="cgx:progress")`   |
| Run everything automatically                          | `Skill(skill="cgx:autonomous")` |

## When to auto-route
- User describes a task naturally (not using slash commands)
- The task clearly matches one of the intents above
- Invoke the CGX command BEFORE starting manual work

## When NOT to auto-route
- User explicitly asks for a specific approach
- Simple questions that don't need a pipeline
- User is in the middle of a CGX command flow already

## Output Format
Always follow `~/.claude/cgx/output-format.md` — tables, icons, progress bars. No prose paragraphs.
RULESEOF
echo -e "  ${GREEN}✓${NC} cgx-rules.md"

# Inject into global CLAUDE.md if not already present
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
CGX_MARKER="<!-- CGX-AUTO-ROUTING -->"

if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q "$CGX_MARKER" "$CLAUDE_MD" 2>/dev/null; then
    # Append CGX rules reference
    cat >> "$CLAUDE_MD" << INJECT_EOF

$CGX_MARKER
## CGX Auto-Routing
CGX hybrid commands are installed. Follow the routing rules in \`~/.claude/cgx/cgx-rules.md\` to automatically use \`/cgx:*\` commands when user intent matches.
Read \`~/.claude/cgx/cgx-rules.md\` for the auto-route table.
Read \`~/.claude/cgx/output-format.md\` for output formatting rules.
<!-- /CGX-AUTO-ROUTING -->
INJECT_EOF
    echo -e "  ${GREEN}✓${NC} Injected CGX rules into CLAUDE.md"
  else
    echo -e "  ${GREEN}✓${NC} CLAUDE.md already has CGX rules"
  fi
else
  # Create minimal CLAUDE.md with CGX rules
  cat > "$CLAUDE_MD" << INJECT_EOF
# CLAUDE.md

$CGX_MARKER
## CGX Auto-Routing
CGX hybrid commands are installed. Follow the routing rules in \`~/.claude/cgx/cgx-rules.md\` to automatically use \`/cgx:*\` commands when user intent matches.
Read \`~/.claude/cgx/cgx-rules.md\` for the auto-route table.
Read \`~/.claude/cgx/output-format.md\` for output formatting rules.
<!-- /CGX-AUTO-ROUTING -->
INJECT_EOF
  echo -e "  ${GREEN}✓${NC} Created CLAUDE.md with CGX rules"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 7: Write config
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[7/7] Writing config...${NC}"

CONFIG_FILE="$CGX_DIR/config.json"

node -e "
const fs = require('fs');
let cfg;
try { cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE','utf8')); } catch { cfg = {}; }
cfg.version = '$CGX_VERSION';
cfg.ck = { detected: $CK_FOUND, skillsPath: '$CK_SKILLS', skillCount: parseInt('${CK_SKILL_COUNT:-0}') || 0 };
cfg.gsd = { detected: $GSD_FOUND, version: '$GSD_VERSION', commandsPath: '$GSD_COMMANDS' };
cfg.integrations = cfg.integrations || {
  plan: { ck_research: true, ck_docs_seeker: true, gsd_discuss: true, gsd_plan: true },
  execute: { ck_cook: true, ck_review: true, ck_test: true, gsd_execute: true, gsd_verify: true },
  quick: { ck_cook: true, ck_fix: true, gsd_quick: true },
  debug: { ck_debug: true, ck_sequential_thinking: true, gsd_debug: true },
  ui: { ck_ui_ux: true, ck_ui_styling: true, gsd_ui_phase: true }
};
fs.writeFileSync('$CONFIG_FILE', JSON.stringify(cfg, null, 2));
" 2>/dev/null

echo -e "  ${GREEN}✓${NC} Config saved"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Determine mode
MODE="none"
[ "$CK_FOUND" = true ] && [ "$GSD_FOUND" = true ] && MODE="hybrid"
[ "$CK_FOUND" = true ] && [ "$GSD_FOUND" = false ] && MODE="ck-only"
[ "$CK_FOUND" = false ] && [ "$GSD_FOUND" = true ] && MODE="gsd-only"

echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}  CGX v${CGX_VERSION} — Installation Complete${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Mode: ${BOLD}${MODE}${NC}"
echo -e "  CK:   $([ "$CK_FOUND" = true ] && echo -e "${GREEN}✓ ${CK_SKILL_COUNT} skills${NC}" || echo -e "${YELLOW}✗ Missing${NC}")"
echo -e "  GSD:  $([ "$GSD_FOUND" = true ] && echo -e "${GREEN}✓ v${GSD_VERSION}${NC}" || echo -e "${YELLOW}✗ Missing${NC}")"
echo -e "  CGX:  ${GREEN}✓ 15 commands${NC}"
echo ""
echo -e "  ${BOLD}Usage:${NC}"
echo -e "    /cgx:help       — Show all commands"
echo -e "    /cgx:do <text>  — Smart router"
echo -e "    /cgx:update     — Fetch latest CK + GSD"
echo ""
echo -e "  ${DIM}Config: $CONFIG_FILE${NC}"
echo -e "  ${DIM}Uninstall: bash $0 --uninstall${NC}"
echo ""
