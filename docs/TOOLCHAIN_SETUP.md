# SoundHealing — Verified Windows Development Setup

**Audited source:** [Skyrim-SoundHealing](https://github.com/paulj3/Skyrim-SoundHealing), main commit `a9ebf583b6c6c56249d15b914b35ed524eee3eb5`, 2026-10-11.

**Verification level:** The actual committed build script, VS Code task, .gitignore, Papyrus files, serialized records and assets were inspected. A Windows build, xEdit validation and in-game tests **were not run** in this review. Treat environment-specific versions as unverified unless confirmed on your computer.

## 1. What must be installed

| Tool | Exact repository requirement |
|---|---|
| Windows PowerShell | `.vscode/tasks.json` invokes `powershell.exe` |
| Skyrim Special Edition | Existing script points to Steam install at `C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition` |
| PapyrusCompiler.exe | Must exist at `<Skyrim root>\Papyrus Compiler\PapyrusCompiler.exe` |
| Vanilla script sources | `<Skyrim root>\Data\Source\Scripts`, with `TESV_Papyrus_Flags.flg` |
| Spriggit CLI 0.41.0 | Must exist locally at `tools\Spriggit-0.41.0\Spriggit.CLI.exe` |
| VS Code | Optional editor; default task `Build SoundHealing` is committed |
| xEdit / Creation Kit | Recommended for record inspection; neither is invoked by the script |
| Blender / NifSkope | Asset authoring and mesh inspection; not build-time dependencies |
| Git | Source control; not part of the build |

Spriggit YAML metadata explicitly declares `Spriggit.Yaml.Skyrim`, version `0.41.0`, `SkyrimSE`, and `SoundHealing.esp`. Earlier reported local versions (Skyrim 1.7.104.0, Creation Kit 1.7.99, xEdit 4.1.5f, .NET SDK 10.0.401) are **historical notes, not verified minimum requirements**. Check the Spriggit release's actual .NET runtime requirements.

## 2. Clone and verify the project

```powershell
git clone git@github.com:paulj3/Skyrim-SoundHealing.git
cd Skyrim-SoundHealing
git status
```

GitHub does not contain the Spriggit executable, Skyrim, compiler, or vanilla game sources. Download the appropriate Spriggit 0.41.0 CLI release from the official upstream project and extract to:

```text
<repo>\tools\Spriggit-0.41.0\Spriggit.CLI.exe
```

Then check:

```powershell
Test-Path .\tools\Spriggit-0.41.0\Spriggit.CLI.exe
& .\tools\Spriggit-0.41.0\Spriggit.CLI.exe --help
```

`tools/Spriggit-0.41.0/` is excluded from Git because the third-party executable exceeded GitHub's 100 MB limit.

## 3. Verify the hardcoded Skyrim paths

The committed `scripts/build.ps1` defines:

```powershell
$SkyrimRoot = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition"
$DataPath = Join-Path $SkyrimRoot "Data"
$PapyrusCompiler = Join-Path $SkyrimRoot "Papyrus Compiler\PapyrusCompiler.exe"
$VanillaPapyrusSource = Join-Path $DataPath "Source\Scripts"
$FlagsFile = Join-Path $VanillaPapyrusSource "TESV_Papyrus_Flags.flg"
```

Check all dependencies:

```powershell
$SkyrimRoot = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition"
Test-Path $SkyrimRoot
Test-Path (Join-Path $SkyrimRoot "Papyrus Compiler\PapyrusCompiler.exe")
Test-Path (Join-Path $SkyrimRoot "Data\Source\Scripts\TESV_Papyrus_Flags.flg")
Test-Path (Join-Path $SkyrimRoot "Data\Source\Scripts")
```

Each should be `True`. If Skyrim is installed elsewhere, the **current build script provides no path override**: change the local `$SkyrimRoot` or implement a separately reviewed configurable path. Have a suitable Skyrim/Creation Kit Papyrus SDK installed; editor extensions alone do not provide the compiler and vanilla scripts.

## 4. Run the exact build task

The committed `.vscode/tasks.json` contains one default task, `Build SoundHealing`. It calls Windows PowerShell with `-NoProfile -ExecutionPolicy Bypass -File` and the workspace-relative `scripts\build.ps1`.

Use **Terminal → Run Build Task** in VS Code, or from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

**Warning:** This script recursively deletes the project `build/` directory and copies built files directly into the installed Skyrim `Data` directory, overwriting matching files. Do not run until you have verified paths and backed up anything in those locations that matters.

### What the script actually does

1. Sets `$ErrorActionPreference = "Stop"`, deletes and recreates `build/` and `build/Scripts/`.
2. Executes:

```powershell
& $Spriggit deserialize --InputPath $PluginSource --OutputPath $BuiltPlugin --DataFolder $DataPath
```

Here `$Spriggit` is `tools/Spriggit-0.41.0/Spriggit.CLI.exe`, `$PluginSource` is `plugin-src/SoundHealing`, and `$BuiltPlugin` is `build/SoundHealing.esp`. A nonzero exit code throws `Spriggit build failed.`

3. Enumerates **top-level** `*.psc` files under `src/papyrus/` (no recursive traversal). It compiles each source from that directory using the equivalent invocation:

```powershell
& $PapyrusCompiler $Script.Name "-i=$VanillaPapyrusSource;$ProjectPapyrusSource" "-o=$BuiltScripts" "-f=$FlagsFile"
```

The two tracked Papyrus classes are `JP_SH_ResonantMeditationScript` and `JP_SH_SingMagickaDrainScript`. Each compiler invocation is exit-code checked.

4. Copies `build/SoundHealing.esp` into `Data/SoundHealing.esp`; copies `build/Scripts/*` into `Data/Scripts`; and recursively copies `assets/*` into `Data`.
5. Prints `=== BUILD AND DEPLOY SUCCESSFUL ===` after the copy operations.

**Not performed:** xEdit validation, mod-manager packaging, a release ZIP, runtime tests, or a comparison with `plugin/SoundHealing.esp`. That tracked ESP is a binary snapshot **not read by the build script**. Generated output and tracked snapshot can diverge.

## 5. Confirm the resulting files

Run after building:

```powershell
Test-Path .\build\SoundHealing.esp
Get-ChildItem .\build\Scripts -Filter '*.pex'
$Data = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data"
Test-Path (Join-Path $Data "SoundHealing.esp")
Test-Path (Join-Path $Data "Scripts\JP_SH_ResonantMeditationScript.pex")
Test-Path (Join-Path $Data "Scripts\JP_SH_SingMagickaDrainScript.pex")
Test-Path (Join-Path $Data "Meshes\SoundHealing\Weapons\Bowl\JP_SH_BowlPrototype.nif")
Test-Path (Join-Path $Data "Meshes\SoundHealing\Weapons\Bowl\JP_SH_BowlEquipped.nif")
Test-Path (Join-Path $Data "Textures\SoundHealing\Weapons\Bowl\JP_SH_BowlBronze_d.dds")
Test-Path (Join-Path $Data "Textures\SoundHealing\Weapons\Bowl\JP_SH_BowlBronze_n.dds")
Test-Path (Join-Path $Data "Sound\FX\SoundHealing\ResonantMeditation\JP_SH_ResonantMeditation.wav")
```

All should be present after full deployment. File presence does **not** establish that meshes, script properties or sounds resolve in game. A Vortex purge/deploy may also affect manually copied files; coordinate mod-manager ownership.

## 6. Verify game record wiring with xEdit and Creation Kit

Open the generated/deployed `SoundHealing.esp` with compatible xEdit or Creation Kit:

- **Strike:** `WEAP 003322 → ENCH 003889 → MGEF 003326 → PROJ 00388A`. The current YAML still references a vanilla Forsworn staff model, FireBolt projectile, and legacy fire-damage description.
- **Sing:** `WEAP 00388B → ENCH 00388C → MGEF 00388D`; script attachment `JP_SH_SingMagickaDrainScript`, model `003890`, sound `00388F`. Serialized WEAP charge capacity is **65535**, enchantment cost **0**.
- **Meditation:** Lesser Power `0012CE → MGEF 0022F7` running `JP_SH_ResonantMeditationScript` → buff `SPEL 0022F8` with effects `0012C7`, `0012C9`, `0012CB`.

The script's meditation Sound property is assigned **sound marker 001D94**, which references descriptor **001D93**. Both Sing and meditation sound descriptors reference the same WAV, whose serialized source string begins `data\Sound\FX\...`. Inspect in-game sound path resolution rather than treating this as verified playback.

Verify NIF embedded DDS paths in NifSkope and compare to files under `assets/Textures/SoundHealing/Weapons/Bowl`.

## 7. Manual runtime checklist — not yet executed in this audit

Test fresh load and re-equip; Strike aim, sound, damage, charge and hit; Sing concentration start/end, Magicka drain (script defaults **6 per second**, updates every **0.25 seconds**), insufficient-Magicka cutoff and weapon-switch cleanup. Test meditation on timeout, movement, combat, re-cast, dispel and save/load. Its source contains a `Utility.Wait`-based loop and cleanup at the end of `OnEffectStart`, **not** an `OnEffectFinish` cleanup handler; abnormal termination needs dedicated checks.

Do not claim v0.1 gameplay works because deserialization or compilation passed.

## 8. Source control and common pitfalls

The actual committed `.gitignore` ignores `build/`, `*.pex`, `scratch/`, `*.tmp`, `*.bak`, `*.blend1`, `*.blend2`, `asset-src/reference/`, `Thumbs.db`, `Desktop.ini`, and `tools/Spriggit-0.41.0/`.

Commit serialized YAML, PSC, owned original Blender files, NIFs, DDS files, licensed WAVs, and docs. Do not commit the Spriggit binary, extracted Bethesda content or secrets.

The initial git push previously failed on an oversized Spriggit EXE; history containing that blob must be cleaned before it can be accepted even after ignoring the path. The current GitHub repo is now accessible, but do not infer local worktree equality from the remote.

When troubleshooting, check in this order: required executable `Test-Path` outputs, Spriggit schema version, compiler flags/imports, successful build outputs, deployment paths, xEdit record references, embedded NIF paths, then actual Skyrim behavior.

For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md). For milestone scope, see [DESIGN_V0_1.md](DESIGN_V0_1.md).
