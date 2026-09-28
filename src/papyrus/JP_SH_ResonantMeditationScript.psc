Scriptname JP_SH_ResonantMeditationScript extends ActiveMagicEffect

Sound Property JP_SH_ResonantMeditationSound Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    JP_SH_ResonantMeditationSound.Play(akTarget)
EndEvent