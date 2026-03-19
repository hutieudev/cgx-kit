# CGX Development Roadmap

## v0.1.0 — Initial Release (Current)

**Status:** Complete

- [x] Standalone installer (bash, self-contained)
- [x] Auto-detect CK + GSD
- [x] Auto-fetch latest versions (--fetch-latest, --fetch-gsd, --fetch-ck)
- [x] 13 hybrid commands
- [x] Config system with integration toggles
- [x] Uninstall support
- [x] Graceful degradation (ck-only, gsd-only modes)
- [x] README + docs

## v0.2.0 — Enhancements (Planned)

- [ ] `cgx:settings` — Interactive config editor (toggle integrations)
- [ ] `cgx:status` — One-line status bar for session hooks
- [ ] Hook integration — Auto-inject CGX awareness into CK hooks
- [ ] Version pinning — Lock CK/GSD to specific versions in config
- [ ] Changelog tracking — Show what changed after updates

## v0.3.0 — Distribution (Planned)

- [ ] npm package (`npx cgx-kit --install`)
- [ ] Auto-update mechanism for CGX itself
- [ ] Plugin system for custom CGX commands
- [ ] Multi-runtime support (OpenCode, Gemini, Codex)

## v1.0.0 — Stable (Future)

- [ ] Battle-tested across 10+ real projects
- [ ] Community contributions
- [ ] Comprehensive test suite
- [ ] CI/CD for installer validation
