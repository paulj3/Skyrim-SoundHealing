# AGENTS.md — Instructions for AI agents and contributors

## Repository mission

SoundHealing is a Skyrim Special Edition mod that turns musical resonance into playable equipment, magic and restorative rituals. The v0.1 goal is a **small, reliable, fully playable vertical slice**, not a sprawling content mod. Read the design and engineering docs before changing behavior:

- `docs/DESIGN_V0_1.md` — scope, user experience, acceptance tests and future ideas.
- `docs/ARCHITECTURE.md` — source layout, record graph, scripts, invariants.
- `docs/TOOLCHAIN_SETUP.md` — Windows editor/tool installation and build instructions.
- `CLAUDE.md` — additional guidance when Claude is the assisting tool.

## Primary instruction: respect existing source

This documentation was reconstructed partly from previous development sessions and a sample of exported YAML; **the live checkout wins** when details differ. Inspect files before asserting file paths, values, Papyrus inheritance, CLI syntax, or completion status. Do not invent test results.

### Expected files and outputs

| Editable source | Purpose |
|---|---|
| `plugin-src/SoundHealing/` | Spriggit YAML plugin records and identifiers |
| `src/papyrus/` | Papyrus `.psc` scripts |
| `assets/` | Original owned meshes, textures, sounds and other asset source |
| `scripts/build.ps1` | Previously observed build orchestration; verify exact path |
| `.vscode/tasks.json` | Development tasks |
| `docs/` | Human and AI-readable technical/design docs |

**Generated output (generally ignored):** `build/`, `.pex` binaries, deserialized ESP and temporary files. **Local non-source:** bundled `tools/Spriggit-0.41.0/`, extracted Bethesda reference assets in `asset-src/reference/`.

## Non-negotiable safety and correctness rules

1. **Do not overwrite, delete or re-key FormKeys** without a deliberate migration plan. Preserve plugin name and the reference network.
2. **Do not change records by filename inference alone.** Inspect YAML `FormKey` and `EditorID`; exported sample filenames sometimes differ from EditorIDs.
3. **Avoid destructive Git commands**, reset, history rewriting, or forced pushes without explicit user approval and a backup. A rejected GitHub push previously involved a 171 MB local Spriggit executable; never commit tool binaries.
4. **Keep generated files generated.** Make durable changes in YAML/PSC/source assets/scripts, then build.
5. **No undocumented dependencies.** Ask before introducing SKSE, custom runtime libraries, new plugin masters, externally sourced assets, or software requirements.
6. **Respect licenses and provenance.** Do not publish Skyrim-extracted assets or third-party tool downloads; avoid sharing proprietary files in a public repository.
7. **No fabricated verification.** Distinguish successful compile, successful serialization, xEdit inspection, and actual in-game tests.
8. **Keep changes small and reversible.** Avoid unrelated formatting, renames, or broad refactors. Explain behavior changes and known risks.
9. **Maintain accurate docs.** Update design, setup and architecture when modifying scope, tools, properties or file layout.
10. **Do not make medical efficacy claims.** Sound healing is a creative/artistic inspiration for fantasy-game mechanics, not medical treatment.

## Architecture constraints

### Prototype relationship to preserve until deliberately redesigned

```text
JP_SH_BowlPrototype (WEAP, 003322)
  -> JP_SH_EnchPrototypeStrike (ENCH, 003889)
      -> JP_SH_MGEFPrototypeStrike (MGEF, 003326)
          -> JP_SH_ProjectileStrike (PROJ, 00388A)
          -> release sound record 001D93
```

All IDs above belong to `SoundHealing.esp` in the exported prototype. Do not automatically create/reuse an existing FormKey for a new variant.

### Runtime invariants

- Strike: **FireAndForget** in known sample, with staff/enchantment charge behavior.
- Sing: Concentration; previously drained Magicka at **6/s**, checked every **0.25 s**, interrupted when insufficient.
- Resonant Meditation: ~**30 s**, cancels on movement/combat, uses regen-rate effects, must clean up on *every* exit path.
- Equip/sound: test first equip as well as re-equip after loading; an initial-equip audio issue was observed previously.

Historical values are checkpoints, not a substitute for reading live source.

## Agent task protocol

### Before editing

- Confirm repository root and `git status`.
- Read relevant doc and source files; identify the smallest testable outcome.
- Map the affected YAML records, their FormKeys, assets, and `.psc` scripts.
- Flag risks to existing save games or dependencies. Ask for clarification when uncertain.

### During edits

- Preserve existing directory conventions and `JP_SH_` identifiers.
- Make minimal patches; avoid adding extra masters or expensive frameworks.
- Keep code readable and comments focused on why, not narrating every line.
- Favor controllable parameters over hardcoded gameplay values, but don't invent a config architecture for v0.1 without need.
- Use source-controlled original audio/3D assets; do not modify packaged copies as the source of truth.

### After edits

- Run available static checks and the project's actual build task; show commands/results.
- Verify linked records with xEdit/Creation Kit when the environment allows.
- Provide a clear **manual in-game test checklist** when a game session is unavailable.
- State which tests were not run and why.
- Summarize edited files, gameplay impact, and rollback considerations.
- Suggest a narrowly scoped commit message; do not claim a push occurred unless it actually did.

## Completion rubric

| Layer | Minimum evidence |
|---|---|
| Source | Reviewed diff; identifiers and paths intentional |
| Compilation | Papyrus compiled when scripts changed |
| Serialization | Spriggit output built without errors when YAML changed |
| Plugin integrity | Masters/records/links inspected where possible |
| Gameplay | Targeted in-game action works; stop/reload edge cases tested |
| Documentation | Relevant instructions and statuses updated |

## Coding and design preferences

- Prefer the simplest native Skyrim mechanism that can deliver the experience.
- Gameplay that sounds and feels coherent is more valuable than speculative architecture.
- Keep Strike / Sing / meditation responsibilities separate.
- Prefer data records for static effects and Papyrus for timed/interrupted state.
- Build incrementally, verify in game, then extend to recipes, material variants, NPC healing, additional instruments and lore.

## Useful first commands (PowerShell)

```powershell
git status
Get-ChildItem .\plugin-src\SoundHealing -Recurse -Filter *.yaml -ErrorAction SilentlyContinue | Select-Object -First 20
Get-ChildItem .\src\papyrus -Recurse -Filter *.psc -ErrorAction SilentlyContinue
Get-ChildItem . -Recurse -Filter build.ps1 | Select-Object FullName
```

If the paths don't match, find the actual equivalents and update the docs only after confirming them.
