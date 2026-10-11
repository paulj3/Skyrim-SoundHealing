# SoundHealing — Development Tools and Setup (Windows)

**Status:** Reconstructed from the project's established development workflow; validate local paths and scripts against the checkout.  
**Primary development OS:** Windows  
**Project:** Skyrim Special Edition `SoundHealing` plugin (`SoundHealing.esp`)

## 1. Tested/observed environment versus portable requirements

The following versions were used or discussed during development, not asserted as universally required for every contributor:

| Component | Observed version or choice | Why it is used |
|---|---|---|
| Skyrim Special Edition | Game/runtime reported as **1.7.104.0** | Runtime and assets for manual playtesting; **verify** exact executable/version on each machine |
| Creation Kit | **1.7.99** (reported) | Editing and inspecting game records; debugging active plugin |
| Spriggit | **0.41.0** | Serialize/deserialize ESP records as Git-friendly YAML |
| .NET SDK | **10.0.401 x64** (reported) | Installed as part of local Spriggit tooling environment; actual required runtime must be checked with Spriggit release |
| SSEEdit / xEdit | **4.1.5f** | Inspect FormKeys, references, masters and winning overrides |
| VS Code | + Papyrus Tools extension | Papyrus authoring, tasks, navigation |
| Papyrus compiler | From compatible Creation Kit toolchain | Compile `.psc` to `.pex` |
| Vortex | Used locally | Deployment and mod-manager testing; not required if using another safe manager |
| NifSkope / Blender | Used or planned for mesh/asset work | Inspect NIF references, build meshes and source assets |
| Git for Windows + SSH | In use | Source control and GitHub backups |
| PowerShell | Windows PowerShell / PowerShell | Build, inspection, and validation commands |

**Version note:** Double-check the Skyrim runtime number before posting public compatibility guidance. Some project notes report versions that may describe a local installation or component, not a supported public release target. Do not silently modify runtime or Creation Kit versions to match this table.

## 2. Obtain the source and verify Git

In PowerShell:

```powershell
ssh -T git@github.com
git clone git@github.com:paulj3/Skyrim-SoundHealing.git
cd Skyrim-SoundHealing
git status
git remote -v
```

The remote previously appeared as HTTPS during a rejected push; either HTTPS or SSH can be valid, but SSH is recommended if the Windows machine has already been configured with a key. A GitHub clone will only work after the repository has been pushed successfully and you have access.

> **Repository hygiene:** Never commit the downloaded Spriggit executable, Skyrim/Data assets extracted from the game, proprietary Bethesda files, transient `.pex` outputs or credentials. An earlier upload was rejected because `tools/Spriggit-0.41.0/Spriggit.CLI.exe` was ~171 MB. `.gitignore` alone does not remove earlier commits containing it; see GitHub history-cleanup notes before the initial push.

## 3. Install and configure game editing tools

1. Install a legitimate copy of Skyrim Special Edition; confirm its install directory. The familiar Steam default is `C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\`, but **do not hardcode** this in shared scripts.
2. Install a compatible Creation Kit for the installed game and verify it starts.
3. Install Vortex (or your chosen mod manager). Keep the working source repository separate from the installed mod. Be mindful of deployment/purge operations; the Vortex **Purge Mods** command can change what appears in Skyrim's `Data` folder.
4. Install SSEEdit/xEdit and inspect `SoundHealing.esp` after every significant record change.
5. Install VS Code and a Papyrus language extension (the earlier workflow used **Papyrus Tools**). Point its compiler settings to the local compiler and the correct base-game script sources.
6. Install an appropriate NIF inspector/editor (NifSkope) and Blender for custom meshes, where applicable. Do not assume a Blender export is directly game-ready; check NIF conversion, shader paths, and NiTriShape/NIF compatibility.

### Creation Kit configuration

The prior setup resolved Creation Kit master-loading trouble using a setting equivalent to:

```ini
[General]
bAllowMultipleMasterLoads=1
```

Place/configure this only in the correct Creation Kit INI for your installation and version; keep a local backup of configuration first. Use Creation Kit's master selection intentionally. Confirm the plugin loads with its actual masters; do not infer a master list from examples.

### Optional quality-of-life tools

Creation Kit UI fixes, xEdit helpers, and Spriggit support scripts are optional. Capture their exact names and versions in a local contributor note if they become prerequisites. Do not treat optional developer modifications as player-facing dependencies.

## 4. Install Spriggit 0.41.0 locally (do not commit it)

The previously used executable was under:

```text
tools/Spriggit-0.41.0/Spriggit.CLI.exe
```

Download the matching release from the official Spriggit project/release distribution; verify version and contents. Keep this folder in `.gitignore` or configure a machine-local external path. The repository stores **YAML source**, not the installed tool.

Validate the CLI rather than guessing command-line flags:

```powershell
& .\tools\Spriggit-0.41.0\Spriggit.CLI.exe --help
```

Spriggit's data flow is:

```text
plugin-src/SoundHealing/ (serialized YAML + metadata)
    -- Spriggit deserialize -->
build/SoundHealing.esp
```

The existing build script is the authoritative source for exact switches, options and arguments for this version. Do not copy generic Spriggit commands from tutorials without confirming `--help` and the script.

## 5. Papyrus authoring and compilation

Expected source/build roles from the earlier workflow:

```text
src/papyrus/              editable .psc scripts
build/...                 generated .pex scripts (ignored by Git)
```

The compiler must have access to the appropriate `.psc` source imports from Skyrim and any explicitly declared dependencies. Open the workspace in VS Code, confirm compiler settings in the project's `.vscode/` files, and run the project's configured compile task. A successful compile should produce `.pex` files and report no unresolved script types/properties.

**Do not edit `.pex` output**: change `.psc`, recompile, and redeploy. Avoid putting generated scripts under version control unless a deliberate release-packaging exception is approved.

## 6. Build the mod

Previously established pipeline:

```text
YAML source  -> Spriggit -> build/SoundHealing.esp
Papyrus PSC  -> compiler -> compiled PEX
Source assets -> copy/deploy -> Skyrim/Data-relative paths
```

First find the actual build entry point in your checkout:

```powershell
Get-ChildItem -Path . -Filter build.ps1 -Recurse | Select-Object FullName
Get-Content .\.vscode\tasks.json -ErrorAction SilentlyContinue
```

In the earlier implementation the build entry point was `scripts/build.ps1` and the VS Code task ran it. If that path matches your checkout, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

**Expected:** a message equivalent to `=== BUILD SUCCESSFUL ===` and `build/SoundHealing.esp`. Inspect `scripts/build.ps1` first; it may expect a configured game path, local Spriggit CLI, Papyrus compiler, and writable deployment destination. Do not run an unknown script with elevated permissions.

After building:

```powershell
Test-Path .\build\SoundHealing.esp
Get-ChildItem .\build -Recurse -Filter '*.pex'
```

If the ESP path differs, trust the script's actual output, then update this guide.

## 7. Game deployment, mesh, texture and audio verification

The old workflow copied custom assets to Skyrim's `Data` tree. Illustrative game-relative layout:

```text
Data/
  Sound/FX/SoundHealing/ResonantMeditation/JP_SH_ResonantMeditation.wav
  Meshes/SoundHealing/...
  Textures/SoundHealing/...
  Scripts/<compiled Papyrus names>.pex
  SoundHealing.esp
```

The `JP_SH_ResonantMeditationSound` record refers to the WAV at `data\Sound\FX\SoundHealing\ResonantMeditation\JP_SH_ResonantMeditation.wav`; verify path normalization and case on deployment. A bronze bowl texture was shown working previously. For mesh work, verify **both** the `Model` field in the plugin and the texture paths embedded in the NIF.

**Known testing wrinkle:** sound/equipment state sometimes worked **after re-equipping** rather than on the initial load/equip. Test both scenarios; do not accept re-equip as a permanent fix.

## 8. Inspect and validate plugin data with xEdit

In xEdit, load the plugin and its actual masters. Inspect:

- Weapon ↔ enchantment ↔ magic effect ↔ projectile relationships.
- Referenced sound records, models, and script attachments/properties.
- Unintended override/conflict records or masters.
- Record FormKeys after YAML edits and deserialization.

YAML **filename** and the serialized `EditorID` are not necessarily identical. Treat actual fields and FormKeys as authoritative.

## 9. Git / backup checklist

Suggested ignored paths (adapt to the checkout; **avoid ignoring source assets**):

```gitignore
# Generated output
build/
scratch/
*.pex
*.tmp
*.bak
*.blend1
*.blend2
Thumbs.db
Desktop.ini

# Third-party tool binary and extracted Bethesda assets
tools/Spriggit-0.41.0/
asset-src/reference/
```

Before each push:

```powershell
git status
git diff --cached --stat
git add .
git diff --cached --stat
git commit -m "Describe the tested change"
git push
```

Check that original meshes/Blender files, textures, owned recordings, `.psc`, build scripts, plugin YAML, and docs are actually tracked, and that licensed third-party assets are not accidentally published.

## 10. Frequent issues

| Symptom | First checks |
|---|---|
| Creation Kit fails loading masters | Correct CK/game compatibility, INI settings, selected master files |
| Spriggit CLI not found | Local downloaded version/path; don't assume bundled exe in Git |
| ESP missing after build | Read script errors; inspect input `plugin-src`; confirm CLI `.NET` requirements |
| Papyrus compile fails | Import paths, source `.psc`, compiler version, script filename/class name consistency |
| Texture missing/purple | NIF material texture path, actual `Data/Textures` deploy path, mesh choice |
| Audio absent on first equip | Equip-state and load-event regression; inspect sound record and WAV path |
| `git push` fails on 100 MB file | Purge offending object from **history**, not only working tree; keep tool downloads excluded |
| Python `python` redirects to Microsoft Store | Check Windows App Execution Aliases and Python installation PATH; `py` launcher may be absent |

## 11. New-machine onboarding checklist

1. Clone source; inspect `git status` and README.
2. Install Skyrim/CK and record exact local versions.
3. Install VS Code/Papyrus compiler/xEdit; set paths.
4. Install/download Spriggit **locally**, outside version control.
5. Run Spriggit help; inspect and execute the build script.
6. Verify compiled `.pex`, `.esp`, mesh/texture/sound distribution.
7. Load in xEdit and in game; exercise Strike, Sing and Meditation.
8. Document any machine-specific fixes without committing private paths or proprietary dependencies.
