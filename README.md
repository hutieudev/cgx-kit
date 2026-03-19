# CGX — CK × GSD Hybrid Kit

**One installer. Two powerhouses. Zero friction.**

CGX merges [ClaudeKit](https://github.com/anthropics/claudekit) (CK) skills with [Get Shit Done](https://github.com/glittercowboy/get-shit-done) (GSD) workflows into 13 unified `/cgx:*` commands for Claude Code.

```
┌─────────┐     ┌──────────────┐     ┌──────────────┐
│ CGX cmd │ ──→ │ GSD workflow  │ ──→ │  CK skills   │
│ /cgx:*  │     │ state, phases│     │ review, test  │
└─────────┘     └──────────────┘     └──────────────┘
```

## Why CGX?

| Problem | CGX Solution |
|---------|-------------|
| GSD executes but doesn't review code | CGX auto-runs CK code-review + tests after every execution |
| CK has great skills but no project lifecycle | CGX wraps CK skills in GSD's phase/state management |
| Switching between `/gsd:*` and CK skills is manual | CGX orchestrates both automatically per command |

## Quick Start

```bash
# One-liner install (recommended)
npx cgx-kit

# Install + auto-fetch both CK & GSD
npx cgx-kit --fetch-latest

# Or curl directly
bash <(curl -fsSL https://raw.githubusercontent.com/hutieudev/cgx-kit/main/cgx-installer.sh)
```

Then in Claude Code:

```
/cgx:help                           # Show all commands
/cgx:do "add user authentication"   # Smart router
/cgx:plan 3                         # Plan phase 3
/cgx:execute 3                      # Build + review + test + verify
```

## Commands

### Setup
| Command | Description |
|---------|-------------|
| `/cgx:install` | Detect CK + GSD, setup config |
| `/cgx:update` | Fetch latest CK + GSD versions |

### Workflow (use in order)
| Command | Pipeline |
|---------|----------|
| `/cgx:new` | CK bootstrap → GSD new-project → CK docs init |
| `/cgx:plan <phase>` | GSD discuss → CK brainstorm → CK research → GSD plan |
| `/cgx:execute <phase>` | CK cook → GSD execute → CK review → CK test → GSD verify |
| `/cgx:autonomous` | Full auto: plan → execute per phase with quality gates |

### Discovery
| Command | Pipeline |
|---------|----------|
| `/cgx:think <topic>` | Clarify (100%) → Research → Brainstorm → Vision. Flag: `--quick` for clarify-only |

### Quick Access
| Command | Pipeline |
|---------|----------|
| `/cgx:do <text>` | Smart router — auto-route to best command |
| `/cgx:quick <task>` | Auto-detect bug/feature → CK fix/cook → GSD commit → CK test |
| `/cgx:debug <issue>` | CK debug → CK sequential-thinking → GSD debug → CK test |

### Quality
| Command | Pipeline |
|---------|----------|
| `/cgx:review <phase>` | Review + test + verify. Flags: `--test-only`, `--simplify`, `--coverage`, `--e2e` |
| `/cgx:ui <phase>` | GSD UI-SPEC → CK ui-ux-pro-max → build → GSD ui-review |

### Knowledge
| Command | Pipeline |
|---------|----------|
| `/cgx:plan <phase>` | Research + plan. Flag: `--research-only` for standalone research |
| `/cgx:docs [action]` | CK docs → GSD project state → ./docs/ sync |

### Session
| Command | Pipeline |
|---------|----------|
| `/cgx:progress` | Dashboard + session. Flags: `--pause [notes]`, `--resume` |

## How It Works

CGX is a **thin orchestration layer** — it never duplicates logic. Each command calls the best combination of existing GSD commands and CK skills via `Skill()` invocations.

### What GSD Provides
- Project state management (`.planning/`, `STATE.md`, `ROADMAP.md`)
- Phase-based development lifecycle
- Wave-based parallel execution with atomic commits
- Debug checkpoints persistent across sessions
- Goal-backward verification

### What CK Provides
- 60+ specialized skills (cook, fix, debug, research, docs-seeker, etc.)
- Expert code review with scout-based edge case detection
- Comprehensive testing (unit, integration, e2e)
- Domain-specific skills (frontend, backend, databases, devops)
- MCP integrations (context7 for latest docs)

### CGX Hybrid Pipeline Example

```
/cgx:execute 3

  ┌─────────────────────────────────────────────┐
  │ Step 1: Pre-check (CK cook)                 │
  │   Validate plan readiness                   │
  ├─────────────────────────────────────────────┤
  │ Step 2: Build (GSD execute-phase)           │
  │   Wave execution, atomic commits            │
  ├─────────────────────────────────────────────┤
  │ Step 3: Review (CK code-reviewer)           │
  │   Logic errors, security, performance       │
  ├─────────────────────────────────────────────┤
  │ Step 4: Test (CK tester)                    │
  │   Lint, type-check, unit tests, build       │
  ├─────────────────────────────────────────────┤
  │ Step 5: Verify (GSD verify-work)            │
  │   Goal-backward achievement check           │
  └─────────────────────────────────────────────┘
```

## Installation

### Prerequisites

- **Node.js** (v18+)
- **npm**
- At least one of:
  - **ClaudeKit** — installed at `~/.claude/skills/`
  - **GSD** — installed via `npx get-shit-done-cc --claude --global`

### Install Options

```bash
# Via npm (recommended — works from any directory)
npx cgx-kit                    # Detect-only
npx cgx-kit --fetch-latest     # Auto-fetch CK + GSD
npx cgx-kit --fetch-gsd        # Fetch only GSD
npx cgx-kit --fetch-ck         # Fetch only CK dependencies
npx cgx-kit --uninstall        # Remove CGX (CK and GSD untouched)

# Via curl
bash <(curl -fsSL https://raw.githubusercontent.com/hutieudev/cgx-kit/main/cgx-installer.sh)

# Or clone + run
git clone https://github.com/hutieudev/cgx-kit.git /tmp/cgx-kit
bash /tmp/cgx-kit/cgx-installer.sh --fetch-latest
```

### What Gets Installed

```
~/.claude/
├── cgx/                        # CGX runtime
│   ├── config.json             # Integration toggles
│   └── check-prerequisites.cjs # Runtime prereq checker
└── commands/cgx/               # 13 slash commands
    ├── install.md
    ├── help.md
    ├── update.md
    ├── do.md
    ├── new.md
    ├── plan.md
    ├── execute.md
    ├── quick.md
    ├── debug.md
    ├── review.md
    ├── autonomous.md
    ├── ui.md
    └── progress.md
```

### Modes

| Mode | Condition | Available Commands |
|------|-----------|-------------------|
| **hybrid** | CK + GSD both detected | All 13 commands (full power) |
| **gsd-only** | Only GSD installed | GSD commands work, CK skills skipped |
| **ck-only** | Only CK installed | CK skills work, GSD lifecycle skipped |

## Configuration

Config at `~/.claude/cgx/config.json`:

```json
{
  "version": "0.1.0",
  "integrations": {
    "plan": { "ck_research": true, "ck_docs_seeker": true },
    "execute": { "ck_cook": true, "ck_review": true, "ck_test": true },
    "debug": { "ck_debug": true, "ck_sequential_thinking": true }
  }
}
```

Toggle any integration on/off to customize the pipeline.

## Updating

```bash
# Via Claude Code
/cgx:update

# Via terminal (re-runs installer with fetch)
bash cgx-installer.sh --fetch-latest
```

## Uninstalling

```bash
bash cgx-installer.sh --uninstall
```

This removes only CGX commands and config. CK and GSD remain untouched.

## License

MIT
