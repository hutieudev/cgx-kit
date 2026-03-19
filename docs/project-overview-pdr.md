# CGX — Product Development Requirements

## Product Vision

CGX is a hybrid orchestration kit that unifies ClaudeKit (CK) and Get Shit Done (GSD) into a single command interface for Claude Code. It eliminates the friction of manually switching between two powerful but separate systems.

## Problem Statement

- **GSD** excels at project lifecycle (roadmap, phases, execution, state tracking) but lacks quality gates (code review, testing, research)
- **CK** excels at domain skills (60+ specialized skills) but lacks project lifecycle management
- Users must manually orchestrate both systems, remembering which commands belong where
- No unified workflow exists that leverages both systems' strengths

## Solution

A thin orchestration layer (`/cgx:*` commands) that:
1. Detects both systems via standalone installer
2. Chains GSD workflows with CK skills automatically
3. Provides 13 hybrid commands covering the full development lifecycle
4. Allows toggling integrations via config

## Target Users

- Developers using Claude Code with both CK and GSD installed
- Teams wanting automated quality gates in their GSD workflows
- Solo developers wanting a complete AI-assisted development pipeline

## Key Metrics

- Installation: < 30 seconds via single bash script
- Commands: 13 hybrid commands covering all workflow stages
- Zero duplication: CGX never re-implements CK/GSD logic
- Graceful degradation: Works in gsd-only or ck-only mode

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Bash installer (not npm) | Self-contained, no package registry dependency |
| Slash commands (not skills) | Commands live in `~/.claude/commands/`, auto-registered |
| Config-based toggles | Users can disable specific CK/GSD integrations |
| No custom agents | Reuses existing CK agents + GSD agents |

## Versioning

- v0.1.0 — Initial release (13 commands, installer, config)
- Future: npm package for easier distribution
