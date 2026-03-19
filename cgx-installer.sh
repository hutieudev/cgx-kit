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
CGX_VERSION="0.4.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Uninstall
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ "$UNINSTALL" = true ]; then
  echo -e "${CYAN}${BOLD}Uninstalling CGX...${NC}"
  rm -rf "$CGX_DIR" "$CGX_COMMANDS"
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
echo -e "${BOLD}[1/6] Creating directories...${NC}"
mkdir -p "$CGX_DIR" "$CGX_COMMANDS"
echo -e "  ${GREEN}✓${NC} $CGX_DIR"
echo -e "  ${GREEN}✓${NC} $CGX_COMMANDS"

# Copy installer to CGX dir for self-reference
cp "$0" "$CGX_DIR/install.sh" 2>/dev/null || true
chmod +x "$CGX_DIR/install.sh" 2>/dev/null || true

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Write runtime utilities
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[2/6] Writing runtime utilities...${NC}"

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: Detect CK + GSD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[3/6] Detecting installed systems...${NC}"

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
echo -e "${BOLD}[4/6] Fetching latest versions...${NC}"

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
# Step 5: Write all CGX commands
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[5/6] Installing CGX commands (13)...${NC}"

# --- cgx:install ---
cat > "$CGX_COMMANDS/install.md" << 'CMD_EOF'
---
name: cgx:install
description: Detect CK + GSD installations and setup CGX hybrid kit
allowed-tools: [Bash, Read, AskUserQuestion]
---
<objective>Run CGX installer to detect systems, fetch latest, and verify readiness.</objective>
<process>
## 1. Run Installer
```bash
bash "$HOME/.claude/cgx/install.sh"
```
## 2. Verify
```bash
node "$HOME/.claude/cgx/check-prerequisites.cjs" --json
```
Report the detected mode. Show available commands with `/cgx:help`.
</process>
CMD_EOF

# --- cgx:help ---
cat > "$CGX_COMMANDS/help.md" << 'CMD_EOF'
---
name: cgx:help
description: Show all CGX hybrid commands and usage guide
---
<objective>Display the complete CGX command reference.</objective>
<process>
```bash
node "$HOME/.claude/cgx/check-prerequisites.cjs" --summary
```
Then display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CGX — CK × GSD Hybrid Kit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SETUP
  /cgx:install          Detect CK + GSD, setup config
  /cgx:update           Fetch latest CK + GSD versions

WORKFLOW (use in order)
  /cgx:new              New project (GSD lifecycle + CK bootstrap)
  /cgx:plan <phase>     Research + Plan (CK research → GSD planner)
  /cgx:execute <phase>  Execute + Review + Test + Verify
  /cgx:autonomous       Full auto with CK quality gates per phase

DISCOVERY
  /cgx:clarify <desc>   10+ questions until 100% understanding

QUICK ACCESS
  /cgx:do <text>        Smart router — auto-route to best command
  /cgx:quick <task>     Bug fix or feature + commit + test (auto-detect)
  /cgx:debug <issue>    Deep investigation with checkpoints

QUALITY
  /cgx:review <phase>   Review + test + simplify + verify (flags: --test-only, --simplify)
  /cgx:ui <phase>       UI design + build + audit

KNOWLEDGE
  /cgx:plan <phase>     Research + plan (flag: --research-only for standalone research)
  /cgx:docs [action]    Documentation sync + analysis

SESSION
  /cgx:progress         Dashboard + pause/resume (flags: --pause, --resume)

HOW IT WORKS
  GSD provides: project state, roadmap, phases, wave execution, atomic commits
  CK  provides: research, cook, code-review, test, debug, docs-seeker, ui-ux
```
</process>
CMD_EOF

# --- cgx:update ---
cat > "$CGX_COMMANDS/update.md" << 'CMD_EOF'
---
name: cgx:update
description: Update CK + GSD to latest versions and refresh CGX config
argument-hint: "[--ck-only] [--gsd-only] [--all]"
allowed-tools: [Bash, Read, AskUserQuestion]
---
<objective>Auto-fetch latest CK and GSD, then refresh CGX config.</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Check Current
```bash
node "$HOME/.claude/cgx/check-prerequisites.cjs" --json
```
## 2. Update GSD (skip if --ck-only)
```
Skill(skill="gsd:update")
```
Or direct: `npx -y get-shit-done-cc@latest --claude --global`
## 3. Update CK (skip if --gsd-only)
```bash
bash "$HOME/.claude/cgx/install.sh" --fetch-ck
```
## 4. Refresh Config
```bash
bash "$HOME/.claude/cgx/install.sh"
```
Display before/after versions. Remind to restart session.
</process>
CMD_EOF

# --- cgx:do ---
cat > "$CGX_COMMANDS/do.md" << 'CMD_EOF'
---
name: cgx:do
description: Smart router — describe what you want, routes to the best CGX command
argument-hint: "<description of what you want to do>"
allowed-tools: [Read, Bash, AskUserQuestion]
---
<objective>Analyze freeform text and route to best CGX command. Dispatcher only.</objective>
<context>$ARGUMENTS</context>
<process>
If empty, ask user what they want to do.
Check `.planning/` existence.
Route by first match:
| Text describes... | Route |
|-------------------|-------|
| Unclear, vague, need to discuss | `/cgx:clarify` |
| New project, setup, initialize | `/cgx:new` |
| Bug fix, quick error, broken | `/cgx:fix` |
| Complex bug, crash, investigate | `/cgx:debug` |
| Planning, approach, strategy | `/cgx:plan` |
| Research, docs, library, how-to | `/cgx:research` |
| Building, implementing, execute | `/cgx:execute` |
| Review, quality, audit | `/cgx:review` |
| Test, coverage, verify | `/cgx:test` |
| Refactor, simplify, cleanup | `/cgx:simplify` |
| UI, styling, frontend visuals | `/cgx:ui` |
| Docs, documentation, update docs | `/cgx:docs` |
| Progress, status | `/cgx:progress` |
| Resume, continue, pick up | `/cgx:resume` |
| Pause, stop, save context | `/cgx:pause` |
| All phases auto | `/cgx:autonomous` |
| Small specific task | `/cgx:quick` |
If ambiguous: ask user with top 2-3 options.
Invoke matched command via `Skill(skill="cgx:<match>", args="...")`.
</process>
CMD_EOF

# --- cgx:plan ---
cat > "$CGX_COMMANDS/plan.md" << 'CMD_EOF'
---
name: cgx:plan
description: Research + Plan — CK deep research then GSD structured planning
argument-hint: "<phase-number|topic> [--research-only] [--skip-discuss] [--skip-research] [--deep]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Full planning pipeline with integrated research. Use --research-only for standalone research without planning.
Replaces separate cgx:research. All research capabilities built in.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Check: `node "$HOME/.claude/cgx/check-prerequisites.cjs" --json`
## 2. Context (GSD): `Skill(skill="gsd:discuss-phase", args="${PHASE} --auto")` (skip if --skip-discuss)
## 3. Research phase (skip if --skip-research):
  a. Docs lookup (CK): `Skill(skill="docs-seeker", args="$ARGUMENTS")` — latest library/framework docs
  b. Brainstorm (CK): `Skill(skill="brainstorm", args="$ARGUMENTS approaches")`
  c. Deep research (if --deep): Spawn 1-2 researcher agents for different aspects
  d. Save research report to plans/reports/
## 4. If --research-only: Stop here. Output consolidated research report.
## 5. Plan (GSD): `Skill(skill="gsd:plan-phase", args="${PHASE}")`
## 6. Report: Step statuses. Next: `/cgx:execute ${PHASE}`
</process>
CMD_EOF

# --- cgx:execute ---
cat > "$CGX_COMMANDS/execute.md" << 'CMD_EOF'
---
name: cgx:execute
description: Execute phase with full quality pipeline — cook, build, review, test, verify
argument-hint: "<phase-number> [--skip-review] [--skip-test] [--gaps-only]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Pipeline: CK cook pre-check → GSD execute-phase → CK code-review → CK test → GSD verify-work.
</objective>
<context>Phase: $ARGUMENTS</context>
<process>
## 1. Check prerequisites
## 2. Pre-check (CK cook): Validate plan readiness. `Skill(skill="cook", args="<plan-path> --auto")`
## 3. Build (GSD): `Skill(skill="gsd:execute-phase", args="${PHASE}")`. Stop if fails.
## 4. Review (CK): Spawn code-reviewer agent on changed files. Skip if --skip-review. Fix critical issues.
## 5. Test (CK): Spawn tester agent. Skip if --skip-test. Fix failures before proceeding.
## 6. Verify (GSD): `Skill(skill="gsd:verify-work", args="${PHASE}")`
## 7. Report: Step statuses table. Next: `/cgx:progress`
</process>
CMD_EOF

# --- cgx:quick ---
cat > "$CGX_COMMANDS/quick.md" << 'CMD_EOF'
---
name: cgx:quick
description: Quick task — auto-detects bug/feature, fix + commit + test in one shot
argument-hint: "<task or bug description> [--fix] [--feature] [--no-test]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
All-in-one quick action: auto-detect bug vs feature → CK fix or cook → implement → GSD atomic commit → CK test verify.
Replaces separate cgx:fix. Use --fix to force bug mode, --feature for feature mode.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Check prerequisites
## 2. Auto-detect intent (or use --fix/--feature flag):
  - Bug keywords (fix, bug, error, crash, broken, wrong, fail) → bug mode
  - Everything else → feature mode
## 3. Analysis:
  - Bug mode: `Skill(skill="fix", args="$ARGUMENTS")` — root cause analysis
  - Feature mode: `Skill(skill="cook", args="$ARGUMENTS --fast")` — pre-check
## 4. Implement the fix or feature based on analysis
## 5. Commit (GSD): `Skill(skill="gsd:quick", args="$ARGUMENTS")`
## 6. Verify (unless --no-test): `Skill(skill="test", args="regression check")`
## 7. Report: Mode (bug/feature), CK skill used, commit hash, test result
</process>
CMD_EOF

# --- cgx:debug ---
cat > "$CGX_COMMANDS/debug.md" << 'CMD_EOF'
---
name: cgx:debug
description: Systematic debug — CK root cause analysis + GSD checkpoint persistence
argument-hint: "<issue description>"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
CK debug (root cause) + CK sequential-thinking → GSD debug (checkpoints) → CK test verify.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Analysis (CK): `Skill(skill="debug", args="$ARGUMENTS")`
## 2. Deep analysis: If unclear, `Skill(skill="sequential-thinking", args="...")`
## 3. Fix (GSD): `Skill(skill="gsd:debug", args="$ARGUMENTS")` — persistent DEBUG.md + checkpoints
## 4. Verify (CK): Spawn tester to confirm fix
## 5. Report: Root cause, fix, test result
</process>
CMD_EOF

# --- cgx:new ---
cat > "$CGX_COMMANDS/new.md" << 'CMD_EOF'
---
name: cgx:new
description: New project — GSD lifecycle setup + CK bootstrap
argument-hint: "[project description]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
CK bootstrap (tech research) → GSD new-project (lifecycle) → CK docs init.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Tech research (CK): `Skill(skill="bootstrap", args="$ARGUMENTS --fast")`
## 2. Project setup (GSD): `Skill(skill="gsd:new-project", args="$ARGUMENTS")`
## 3. Docs init (CK): `Skill(skill="docs", args="init")`
## 4. Report: GSD .planning/ + CK docs/ ready. Next: `/cgx:plan 1`
</process>
CMD_EOF

# --- cgx:progress ---
cat > "$CGX_COMMANDS/progress.md" << 'CMD_EOF'
---
name: cgx:progress
description: Progress + session management — dashboard, pause, or resume
argument-hint: "[--pause [notes]] [--resume]"
allowed-tools: [Read, Write, Glob, Grep, Bash, Task, AskUserQuestion]
---
<objective>
Project dashboard + session management. Replaces separate cgx:pause and cgx:resume.
Default: show progress. Use --pause or --resume for session control.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. If --pause:
  a. Check for uncommitted changes — warn if exist
  b. Pause (GSD): `Skill(skill="gsd:pause-work", args="$ARGUMENTS")`
  c. Summary: Git log since session start, files changed, phases touched
  d. Report: Handoff file location, resume instructions
  → STOP HERE

## 2. If --resume:
  a. Restore (GSD): `Skill(skill="gsd:resume-work")`
  b. Git scan: Check recent commits, uncommitted changes, branch status
  c. Health (GSD): `Skill(skill="gsd:health")`
  d. Progress: `Skill(skill="gsd:progress")` — where we left off
  e. Suggest: Route to next action (plan, execute, fix, test)
  → STOP HERE

## 3. Default — Progress dashboard:
  a. GSD: `Skill(skill="gsd:progress")`
  b. Stats: `Skill(skill="gsd:stats")`
  c. Kanban (CK): If plans exist, `Skill(skill="plans-kanban")`
  d. Suggest next action based on progress
</process>
CMD_EOF

# --- cgx:review ---
cat > "$CGX_COMMANDS/review.md" << 'CMD_EOF'
---
name: cgx:review
description: Quality gate — review + test + simplify + verify in one command
argument-hint: "<phase-number|file-path> [--test-only] [--simplify] [--coverage] [--e2e]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Unified quality gate. Replaces separate cgx:test and cgx:simplify.
Default: review + test + verify. Use flags for specific modes.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Determine scope: phase number → phase files, file path → specific file

## 2. If --simplify:
  a. Simplify (CK): `Skill(skill="simplify", args="$ARGUMENTS")`
  b. Review simplified code (CK): Spawn code-reviewer
  c. Test (CK): `Skill(skill="test", args="regression check")`
  d. Commit (GSD): `Skill(skill="gsd:quick", args="refactor: simplify")`
  e. Report: Lines reduced, complexity, test results
  → STOP HERE

## 3. If --test-only:
  a. Generate tests if needed: `Skill(skill="gsd:add-tests", args="$ARGUMENTS")`
  b. Run tests (CK): `Skill(skill="test", args="$ARGUMENTS")`
  c. Coverage (if --coverage): Analyze coverage for scoped files
  d. E2E (if --e2e): `Skill(skill="web-testing", args="e2e $ARGUMENTS")`
  e. Report: Pass/fail, coverage %, untested areas
  → STOP HERE

## 4. Full review (default):
  a. Review (CK): `Skill(skill="code-review", args="$ARGUMENTS")`
  b. Test (CK): `Skill(skill="test", args="$ARGUMENTS")`
  c. Verify (GSD): `Skill(skill="gsd:verify-work", args="$ARGUMENTS")`
  d. Verdict: Review/Tests/Goal pass/fail table
</process>
CMD_EOF

# --- cgx:autonomous ---
cat > "$CGX_COMMANDS/autonomous.md" << 'CMD_EOF'
---
name: cgx:autonomous
description: Full auto — run all phases with CK quality gates at each step
argument-hint: "[--from N]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Auto-execute all remaining phases: cgx:plan → cgx:execute per phase.
Pauses for blockers, validation, critical failures only.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Check .planning/ exists
## 2. Discover incomplete phases from ROADMAP.md
## 3. Per phase loop:
  - Plan if needed: `Skill(skill="cgx:plan", args="${N} --skip-discuss")`
  - Execute with quality: `Skill(skill="cgx:execute", args="${N}")`
  - Handle failures: fix + re-execute
## 4. After all: `Skill(skill="gsd:audit-milestone")` → `Skill(skill="gsd:complete-milestone")`
## 5. Report: Phases completed, quality gates status
</process>
CMD_EOF

# --- cgx:ui ---
cat > "$CGX_COMMANDS/ui.md" << 'CMD_EOF'
---
name: cgx:ui
description: UI phase — GSD UI-SPEC + CK design intelligence + implementation
argument-hint: "<phase-number>"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
GSD ui-phase (UI-SPEC) → CK ui-ux-pro-max (design) → cgx:execute → GSD ui-review + CK web-design-guidelines.
</objective>
<context>Phase: $ARGUMENTS</context>
<process>
## 1. Design contract (GSD): `Skill(skill="gsd:ui-phase", args="$ARGUMENTS")`
## 2. Design enhance (CK): `Skill(skill="ui-ux-pro-max", args="review Phase $ARGUMENTS UI-SPEC")`
## 3. Build: `Skill(skill="cgx:execute", args="$ARGUMENTS")`
## 4. Audit: `Skill(skill="gsd:ui-review", args="$ARGUMENTS")` + `Skill(skill="web-design-guidelines", args="Phase $ARGUMENTS")`
## 5. Report: UI-SPEC/Design/Build/Audit status table
</process>
CMD_EOF

# Remove merged commands
rm -f "$CGX_COMMANDS/fix.md" "$CGX_COMMANDS/research.md" "$CGX_COMMANDS/test.md" \
      "$CGX_COMMANDS/simplify.md" "$CGX_COMMANDS/pause.md" "$CGX_COMMANDS/resume.md"

# --- cgx:clarify ---
cat > "$CGX_COMMANDS/clarify.md" << 'CMD_EOF'
---
name: cgx:clarify
description: Deep requirement clarification — ask 10+ questions until 100% understanding before action
argument-hint: "<what you want to do or problem description>"
allowed-tools: [Read, Glob, Grep, Bash, AskUserQuestion]
---
<objective>
Interview the user with targeted questions to reach 100% understanding before any implementation.
Minimum 10 questions. Show understanding % after each answer. Keep asking until 100%.
</objective>
<context>$ARGUMENTS</context>
<process>
## Protocol

You are a senior technical consultant. Your job is to FULLY understand what the user needs before ANY work begins.

### Step 1: Initial Analysis
Read the user's description. Identify:
- What is clear vs ambiguous
- Missing technical details
- Unstated assumptions
- Scope boundaries unclear
- Success criteria undefined

Calculate initial understanding % based on how complete the description is.
Display: `Understanding: XX% — need more clarity on: [list gaps]`

### Step 2: Question Rounds (minimum 10 questions)

Ask questions in batches of 3-5 using AskUserQuestion. Each batch targets different dimensions:

**Round 1 — Problem/Goal (Q1-3):**
- What exactly is the problem or desired outcome?
- What triggered this need? (bug report, feature request, tech debt, user feedback)
- What does "done" look like? How will you verify success?

**Round 2 — Scope & Constraints (Q4-6):**
- What files/modules/areas are involved?
- What should NOT be changed? (boundaries, dependencies, APIs)
- Any deadlines, performance requirements, or tech constraints?

**Round 3 — Context & Dependencies (Q7-9):**
- Who are the end users? What's their workflow?
- Are there related features, existing implementations, or prior attempts?
- Any external systems, APIs, or services involved?

**Round 4 — Edge Cases & Risks (Q10+):**
- What could go wrong? Known edge cases?
- Any security, accessibility, or compliance concerns?
- What's the rollback plan if this doesn't work?

After EACH user response, update the understanding %:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Understanding: 73% ████████████████░░░░░░
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Problem: clear
✓ Goal: clear
✓ Scope: clear
✗ Edge cases: need more info
✗ Success criteria: vague
✗ Dependencies: unknown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Understanding % Calculation
Score each dimension (0-100), then average:
- Problem definition: __%
- Desired outcome: __%
- Scope boundaries: __%
- Technical constraints: __%
- Success criteria: __%
- Edge cases & risks: __%
- Context & dependencies: __%
- User/stakeholder needs: __%
- Priority & timeline: __%
- Rollback/safety: __%

### Step 3: Keep Asking Until 100%
- If any dimension < 80%: ask targeted follow-ups for that dimension
- If understanding >= 90% but < 100%: ask 2-3 final precision questions
- NEVER stop below 100%

### Step 4: Summary & Route
When 100% reached, output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Understanding: 100% ██████████████████████
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then produce a structured brief:
- **Problem:** 1-2 sentences
- **Goal:** what success looks like
- **Scope:** files/modules involved, boundaries
- **Constraints:** tech, performance, timeline
- **Edge cases:** identified risks
- **Success criteria:** how to verify done
- **Recommended approach:** which cgx command to use next

Ask user: "Ready to proceed with `/cgx:<recommended>`?"
</process>
CMD_EOF

# --- cgx:docs ---
cat > "$CGX_COMMANDS/docs.md" << 'CMD_EOF'
---
name: cgx:docs
description: Documentation management — CK docs analysis + GSD project docs sync
argument-hint: "[init|update|sync|summary]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>
Unified docs: CK docs (codebase analysis) + GSD project docs (.planning/) + ./docs/ sync.
</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Detect action: init (first time), update (after changes), sync (align docs), summary (overview)
## 2. Analyze (CK): `Skill(skill="docs", args="$ARGUMENTS")`
## 3. GSD context: Read .planning/PROJECT.md, ROADMAP.md for project state
## 4. Sync: Update ./docs/ files (architecture, roadmap, changelog) from current codebase + GSD state
## 5. Report: Files updated, coverage gaps, stale docs flagged
</process>
CMD_EOF

echo -e "  ${GREEN}✓${NC} 15 commands installed"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 6: Write config
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}[6/6] Writing config...${NC}"

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
