# Rhythm Rhythm — Claude Code project scope

This is an **adapted minimal CCGS workflow**, not a complete upstream installation.
Use Godot 4.7.2-stable, GDScript and Compatibility renderer. Read `project.yaml`,
`design/game-brief.md`, `docs/CCGS_ADOPTION.md`, `docs/engineering/ARCHITECTURE.md`.

## Safety and execution
- Never install global hooks/skills/agents or modify WDO, Registry or Persona.
- No project hooks, shell scripts or blanket permissions are installed here.
- Never import another rhythm game's assets, songs, characters or presentation.
- Work on a feature branch; code, tests, PR may proceed within approved scope.
- Ask before deployment, release/tag, force-push, main pushes except bootstrap.
- A passing parser/build is not a real gameplay/playtest result.

## Workflow
`/start` review current brief → `/setup-engine` inspect pinned version →
`/brainstorm` refine one-page brief → `/prototype` test Beat Factory timing →
implementation and `/smoke-check` validate Godot, controls, audio and actual screenshots.
The five commands below are *local adaptations* of named upstream CCGS phases.
They intentionally omit upstream orchestration and shell hooks.
