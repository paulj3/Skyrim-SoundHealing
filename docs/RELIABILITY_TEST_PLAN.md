# Reliability test plan — Meditation cleanup and safe builds

## New build workflow

Default: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1`

The default build creates `build/SoundHealing.esp`, compiles `build/Scripts/*.pex`, and stages an installable tree under `build/package/Data`. It **does not** write to Skyrim's Data folder.

Explicit deployment: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Deploy`

The optional `-Deploy` flag copies staged files to Skyrim Data, overwriting matching files. Stop Skyrim and Creation Kit and back up installed mod data beforehand; deployment is not transactional and does not remove stale files. The script removes and recreates repository-local `build/` on each run.

The Skyrim root now accepts a `-SkyrimRoot "D:\Games\Skyrim Special Edition"` argument or `SKYRIM_ROOT` environment variable. Without either, the default is the existing Steam path. The script validates compiler, flag file, vanilla sources, Spriggit, and plugin source before cleaning the output folder.

## Meditation changes

`JP_SH_ResonantMeditationScript.psc` uses `OnUpdate` timer events instead of keeping `OnEffectStart` active in a blocking wait loop. A shared `CleanupMeditation` function stops updates and dispels the temporary regeneration spell. Both normal `StopMeditation` and `OnEffectFinish` call it, with a guard against duplicate cleanup. The controller's 35-second effect and the buff's 30-second record durations remain unchanged.

**Limitations:** There is no recorded sound playback handle to stop early. Overlapping meditation casts might still interact with `DispelSpell` and need testing. Papyrus compile results and live Skyrim behavior have **not been verified** by this PR.

## Mandatory Windows checks before merging

1. Run the default build. Check `build/package/Data/SoundHealing.esp`, two PEX files under `build/package/Data/Scripts`, and sound/mesh/texture assets; verify that the installed game Data folder was not modified.
2. Inspect the controller's attached script and two property references (sound marker and buff) in Creation Kit or xEdit.
3. Test optional `-Deploy` on a safe copy of Skyrim, then load the ESP.
4. Check normal ~30-second completion, combat interruption, and movement across each of X/Y/Z. Verify regeneration values/effects return to baseline every time.
5. Test external dispel, save/load mid-effect, dying, and re-casting. Look for stranded buffs and debug spam.
6. Confirm existing Strike and Sing behaviors were not regressed, and that first-equip audio/visuals still work.
7. If Papyrus reports compilation errors, fix them before merging; a committed source change alone is not evidence of a working mod.

## Source files touched

- `src/papyrus/JP_SH_ResonantMeditationScript.psc`
- `scripts/build.ps1`
- `docs/RELIABILITY_TEST_PLAN.md`
