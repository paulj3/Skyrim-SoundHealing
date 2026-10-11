# Resonant Encounter — Development Plan

**Project:** SoundHealing for Skyrim Special Edition  
**Status:** Proposed gameplay research milestone; **not implemented**  
**Created:** 2026-10-11  
**Primary objective:** Test whether a player can use sustained sound and compassionate attention to bring a violent encounter to a **lasting, nonlethal resolution**.  
**Dependencies:** Aim for **vanilla Skyrim + Creation Kit + Papyrus + Spriggit**, without mandatory SKSE or custom animation frameworks.

Related: [v0.1 design](DESIGN_V0_1.md) · [technical architecture](ARCHITECTURE.md) · [toolchain](TOOLCHAIN_SETUP.md) · [reliability tests](RELIABILITY_TEST_PLAN.md)

## 1. Why build this?

> What if healing the world were as compelling as conquering it?

SoundHealing is a playable design laboratory for a future original game. The goal is not just a musical weapon or a prettier Calm spell. We want the player to be **surprised and delighted that sacred sound and loving-kindness can change a violent world**, and to discover that resolving conflict need not require killing everyone involved.

**Player experience hypothesis:** A player who willingly sustains a musical, restorative action in the face of danger can experience nonviolence as an **active, meaningful choice**, particularly if the consequence persists after the sound ends.

**Design constraint:** Create an opportunity for someone to choose peace, rather than depicting resonance as an infallible mechanism for overriding anyone's will. The encounter should allow uncertainty, self-protection, and a response from the other character.

## 2. The first vertical slice: one encounter, one changed life

**Working title:** The Resonant Encounter

- A **purpose-built, named hostile NPC** confronts the player in a controlled location. Do not alter randomly spawned bandits, guards, civilians, or broad vanilla factions in the first version.
- The player can defend themself through ordinary means, but can also play the singing bowl.
- A first period of steady resonance produces a **visible hesitation**: the NPC pauses or temporarily de-escalates.
- Continued resonance gives the NPC an opportunity to **lower their weapon and disengage**.
- The player is then offered a simple **nonviolent continuation** (for example, allow the NPC to leave, listen to them, or offer aid). For the prototype, a single brief line of dialogue or clear scripted action is sufficient; voice acting is optional.
- Choosing that resolution advances a **persistent quest state**. The NPC stays peaceful through the encounter's conclusion, a save/reload, and a return visit.
- The player receives feedback from the *world*, not just a damage or XP popup: the NPC puts away their weapon, departs safely, or appears later in a peaceful routine.

**Crucial test:** The NPC does **not** instantly resume attacking when Sing ends. The change must be meaningfully distinguishable from Skyrim's temporary Calm magic.

### Suggested emotional beats

| Beat | Player action | World response | Intended feeling |
|---|---|---|---|
| Threat | An enemy approaches | Weapon drawn; ordinary hostility | Familiar Skyrim tension |
| Experiment | Player starts playing Sing | The tone is audible; no immediate magical victory | Curiosity |
| Opening | Player keeps the resonance going | The NPC hesitates, slows, or disengages briefly | Surprise |
| Choice | Player continues without attacking | NPC lowers their weapon; nonviolent interaction becomes possible | Agency and compassion |
| Consequence | Player accepts a peaceful outcome | Quest stage and NPC behavior change persist | Delight and hope |

This is **not** a promise that every enemy can or should be redeemed. One thoughtfully authored encounter is enough to test the idea.

## 3. Technical baseline from the existing repository

As of the planning baseline:

- Sing is **WEAP** `JP_SH_BowlSingPrototype` (`00388B`) → staff **ENCH** `JP_SH_EnchPrototypeSing` (`00388C`) → **MGEF** `JP_SH_MGEFPrototypeSing` (`00388D`).
- Sing currently uses **Concentration**, `TargetType: Self`, and a health-restoration effect. **It does not yet heal or calm nearby hostile NPCs.**
- `src/papyrus/JP_SH_SingMagickaDrainScript.psc` drains **6 Magicka/second** on **0.25-second** updates, stopping when the caster cannot pay.
- Meditation already provides a separate example of timed state and cleanup, but **the proposed encounter is not the meditation mechanic**.
- `scripts/build.ps1` builds and stages `build/package/Data`; `-Deploy` is required to copy staged files into the Skyrim `Data` folder.
- The experimental `feature/dual-hand-singing-bowl` branch swaps the equipment slots, but the bowl tips during the staff-casting animation. **That visual issue is known and is not a blocker for testing this gameplay hypothesis.**

**Source-of-truth rule:** Retain existing FormKeys and scripts unless a narrowly scoped change is necessary. Use new `JP_SH_` identifiers and new FormKeys for new records; do not recycle an existing prototype FormKey.

## 4. Implementation approach

### Architecture sketch (proposed; not yet present)

~~~text
Player sustains Sing
  └─ Sing effect / controller (existing; minimal hook or new listener)
       └─ Encounter-specific controller (new quest script)
            ├─ NPC reference/quest alias (one unique actor)
            ├─ proximity + eligible-actor + interruption checks
            ├─ accumulated resonance time / stage
            ├─ temporary de-escalation (prototype)
            └─ quest stage -> nonviolent dialogue/action
                         -> persistent peaceful NPC state + AI package
~~~

**Recommended split of responsibilities:**

1. **Existing Sing effect** owns concentration, its audible loop, and the player's Magicka budget. Make only a small, optional integration hook once the first scripted experiment works.
2. **Encounter quest/controller** owns resonance progress, target eligibility, staging, interruption, completion, and save-persistent outcome. It should use a unique NPC reference or quest alias instead of scanning the entire world.
3. **NPC behavior/quest records** own the peaceful post-encounter schedule, dialogue/action and faction/hostility setup. A momentary `StopCombat()` call alone is **not sufficient** for persistence: combat can resume because of packages, factions, alarms, or other actors.
4. **Audio/visual presentation** provides restrained feedback. Retain current imperfect staff animations if necessary for v0.1; do not require an animation framework solely to test pacification.

**Engineering decision to spike, not assume:** How best to detect the player's active Sing concentration without tightly coupling a generic healing effect to an encounter. Candidates are an optional callback from the existing Sing script, a separate quest-scoped listener, or a small test-only spell/ability. Choose after validating what Papyrus events actually fire in game. Do not claim that a self-targeted healing MGEF automatically reaches an enemy.

### Tentative resonance timing

Use a deliberately tuneable parameter set rather than hardcoded balance:

- ~1–2 seconds: noticeable response/hesitation;
- ~4–6 seconds: temporary de-escalation;
- ~8–12 seconds: peaceful-resolution opportunity;
- interruption (release, Magicka depletion, player attack, too much separation, NPC death, quest stops): halt progress and clear **temporary** effects.

These are **playtest hypotheses**, not implementation facts or final balance. It may feel better if progress decays gently instead of instantly resetting. Decide through playtesting.

## 5. Milestones and acceptance gates

### RE-0 — Encounter design and safety specification

**Tasks**

- Choose a short, isolated test location and a single **new, controlled NPC**; do not modify a named vanilla quest NPC.
- Define the encounter's starting hostility, eligible player actions, distance/LOS rules, and what counts as a failure or surrender.
- Define one meaningful post-conflict behavior (leave peacefully, sit and reflect, return to camp, or a follow-up conversation).
- Decide how the player indicates **intentional mercy** after sound has opened a chance for peace.

**Done when:** A one-page scenario describes what changes during and **after** the sound. Scope and ethical framing are clear.

### RE-1 — Quest and NPC skeleton

**Tasks**

- In Creation Kit, create an isolated quest, one controlled hostile NPC, a reference alias, and clear states such as `Hostile`, `Listening`, `Opportunity`, `Resolved`, and `Failed`.
- Use the project's `JP_SH_` naming conventions and verify new FormKeys/master dependencies in xEdit.
- Serialize new CK records back into `plugin-src/SoundHealing` using the matching Spriggit toolchain. Review the YAML diff rather than editing only `plugin/SoundHealing.esp` or `build/SoundHealing.esp`.
- Implement a **debug-only test command or controlled trigger** to advance quest state before connecting Sing.

**Done when:** The test NPC can transition from hostile to peaceful by a controlled trigger, survives saving/loading, and does not alter vanilla NPCs or global hostility.

### RE-2 — Temporary de-escalation proof

**Tasks**

- Experiment with a vanilla Calm/Pacify-style effect or carefully scoped NPC `StopCombat()` / `StopCombatAlarm()`, followed by appropriate AI/package evaluation.
- Test what makes the NPC resume fighting: factions, detection, combat target, nearby aggressors, player assault, current AI packages, alarm state.
- Establish the **temporary** reaction independently of the permanent outcome.

**Done when:** The target NPC visibly stops attacking for a controlled interval, and a failed/interrupted attempt can restore expected hostility without leaving an unintended permanent global change.

### RE-3 — Resonance listener and player action

**Tasks**

- Connect a *minimal* signal from the existing sustained Sing experience to the encounter controller (start, ongoing, and finish/interruption).
- Validate that the target is the intended encounter NPC, alive, eligible, and in range; use one reference/alias rather than expensive broad actor searches.
- Accumulate continuous (or deliberately decaying) resonance time. Provide feedback at the thresholds, without turning it into a generic damage meter.
- Preserve Sing's existing self-restoration and 6-Magicka/sec budget while avoiding multiple update chains or orphaned listeners.
- Ensure normal/abnormal effect termination, weapon switching, Magicka depletion, and leaving the scene stop the encounter's temporary processes.

**Done when:** Ordinary Sing play—not a console command—causes the listening/de-escalation phase in the controlled encounter. Strike and Meditation still work.

### RE-4 — Persistent, nonviolent resolution

**Tasks**

- Use a **quest stage** to record that this specific encounter was resolved peacefully.
- Change the target's actor-specific hostility/AI behavior (through safely scoped packages, relationships/factions, or other CK records as needed), and stop active combat.
- Allow a brief interaction or the NPC's own choice to conclude the encounter; avoid depicting the player as permanently mind-controlling the NPC.
- Give the actor a visible post-conflict destination/routine; test unload/reload, player leaving/returning, and save/reload.
- Do not change the aggression or factions of all bandits or overwrite unrelated gameplay systems.

**Done when:** The NPC remains nonhostile after Sing ends and through a saved-game reload, with a discernibly different behavior or future.

### RE-5 — Emotional feedback and playtesting

**Tasks**

- Add subtle audio/animation or dialogue cues that show change without over-explaining a moral.
- Have several players try the encounter **without telling them how to solve it**. Observe whether they discover the option and what makes it rewarding or confusing.
- Ask whether the resolution felt earned, surprising, compassionate, coercive, or like a regular Calm spell.
- Tune duration, player vulnerability, visual feedback and failure/retry behavior.

**Done when:** At least one unfamiliar player can discover or learn the nonviolent approach and articulate that the world reacted differently because of it. Favor qualitative notes over artificial completion metrics.

## 6. Definition of done — first Resonant Encounter prototype

- [ ] One purpose-built hostile NPC and scripted encounter exist.
- [ ] The player can trigger a nonviolent opportunity through audible, sustained Sing.
- [ ] The change includes a visible NPC reaction and a meaningful follow-up choice/action.
- [ ] At least one peaceful outcome remains true **after the sound ends, after leaving the area, and after save/reload**.
- [ ] No permanent Calm state or script loop leaks into other NPCs, quests, or the player's active effects.
- [ ] Interruptions (combat, weapon switch, low Magicka, leaving range, NPC death) are tested and handled.
- [ ] Strike, Sing's original healing/charge logic, and Meditation pass regression checks.
- [ ] YAML → ESP, PSC → PEX and staging build works; installed files are tested in-game.
- [ ] No mandatory SKSE/custom-animation dependency is added for the baseline.
- [ ] Playtest feedback records whether participants experienced surprise, agency, and a sense of compassionate possibility.

## 7. Known risks and decisions for later

| Question | Working decision / validation |
|---|---|
| Does SoundHealing make people passive against their will? | Design an opening for dialogue/choice; make the lasting outcome NPC-specific and narratively legible |
| Does Calm immediately wear off? | Temporary de-escalation and permanent resolution are **different** quest phases |
| Can hostile-faction packages restart combat? | Test with xEdit/CK and in-game; ensure actor-specific post-resolution behavior |
| Is concentration too vulnerable or boring? | Tune threshold/feedback and player protection; don't assume longer is better |
| Is the cast animation visually awkward? | Accept as a prototype limitation; defer custom animation dependencies |
| Should the effect work on every enemy? | No. First prove **one** encounter; generalize only after successful playtests |
| Should the mod support every platform? | Minimize dependencies initially; verify actual distribution constraints later |
| Should peaceful outcomes award combat-like XP? | Defer. Prefer visible, meaningful world consequences over reward farming |
| Is nonviolence always the right choice? | Allow self-defense and failure; the mechanic should not shame players |

## 8. Branching and the existing dual-hand experiment

- Keep `feature/dual-hand-singing-bowl` as a valid **experimental branch**. Its equipment-slot swap works, but first-/third-person staff-casting animation tips the bowl vertically and its model/interior needs further work.
- **Do not merge that branch simply to declare the two-handed instrument complete.** If merging just the functional hand mapping, document the visual defects as known issues and test reload/re-equip.
- Build the encounter on a **separate feature branch starting from current `main`**, e.g. `feature/resonant-encounter`. If it needs the hand-slot prototype later, cherry-pick those two small YAML changes only after confirming compatibility.
- This design document lives independently of the dual-hand branch. Changes to gameplay or scope should update this file and, when appropriate, [DESIGN_V0_1.md](DESIGN_V0_1.md).

## 9. Proposed first working session

1. Choose **one NPC** and an isolated Skyrim location where a hostile interaction can be deliberately reproduced.
2. Create the quest/actor/alias and a temporary console/debug trigger that switches the actor to peaceful state.
3. Rebuild, inspect, deploy, save/reload, and return to the encounter.
4. Only after that succeeds, connect sustained Sing and add the staged emotional/narrative beats.

**The first technical risk to retire is not animated wrist rotation: it is whether a hostile NPC can become persistently nonhostile in a controlled encounter without breaking Skyrim's AI and quest systems.**

## 10. Technical references

- [Papyrus Actor.StopCombat](https://papyrus.bellcube.dev/skyrimse/script/actor/function/stopcombat/) and [Actor.StopCombatAlarm](https://papyrus.bellcube.dev/skyrimse/script/actor/function/stopcombatalarm/) — available native methods; neither is a complete persistent pacification system.
- [ActiveMagicEffect.OnEffectStart](https://papyrus.bellcube.dev/skyrimse/script/activemagiceffect/event/oneffectstart/) and [OnUpdate](https://papyrus.bellcube.dev/skyrimse/script/activemagiceffect/event/onupdate/) — lifecycle/periodic update patterns.
- [Creation Kit: EvaluatePackage](https://ck.uesp.net/wiki/EvaluatePackage) — forces AI package reevaluation; does not by itself reset combat behavior.

_This is a planned experiment, not a claim that any new quest, NPC, pacification logic, or dialogue currently exists in the repository._
