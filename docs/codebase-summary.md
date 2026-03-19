# CGX Codebase Summary

## Project Stats

- **Version:** 0.1.0
- **Commands:** 13
- **Files:** 15 (1 installer + 1 util + 13 commands)
- **Dependencies:** Node.js, npm, CK and/or GSD

## Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `cgx-installer.sh` | Standalone installer (all-in-one) | ~300 |
| `~/.claude/cgx/config.json` | Runtime config + detection results | ~20 |
| `~/.claude/cgx/check-prerequisites.cjs` | Status checker (--json / --summary) | ~22 |
| `~/.claude/commands/cgx/*.md` | 13 slash commands | ~15-20 each |

## Command Inventory

| # | Command | GSD Components | CK Components |
|---|---------|---------------|---------------|
| 1 | install | — | — |
| 2 | help | — | — |
| 3 | update | gsd:update | CK install.sh |
| 4 | do | Router pattern | — |
| 5 | new | new-project | bootstrap, docs |
| 6 | plan | discuss-phase, plan-phase | brainstorm, research, docs-seeker |
| 7 | execute | execute-phase, verify-work | cook, code-review, test |
| 8 | quick | quick | fix, cook, code-review |
| 9 | debug | debug | debug, sequential-thinking, test |
| 10 | review | verify-work | code-review, test |
| 11 | autonomous | All lifecycle | All quality gates |
| 12 | ui | ui-phase, ui-review | ui-ux-pro-max, web-design-guidelines |
| 13 | progress | progress, stats | plans-kanban |

## External Dependencies

| System | Package | Version |
|--------|---------|---------|
| GSD | `get-shit-done-cc` (npm) | 1.25.1+ |
| CK | ClaudeKit skills bundle | 2.13.0+ |
| Runtime | Node.js | 18+ |
