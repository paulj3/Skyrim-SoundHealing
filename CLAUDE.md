# CLAUDE.md — SoundHealing contributor instructions

This file gives Claude-specific operating context. **Read `AGENTS.md` first**: it is the repository-wide contract for all AI assistants. Then read `docs/DESIGN_V0_1.md`, `docs/ARCHITECTURE.md`, and `docs/TOOLCHAIN_SETUP.md` as applicable.

## Mission

Build a stable and musically convincing **Skyrim Special Edition sound-healing mod**. For v0.1, favor a working singing bowl (Strike + Sing), reliable Resonant Meditation, reproducible builds, and one forge-craftable bowl. Keep lore and effects grounded in Skyrim's tonal-magic vocabulary; no real-world medical claims.

## Verified project context (recheck against the checkout)

- GitHub: `paulj3/Skyrim-SoundHealing`; output plugin `SoundHealing.esp`.
- Serialized game records live under `plugin-src/SoundHealing/`; editable Papyrus source was under `src/papyrus/`.
- Builds previously used `scripts/build.ps1`, `.vscode/tasks.json`, Spriggit `0.41.0` and a Papyrus compiler.
- `JP_SH_BowlPrototype` WEAP 003322 → `JP_SH_EnchPrototypeStrike` ENCH 003889 → `JP_SH_MGEFPrototypeStrike` MGEF 003326 → `JP_SH_ProjectileStrike` PROJ 00388A.
- The release sound record in that sampled Strike MGEF points to `JP_SH_ResonantMeditationSound` (001D93).
- Previous `JP_SH_SingMagickaDrainScript.psc` experiment: 6 Magicka/s at 0.25 s intervals; on insufficient Magicka, interrupt cast. Meditation: ~30 s, 10-unit movement tolerance, 0.25 s checks, movement/combat cancellation.

These values are historical working notes, not proof of the current repository state. Inspect code and YAML before editing.

## How to approach work

1. **Orient:** run `git status`, inspect relevant files, read existing docs and nearby records/scripts; identify FormKeys and affected assets.
2. **State the smallest plan:** which exact source files and records to modify, what behavior will change, and how to test it. Ask if requirements are ambiguous or a destructive change is contemplated.
3. **Edit source of truth:** `.psc`, Spriggit YAML, build scripts and original assets. No direct edits to `build/`, `.pex` or the generated `.esp` as a permanent source change.
4. **Protect IDs:** never regenerate or renumber existing FormKeys casually; avoid renaming `EditorID`s or adding master dependencies without explicit reasoning.
5. **Validate:** run the real build task if dependencies are available, inspect xEdit/Creation Kit, and supply an in-game manual test plan. If tools are missing, say what you did **not** verify.
6. **Report:** concise change summary, paths touched, commands run, observed output, open risks and next test.

## Critical engineering rules

- Preserve `JP_SH_` naming and script filename/class name parity.
- Keep **Strike** FireAndForget / charge-based and **Sing** Concentration / script-drained Magicka distinct unless an approved redesign changes the model.
- Script state must clean up on natural finish, interruption, and abnormal exits; never leave regen bonuses or timers running.
- Treat YAML `FormKey`, `EditorID` and references as authoritative even if filenames differ.
- Never invent Papyrus APIs, Spriggit CLI flags, or Skyrim record names; look at source, tool help or documented examples first.
- Do not pretend that a passing deserialization guarantees gameplay correctness.
- Do not add third-party binaries, copyrighted Skyrim assets, secrets or downloaded tools to Git. Exclude `tools/Spriggit-0.41.0/`, generated outputs, and extracted vanilla references.
- Use simple, reviewable diffs. Avoid refactoring unrelated code or mass-reformatting YAML.
- Update docs alongside design or architectural changes.

## Commands to discover actual project behavior (PowerShell)

```powershell
git status
git diff --stat
Get-ChildItem -Recurse -Filter build.ps1 | Select-Object FullName
Get-Content .\.vscode\tasks.json -ErrorAction SilentlyContinue
Get-ChildItem .\src\papyrus -Recurse -Filter *.psc -ErrorAction SilentlyContinue
Get-ChildItem .\plugin-src\SoundHealing -Recurse -Filter *.yaml -ErrorAction SilentlyContinue | Select-Object -First 20
```

Do not assume every path exists. If `scripts/build.ps1` is present, examine it before running it. Run project tasks only when safe and available.

## Suggested response format for code tasks

- **Understanding:** target behavior, the relevant source and record graph.
- **Plan:** exact edits and any record/FormKey implications.
- **Implementation:** narrow patch and why it is safe.
- **Validation:** build/compiler output, what was actually run vs not run, required manual tests.
- **Caveats:** compatibility, assets, or save-game risks.

## What counts as done

A feature is *not* done merely because the YAML looks plausible or Papyrus compiles. It is done when the output plugin resolves correctly and the actual interaction is tested in Skyrim, including initial equip, re-equip, release/interruption, and save/load behavior relevant to the change.
