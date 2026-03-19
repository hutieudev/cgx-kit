# CGX Changelog

## [0.1.0] — 2026-03-19

### Added
- Standalone installer (`cgx-installer.sh`) — single file, self-contained
- Auto-detection of ClaudeKit and GSD installations
- Auto-fetch latest versions via `--fetch-latest`, `--fetch-gsd`, `--fetch-ck`
- 13 hybrid commands:
  - Setup: `install`, `help`, `update`
  - Workflow: `new`, `plan`, `execute`, `autonomous`
  - Quick: `do`, `quick`, `debug`
  - Quality: `review`, `ui`
  - Tracking: `progress`
- Config system (`~/.claude/cgx/config.json`) with integration toggles
- Runtime prereq checker (`check-prerequisites.cjs`)
- Graceful degradation: hybrid, ck-only, gsd-only modes
- Uninstall support (`--uninstall`)
- Project documentation (README, PDR, architecture, standards)
