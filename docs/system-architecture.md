# CGX System Architecture

## Overview

CGX is a command-layer bridge between ClaudeKit (CK) and Get Shit Done (GSD). It contains no business logic — only orchestration.

## Component Diagram

```
User
  │
  ▼
/cgx:* commands (13)          ← ~/.claude/commands/cgx/*.md
  │
  ├──→ GSD workflows          ← ~/.claude/get-shit-done/
  │     ├── gsd-tools.cjs     ← State management
  │     ├── workflows/*.md    ← Execution logic
  │     └── .planning/        ← Project state (per-project)
  │
  └──→ CK skills              ← ~/.claude/skills/
        ├── cook/             ← Implementation validation
        ├── code-review/      ← Quality review
        ├── test/             ← Test execution
        ├── debug/            ← Root cause analysis
        ├── research/         ← Technical research
        └── 60+ more...       ← Domain-specific skills
```

## File Layout

```
~/.claude/
├── cgx/                          # CGX runtime (created by installer)
│   ├── config.json               # Detection results + integration toggles
│   └── check-prerequisites.cjs   # Runtime status checker
├── commands/cgx/                 # CGX slash commands (13 files)
│   ├── install.md / help.md / update.md
│   ├── do.md / new.md / plan.md / execute.md
│   ├── quick.md / debug.md / review.md
│   ├── autonomous.md / ui.md / progress.md
├── commands/gsd/                 # GSD commands (40, untouched by CGX)
├── get-shit-done/                # GSD core (untouched by CGX)
├── skills/                       # CK skills (60+, untouched by CGX)
└── agents/                       # CK + GSD agents (untouched by CGX)
```

## Command Flow

### cgx:plan (example)

```
1. check-prerequisites.cjs → mode: hybrid
2. Skill("gsd:discuss-phase") → CONTEXT.md
3. Skill("brainstorm") → approach options
4. Task(researcher) × 2 → research reports
5. Skill("gsd:plan-phase") → PLAN.md
```

### cgx:execute (example)

```
1. check-prerequisites.cjs → mode: hybrid
2. Skill("cook") → pre-check validation
3. Skill("gsd:execute-phase") → wave execution, atomic commits
4. Task(code-reviewer) → review report
5. Task(tester) → test results
6. Skill("gsd:verify-work") → goal verification
```

## Config Schema

```json
{
  "version": "0.1.0",
  "ck": {
    "detected": true,
    "skillsPath": "~/.claude/skills",
    "skillCount": 66
  },
  "gsd": {
    "detected": true,
    "version": "1.25.1",
    "commandsPath": "~/.claude/commands/gsd"
  },
  "integrations": {
    "plan": { "ck_research": true, "ck_docs_seeker": true, "gsd_discuss": true },
    "execute": { "ck_cook": true, "ck_review": true, "ck_test": true },
    "quick": { "ck_cook": true, "ck_fix": true },
    "debug": { "ck_debug": true, "ck_sequential_thinking": true },
    "ui": { "ck_ui_ux": true, "ck_ui_styling": true }
  }
}
```

## Modes

| Mode | CK | GSD | Behavior |
|------|-----|-----|----------|
| hybrid | yes | yes | Full pipeline — all 13 commands fully functional |
| ck-only | yes | no | CK skills work, GSD steps skipped (no state tracking) |
| gsd-only | no | yes | GSD workflows work, CK quality gates skipped |
| none | no | no | Installer exits with error |

## Design Principles

1. **Zero duplication** — CGX calls, never copies
2. **Graceful degradation** — Works with only one system
3. **Config-driven** — Toggle any integration
4. **Self-contained installer** — Single bash file, no dependencies beyond Node.js
5. **Non-invasive** — Never modifies CK or GSD files
