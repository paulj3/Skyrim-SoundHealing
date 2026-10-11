# SoundHealing — Version 0.1 Design Document

**Project:** SoundHealing for The Elder Scrolls V: Skyrim Special Edition  
**Target release:** v0.1 — first playable, reproducible prototype  
**Document status:** Working design proposal, 2026-10-11  
**Repository:** `paulj3/Skyrim-SoundHealing`

## 1. Vision

SoundHealing introduces **resonance as a playable form of magic** within Skyrim. Players should be able to pick up an instrument, hear its characteristic sound, and use it as more than a cosmetic prop. A singing bowl can project a resonant attack, sustain a restorative tone, and support quiet meditation. The system should feel at home in Skyrim's world of tonal magic, without requiring players to know anything about modern sound-bath practice.

The artistic direction favors tactile musical instruments, sustained and expressive audio, restrained visual effects, and systems that reward deliberate use rather than frantic button-mashing. Real-world sound healing provides the creative vocabulary, **not** a claim that audio frequencies medically heal people. Gameplay effects are fantasy mechanics.

**One-sentence promise:** *A player can craft and equip a singing bowl, use resonant sound in combat and restoration, and experience a short meditative state that has meaningful in-game effects.*

## 2. Release philosophy

Version 0.1 is a **vertical slice**, not a content-complete magic school. We prioritize an end-to-end loop that installs cleanly, sounds right, functions reliably, and can be rebuilt from source:

1. Find or craft a singing bowl.
2. Equip it and use at least one working sonic ability.
3. Explore a complementary non-combat/restorative use.
4. Get consistent audiovisual feedback.
5. Repeat the experience after reloading a save, re-equipping, and rebuilding from source.

A limited but polished core is better than many partly configured records.

## 3. Scope and feature priorities

| Priority | Feature | Proposed v0.1 acceptance criterion | State when drafted |
|---|---|---|---|
| P0 | Singing bowl equipment | At least one bowl uses an appropriate model/texture, appears correctly when equipped, and activates in game | Prototype and bronze texture previously demonstrated; verify latest build |
| P0 | **Strike** (impulse) | Fire-and-forget sonic attack with a resolvable projectile/effect, distinguishable sound, and appropriate resource cost | Strike prototype YAML exists; full in-game test required |
| P0 | **Sing** (sustain) | Concentration behavior consumes Magicka continuously and stops when the caster cannot pay | Script behavior previously implemented; regression test required |
| P0 | **Resonant Meditation** | Roughly 30-second restorative buff that ends if the player moves outside tolerance or enters combat | Previously tested in game |
| P0 | Reproducible build & distribution | Source → Papyrus `.pex` + Spriggit → `SoundHealing.esp` + assets, with no bundled proprietary/large tools in Git | Build script previously succeeded; clean-machine verification pending |
| P0 | Forge crafting | At least one playable forge recipe produces a bowl with sensible ingredients | Planned; not verified implemented |
| P1 | Material variants | A second metal variant with a clear cosmetic or gameplay distinction | Planned; can defer if it risks P0 quality |
| P1 | Tunable effects/enchantments | A working, well-defined sonic effect linked to a bowl enchantment, using stable record references | Strike enchantment prototype exists; general enchantment system not finished |
| P2 | Healing nearby NPCs | Supportive resonance affecting allies with safe targeting rules | Future; not a v0.1 gate |
| P2 | More instruments / ritual spaces | Additional bowls, flutes, quests, dedicated animations, or new progression | Future |

**Release rule:** P0 items must pass, including one forge-craftable bowl. P1 expands beyond that minimum (material variants and more flexible enchantments); unresolved P1 items should be clearly listed in release notes, not represented as shipped.

## 4. Player-facing mechanics

### 4.1 Strike — resonant impulse

A short activation sends a directed sonic impact toward a target. In the working prototype, Strike is modeled with Skyrim's **FireAndForget** casting and a staff enchantment/magic-effect/projectile chain. Strike consumes the staff/enchantment charge according to configured game data; it should not silently drain the Sing resource.

Design goals: clear activation feedback; recognizable tone; visible but restrained projectile; predictable damage/cost; no use of leftover fire-themed descriptions or particles in the final presentation.

**Prototype control shorthand:** Strike was explored as the secondary/left-trigger or mouse-right action; this is a design reference, **not** a guaranteed binding. Skyrim's actual handedness and input mapping must be validated in game before documenting final controls.

### 4.2 Sing — sustained resonance

A held activation emits a sustained tone. The earlier prototype uses a **Concentration** magic effect and `JP_SH_SingMagickaDrainScript.psc` to drain **6 Magicka/second**, checked on **0.25-second ticks**; the script interrupts casting when Magicka is insufficient. The prototype raised a weapon charge capacity to approximately **100,000** as a workaround so built-in enchantment charge would not prematurely end a Magicka-driven Sing action. These are current prototype values, **not** finalized balance decisions.

Possible v0.1 outcome: a sustained restorative or non-lethal effect distinguishable from Strike. Avoid promising area healing without implementing targeting and balance tests. A held musical tone that interrupts cleanly is a meaningful first milestone even if its effect is deliberately modest.

**Prototype control shorthand:** Sing was explored as the primary/right-trigger or mouse-left action; verify actual equipped-hand and input behavior in game.

### 4.3 Resonant Meditation

A brief self-directed ritual creates a restorative state for approximately **30 seconds** using the player's `HealRateMult`, `MagickaRateMult`, and `StaminaRateMult`. `JP_SH_ResonantMeditationScript` is attached as an `ActiveMagicEffect` implementation; earlier values included **MovementTolerance = 10.0** and **CheckInterval = 0.25**. Movement outside the threshold or entering combat should cancel the experience.

**Invariants:** no permanent stat changes; no stacking exploit; all buffs/visual/audio state cleaned up on natural expiry, interruption, spell dispel, save/reload, and re-cast. Test exact restoration semantics against actual script source before release.

### 4.4 Crafting and progression

Crafting should establish that bowls are tangible objects in Tamriel. Start with a simple forge recipe and materials appropriate to Skyrim's smithing vocabulary. Material variation can later influence tone, charge, weight, enchantability, or spell behavior—but only add differences that the player can perceive.

Suggested early material ladder: one completed **bronze-like** prototype, then a second variant once the first recipe and assets work. Exact ingredients, perks, recipes, and balance values are **TBD**, not current implementation facts.

## 5. Lore and presentation

Skyrim already contains the broad fantasy idea of **tonal forces** and ancient magic responsive to voice and sound. SoundHealing should draw inspiration from tonal architecture, Dwemer resonance, Thu'um-adjacent themes, and bardic traditions without asserting that all traditions are the same thing.

Creative rules:

- Audio leads; particle effects support the sound rather than obscure it.
- Aim for believable, instrument-like bronze and crystal surfaces, not generic glowing fantasy props.
- Give each instrument a recognizable attack, sustain, and release character.
- Be respectful of real-world healing traditions; keep medical promises out of player-facing copy.
- Use original or appropriately licensed recordings and assets; track provenance in project notes.

## 6. Minimum test plan and release gates

### Installation / build

- A new contributor follows `docs/TOOLCHAIN_SETUP.md` without relying on undocumented global paths.
- Papyrus source compiles to `.pex`; Spriggit materializes `SoundHealing.esp`; required assets install to the correct `Data` paths.
- All references resolve when loaded in Creation Kit or xEdit; plugin does not introduce accidental masters.
- Git history excludes large third-party executables and derived build output.

### Gameplay

- Equip the bowl after loading a saved game; verify first equip **and re-equip** audio/mesh behavior.
- Strike fires, hits, plays the expected sound, and consumes the expected resource.
- Sing starts, loops without unintended repeated effects, drains Magicka at the intended rate, and stops on release/insufficient Magicka.
- Meditation starts, ends after its duration, stops on movement/combat, and restores all modified actor values.
- Test indoors/outdoors, combat/non-combat, with nonzero/zero Magicka, and after save/reload.
- Forge recipe produces a usable bowl and the ingredient/perk requirements behave as intended.

### Distribution

- Package only needed `SoundHealing.esp`, compiled scripts, meshes, textures, and sound files.
- Verify clean enable/disable via the chosen mod manager, stable plugin dependencies, and credit/licensing notes.
- Record known limitations, supported game version, and v0.1 checklist results.

## 7. Exclusions and deferred design questions

**Not necessary for v0.1:** a standalone skill tree, NPC healing AI, custom animation rigging, large questline, every type of sound bath instrument, external SKSE dependency, or medical/therapeutic claims.

**Resolve before finalizing the milestone:** exact shipped Sing effect; number of variants beyond the first craftable bowl; final damage/regen balance; whether one-handed vs dual-action controls are practical with vanilla Skyrim constraints; release compatibility target and load-order expectations.

## 8. Definition of done

Version 0.1 is ready when a fresh installation can reproduce the experience described in the one-sentence promise, the build is repeatable, the source repository is recoverable, and no known issue breaks core audio, casting, cleanup, or saved-game behavior. Any scope not demonstrably tested must be described as experimental or deferred.
