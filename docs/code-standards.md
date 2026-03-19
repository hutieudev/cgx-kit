# CGX Code Standards

## File Types

| Type | Location | Format |
|------|----------|--------|
| Commands | `~/.claude/commands/cgx/*.md` | YAML frontmatter + markdown process |
| Runtime | `~/.claude/cgx/*.cjs` | Node.js CommonJS |
| Installer | `cgx-installer.sh` | Bash |
| Config | `~/.claude/cgx/config.json` | JSON |

## Command File Structure

```yaml
---
name: cgx:<command>
description: Short description
argument-hint: "<args> [--flags]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, AskUserQuestion]
---
<objective>What this command does + which CK/GSD systems it combines.</objective>
<context>$ARGUMENTS</context>
<process>
## 1. Step name: `Skill(skill="...", args="...")`
## 2. Step name: description
...
</process>
```

## Naming Conventions

- Commands: `cgx:<verb>` (lowercase, single word: plan, execute, debug)
- Config keys: `snake_case` (ck_review, gsd_execute)
- Bash variables: `UPPER_SNAKE_CASE`
- Node.js files: `kebab-case.cjs`

## Installer Guidelines

- Self-contained: all commands embedded as heredocs
- Idempotent: safe to re-run
- Exit codes: 0 success, 1 fatal error
- Color output: RED=error, GREEN=success, YELLOW=warning, CYAN=info
- Step numbering: `[N/M]` format

## Integration Rules

1. Never modify CK or GSD files
2. Always check prerequisites before executing
3. Use `Skill()` to invoke CK skills and GSD commands
4. Use `Task()` to spawn CK agents (code-reviewer, tester, researcher)
5. Display step banners with `━━━` separators
6. Report results in table format
