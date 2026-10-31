# CCGS controlled adoption — 2026-10-31

- Source: Donchitos/Claude-Code-Game-Studios at commit `05ad7c8a5b8aa2aa86bbd3439ae7cf7295cac418`; upstream `project.yaml` declares framework `1.2.0`.
- Reference: private Registry `frameworks/claude-code-game-studios/README.md` is **reference-only**; no Registry or profile change was made.
- Reviewed: upstream README, CLAUDE.md, project.yaml, .claude/settings.json, SECURITY.md, LICENSE, actual `/start`, `/setup-engine`, `/brainstorm`, `/prototype`, `/qa-plan`, `/smoke-check` skill definitions.
- Adopted: project-scoped `project.yaml`, lean game brief, architecture/design/QA artifacts and *adapted* `.claude/skills/` command wrappers; the phases were applied to the design and implementation.
- Deliberately omitted: 49 agents, hook scripts, deny/permissions block, project-global or user-global agent configuration, complete CCGS scripts, upstream README and template pack. **The original upstream skills were inspected, not executed or installed verbatim.** The adapted wrappers are not equivalents of the full original skills.
- Why: upstream hooks can run on edits, sessions, commits and pushes, have Python/Bash dependencies, and must not be executed sight-unseen. The minimal solo workflow avoids that scope.
- Upstream MIT license; no executable upstream source files are copied. Original adaptations are project-authored, and upstream names/workflow are attributed here.
- Unverified: actual Claude Code command load/execution, actual Godot editor and manual-playtest; only static Python validation completed in this execution environment.

## CCGS implementation trace
| Phase | Adapted output | Gate |
|---|---|---|
| `/start` | `design/game-brief.md`, `project.yaml` | concept and MVP 3 games specified by owner |
| `/setup-engine godot 4.7.2` | `project.godot`, `docs/engine-reference/VERSION.md` | official stable release pinned |
| `/brainstorm` | single-page brief with distinct three mechanics | no extraneous GDDs |
| `/prototype --spike` | Beat Factory audio clock + timing scorer | real hands-on feel **NOT VERIFIED** |
| `/qa-plan` `/smoke-check` | Python validator/tests, Godot test script, manual checklist | Python PASS; Godot + manual **NOT VERIFIED** |
