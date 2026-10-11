# SoundHealing — Verified Technical Architecture

**Repository:** [paulj3/Skyrim-SoundHealing](https://github.com/paulj3/Skyrim-SoundHealing)  
**Audited baseline:** `main` at `a9ebf583b6c6c56249d15b914b35ed524eee3eb5` (2026-10-11 documentation review)  
**Evidence level:** Verified by reading tracked source/YAML/build configuration. **No Windows build, xEdit inspection, or in-game test was performed as part of this documentation audit.**  
**Scope:** Describes the implementation actually present, not the entire [v0.1 design](DESIGN_V0_1.md).

## 1. Architecture at a glance

SoundHealing is a **Skyrim Special Edition** plugin with four different artifact types:

1. **Game records:** Spriggit YAML files under `plugin-src/SoundHealing/` define Skyrim weapons, staff enchantments, magic effects, projectiles, spells, sounds, and scripts attached to records.
2. **Behavioral code:** Two `ActiveMagicEffect` subclasses in `src/papyrus/*.psc` implement Magicka drain and meditation state/cleanup.
3. **Media assets:** `assets/` contains deployed NIFs, DDS textures, and WAV audio. `asset-src/blender/` contains editable Blender authoring projects.
4. **Build/deployment:** `scripts/build.ps1` deserializes YAML into an ESP, compiles both Papyrus scripts into PEX files, then copies the ESP, PEX files, and assets directly into Skyrim's `Data` folder.

~~~text
plugin-src/SoundHealing/ (+ RecordData.yaml, spriggit-meta.json)
                    |
                    | Spriggit 0.41.0 deserialize
                    v
              build/SoundHealing.esp ----------------+
                                                     |
src/papyrus/*.psc -> PapyrusCompiler.exe -> build/Scripts/*.pex
                                                     |
assets/{Meshes,Textures,Sound}/ ---------------------+
                                                     |
                                            scripts/build.ps1
                                                     |
                      Skyrim Special Edition/Data/{SoundHealing.esp,
                               Scripts/, Meshes/, Textures/, Sound/}
~~~

**Important:** Papyrus PEX files do not get embedded in the ESP by this script. The ESP's magic-effect records refer to scripts by name, and the script binaries are deployed separately.

## 2. Repository map and source-of-truth rules

| Tracked path | Actual responsibility |
|---|---|
| `plugin-src/SoundHealing/` | Editable serialized plugin records and metadata; primary plugin data source for the build |
| `src/papyrus/` | The two editable `.psc` script sources |
| `assets/Meshes/SoundHealing/Weapons/Bowl/` | `JP_SH_BowlPrototype.nif` and `JP_SH_BowlEquipped.nif` |
| `assets/Textures/SoundHealing/Weapons/Bowl/` | `JP_SH_BowlBronze_d.dds` and `JP_SH_BowlBronze_n.dds` |
| `assets/Sound/FX/SoundHealing/ResonantMeditation/` | `JP_SH_ResonantMeditation.wav` |
| `asset-src/blender/` | Three editable `.blend` files, including `JP_SH_BowlEquipped.blend` |
| `scripts/build.ps1` | Build and direct deployment orchestration |
| `.vscode/tasks.json` | One default VS Code build task, `Build SoundHealing` |
| `plugin/SoundHealing.esp` | Tracked binary copy/snapshot; **not an input to `build.ps1`** |
| `docs/`, `CLAUDE.md`, `AGENTS.md` | Documentation and contributor instructions |
| `build/` | Generated ESP/PEX output, excluded by `.gitignore` |
| `tools/Spriggit-0.41.0/` | Expected **local installation**, excluded by `.gitignore` and not distributed in the repo |

A change made only to `plugin/SoundHealing.esp` or `build/SoundHealing.esp` will **not** survive the next YAML-based rebuild. Put durable record changes into `plugin-src/SoundHealing/`; put durable script changes into `src/papyrus/`.

There is currently **no forge crafting recipe** folder/`COBJ` record in the tracked YAML tree. Forge crafting belongs to the design roadmap, not the verified implementation.

## 3. Serialization and record identity

`plugin-src/SoundHealing/RecordData.yaml` declares:

~~~yaml
SpriggitSource:
  PackageName: Spriggit.Yaml.Skyrim
  Version: 0.41
ModKey: SoundHealing.esp
GameRelease: SkyrimSE
ModHeader:
  Author: DEFAULT
  MasterReferences:
  - Master: Skyrim.esm
    FileSize: 0
  INTV: 1
~~~

`spriggit-meta.json` specifies `Spriggit.Yaml.Skyrim` **0.41.0**, `SkyrimSE`, and `SoundHealing.esp`. The serialized header lists `Skyrim.esm` as a master. That does not prove clean xEdit compatibility or that all runtime assets resolve.

**Identifiers are more authoritative than filenames.** For example, the tracked file named `JP_SH_EnchPrototypeResonance - 003889_SoundHealing.esp.yaml` has `EditorID: JP_SH_EnchPrototypeStrike`. Likewise, the file `JP_SH_ProjectileResonance - 00388A_SoundHealing.esp.yaml` has `EditorID: JP_SH_ProjectileStrike`. Never derive an EditorID by stripping a YAML filename.

References use `FormKey` values of the shape `003889:SoundHealing.esp` or `013F42:Skyrim.esm`. Preserve existing FormKeys and master references unless explicitly migrating records.

## 4. Strike: directed, fire-and-forget staff prototype

**Verified serialized graph:**

~~~text
WEAP  003322  JP_SH_BowlPrototype
  ObjectEffect -> 003889
     ENCH  003889  JP_SH_EnchPrototypeStrike
       CastType FireAndForget; TargetType Aimed
       Effect.BaseEffect -> 003326 (Magnitude 25; Duration 1)
          MGEF 003326  JP_SH_MGEFPrototypeStrike
            CastType FireAndForget; TargetType Aimed
            ActorValue Health; Projectile -> 00388A
               PROJ 00388A  JP_SH_ProjectileStrike
            Release sound -> 001D93
               SNDR 001D93  JP_SH_ResonantMeditationSound
~~~

Representative source paths:

- `plugin-src/SoundHealing/Weapons/JP_SH_BowlPrototype - 003322_SoundHealing.esp.yaml`
- `plugin-src/SoundHealing/ObjectEffects/JP_SH_EnchPrototypeResonance - 003889_SoundHealing.esp.yaml`
- `plugin-src/SoundHealing/MagicEffects/JP_SH_MGEFPrototypeResonance - 003326_SoundHealing.esp.yaml`
- `plugin-src/SoundHealing/Projectiles/JP_SH_ProjectileResonance - 00388A_SoundHealing.esp.yaml`

**Current data, not aspirational behavior:** The Strike WEAP record still uses `Weapons\Forsworn\ForswornStaff.nif` (a vanilla model), has `EnchantmentAmount: 1000`, and references the vanilla first-person model `0CC825:Skyrim.esm`. The projectile uses `Magic\FireBoltProjectile.nif`. The effect description still says that a blast of fire does damage and burning targets take extra damage. The effect's release sound points to the meditation descriptor (`001D93`). These are prototype carryovers to address before release, not evidence of custom sonic visuals.

The current record identifies `EquipmentType: 013F43:Skyrim.esm` for Strike; verify intended hand/control behavior in game rather than inferring it from the number.

## 5. Sing: self-targeted concentration staff prototype

**Verified serialized graph:**

~~~text
WEAP  00388B  JP_SH_BowlSingPrototype
  Model -> SoundHealing\Weapons\Bowl\JP_SH_BowlPrototype.nif
  FirstPersonModel -> STAT 003890 JP_SH_BowlFirstPersonModel
                         -> SoundHealing\Weapons\Bowl\JP_SH_BowlEquipped.nif
  ObjectEffect -> 00388C
     ENCH  00388C  JP_SH_EnchPrototypeSing
       CastType Concentration; TargetType Self; EnchantmentCost 0
       Effect.BaseEffect -> 00388D (Magnitude 10; Duration 1)
          MGEF 00388D  JP_SH_MGEFPrototypeSing
            CastType Concentration; TargetType Self
            MagicSkill Restoration; ActorValue Health
            VirtualMachineAdapter.Scripts -> JP_SH_SingMagickaDrainScript
            ConcentrationCastLoop sound -> 00388F
               SNDR 00388F  JP_SH_SingLoopSound
~~~

The Sing WEAP record has `EnchantmentAmount: 65535` (**not** the approximately 100,000 described in earlier working notes) and `EquipmentType: 013F42:Skyrim.esm`. Its enchantment cost is `0`; the Magicka expenditure is scripted rather than ordinary enchantment-charge spending. Its MGEF has a health-restoration description, but the precise magnitude, stacking, and effect of sustained casting require an in-game check.

`JP_SH_ProjectileSing` (`00388E`) exists in `Projectiles/` but is **not referenced by the inspected Sing WEAP → ENCH → MGEF graph**. Do not describe it as an actively used Sing projectile without another reference.

### `JP_SH_SingMagickaDrainScript.psc`

`Scriptname JP_SH_SingMagickaDrainScript extends ActiveMagicEffect`.

| Property or field | Current source value/role |
|---|---|
| `MagickaPerSecond` | `6.0` |
| `TickInterval` | `0.25` seconds |
| `DebugMode` | `True` |
| `CasterActor` | Script instance's retained caster reference |
| `SingActive` | Bool initialized false |

`OnEffectStart` saves `akCaster`, marks the cast active, and calls `RegisterForSingleUpdate(TickInterval)`. Each `OnUpdate` computes `tickCost = MagickaPerSecond * TickInterval` (default **1.5 Magicka per tick**), reads current Magicka, and either calls `CasterActor.InterruptCast()` if `currentMagicka <= tickCost` or uses `DamageActorValue("Magicka", tickCost)` and registers the next update. `OnEffectFinish` clears the flag and calls `UnregisterForUpdate()`. Debug notifications/traces are enabled by default.

This **confirms the code path**, not exact measured in-game drain timing. Validate interruption and update teardown when switching weapons, unequipping, dying, or saving/loading.

## 6. Resonant Meditation: lesser power, controller and buff

**Verified serialized graph:**

~~~text
SPEL 0012CE JP_SH_ResonantMeditation (LesserPower, FireAndForget)
  BaseEffect -> MGEF 0022F7 JP_SH_ResonantMeditationController
      VM script -> JP_SH_ResonantMeditationScript
      property JP_SH_ResonantMeditationSound -> 001D94
         SoundMarker 001D94 -> SoundDescriptor 001D93
      property ResonantMeditationBuff -> SPEL 0022F8
         JP_SH_ResonantMeditationBuff (FireAndForget)
         + HealRateMult   MGEF 0012C7 (Magnitude 100, Duration 30)
         + MagickaRateMult MGEF 0012C9 (Magnitude 100, Duration 30)
         + StaminaRateMult MGEF 0012CB (Magnitude 100, Duration 30)
~~~

The outer lesser power's serialized effect duration is **35 seconds**, while the buff's three effect durations and the script's default `MeditationDuration` are **30 seconds**. Do not flatten these into a single record duration; the controller and buff are distinct.

### `JP_SH_ResonantMeditationScript.psc`

`Scriptname JP_SH_ResonantMeditationScript extends ActiveMagicEffect`. Script properties:

| Property | Default in source |
|---|---|
| `JP_SH_ResonantMeditationSound` | `Sound` reference, populated in YAML with sound marker `001D94` |
| `ResonantMeditationBuff` | `Spell` reference to `0022F8` |
| `MovementTolerance` | `10.0` game-position units **per coordinate axis** |
| `CheckInterval` | `0.25` seconds |
| `MeditationDuration` | `30.0` seconds |
| `DebugMode` | `True` |

`OnEffectStart` plays the sound, casts the buff on the target, waits 0.25 seconds, records initial XYZ coordinates and `Utility.GetCurrentRealTime()`, then runs a **blocking `While` loop with `Utility.Wait(CheckInterval)`**. It stops if `IsInCombat()`, if **any** of X/Y/Z has changed more than `MovementTolerance` from its starting value, or if elapsed real time reaches `MeditationDuration`. Successful exit and interrupted exit both call `akTarget.DispelSpell(ResonantMeditationBuff)`, wait 0.25 seconds, log actor values in debug mode, and call `Dispel()` on the controller.

This is **not** an `OnUpdate` timer architecture. There is **no `OnEffectFinish` cleanup handler in the current meditation script**: unexpected externally terminated controller effects and save/reload behavior should be tested before assuming every exit is safe.

The three regeneration buffs are implemented as normal record effects on actor values, **not** by manually changing actor values in the script. Preserve that ownership distinction when making changes.

## 7. Media references and paths

| Source file | Deployment-relative path |
|---|---|
| `assets/Meshes/SoundHealing/Weapons/Bowl/JP_SH_BowlPrototype.nif` | `Data/Meshes/SoundHealing/Weapons/Bowl/JP_SH_BowlPrototype.nif` |
| `assets/Meshes/SoundHealing/Weapons/Bowl/JP_SH_BowlEquipped.nif` | `Data/Meshes/SoundHealing/Weapons/Bowl/JP_SH_BowlEquipped.nif` |
| `assets/Textures/SoundHealing/Weapons/Bowl/JP_SH_BowlBronze_d.dds` | `Data/Textures/SoundHealing/Weapons/Bowl/JP_SH_BowlBronze_d.dds` |
| `assets/Textures/SoundHealing/Weapons/Bowl/JP_SH_BowlBronze_n.dds` | `Data/Textures/SoundHealing/Weapons/Bowl/JP_SH_BowlBronze_n.dds` |
| `assets/Sound/FX/SoundHealing/ResonantMeditation/JP_SH_ResonantMeditation.wav` | `Data/Sound/FX/SoundHealing/ResonantMeditation/JP_SH_ResonantMeditation.wav` |

Both `JP_SH_ResonantMeditationSound` (`001D93`) and `JP_SH_SingLoopSound` (`00388F`) serialize the WAV reference as `data\Sound\FX\SoundHealing\ResonantMeditation\JP_SH_ResonantMeditation.wav`. The asset is actually staged under `assets/Sound/...` and deployed into `Data/Sound/...`. **Check the sound file resolver in game:** it is not established by source inspection whether the leading `data\` in the YAML field is interpreted/normalized correctly.

NIF files are present, but this source-level audit did **not** inspect embedded texture paths or render meshes. Test custom Sing first-person and third-person models, texture resolution, and first-equip/re-equip behavior separately.

## 8. Build and runtime boundaries

The real entry point is `scripts/build.ps1`, invoked by the default `.vscode/tasks.json` task. It does the following **in this order**:

1. Deletes and recreates the entire repository-local `build/` tree.
2. Runs the local `tools/Spriggit-0.41.0/Spriggit.CLI.exe deserialize` command on `plugin-src/SoundHealing` and writes `build/SoundHealing.esp`.
3. Compiles **all direct `*.psc` files** in `src/papyrus/`, producing `build/Scripts/*.pex` using Skyrim's `PapyrusCompiler.exe`.
4. Copies the built ESP to the hardcoded Skyrim `Data` folder.
5. Copies compiled PEX files into `Data/Scripts`.
6. Recursively copies `assets/*` to `Data`.

The script checks exit codes after Spriggit and Papyrus invocations but does not invoke xEdit, execute in-game tests, run CI, or package a distributable archive. It does **not** consume `plugin/SoundHealing.esp`. See [TOOLCHAIN_SETUP.md](TOOLCHAIN_SETUP.md) for exact paths and commands.

## 9. Architecture risks and unfinished v0.1 work

**Verified from source:**

- Strike and Sing are **two separate WEAP records**, not two independent controls bound to one instrument.
- Both modes currently share the meditation WAV via different descriptors.
- Strike retains a Forsworn staff model, vanilla first-person model, FireBolt projectile model, and inherited fire-description text.
- `JP_SH_ProjectileSing` exists without a verified active reference.
- No tracked crafting/constructible-object `COBJ` records exist.
- The tree contains `DUPLICATE001`-named inherited/prototype records; assess before release, without automatically deleting or re-keying them.
- `plugin/SoundHealing.esp` is tracked even though YAML is the build input; clarify whether it is a snapshot or remove it through an intentional change.
- Meditation cleanup occurs at the end of `OnEffectStart`; extraordinary termination and save/load need special attention.
- Build and deployment depend on local hardcoded paths and writable game files.

**Requires runtime or environment verification:**

- Actual Skyrim executable, Creation Kit and compiler compatibility versions.
- Papyrus compilation and Spriggit deserialization on a fresh machine.
- ESP master references and record validation in xEdit.
- NIF texture links, sound path resolution, audio on first equip, and re-equip behavior.
- Strike impacts/damage/charge and Sing healing, Magicka drain, concentration stop behavior.
- Meditation buff restoration on timeout, combat, movement, external dispel, death and reload.
- How v0.1 should map the proposed Strike/Sing controls to vanilla Skyrim's equip/input model.

## 10. Editing and validation protocol

1. Identify the source record by **FormKey + EditorID**, then follow every referenced FormKey before editing.
2. Change authoritative `plugin-src` YAML, `src/papyrus` PSC, or `assets`/`asset-src` source; **never rely on editing generated `build/` outputs**.
3. Preserve FormKeys, VM script names, VM object-property assignments, and the `SoundHealing.esp` ModKey.
4. Run the real build task and inspect the generated ESP/PEX files.
5. Inspect changed records/references in xEdit or Creation Kit; perform focused in-game tests.
6. Document unverified outcomes explicitly. Update this guide if record graphs, script defaults, file names or paths change.

The linked documents `AGENTS.md` and `CLAUDE.md` are contributor policies; source code and serialized records remain authoritative when an older prose description disagrees with them.
