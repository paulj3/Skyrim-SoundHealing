Scriptname JP_SH_ResonantMeditationScript extends ActiveMagicEffect

Sound Property JP_SH_ResonantMeditationSound Auto
Spell Property ResonantMeditationBuff Auto

Float Property MovementTolerance = 10.0 Auto
Float Property CheckInterval = 0.25 Auto
Float Property MeditationDuration = 30.0 Auto
Bool Property DebugMode = True Auto


Event OnEffectStart(Actor akTarget, Actor akCaster)

    DebugMessage("Resonant Meditation started")

    ; Play the meditation bowl.
    JP_SH_ResonantMeditationSound.Play(akTarget)

    ; Apply all regeneration effects.
    ResonantMeditationBuff.Cast(akTarget, akTarget)

    ; Give Skyrim a moment to apply the buff.
    Utility.Wait(0.25)

    DebugActorValues(akTarget)

    ; Remember where meditation began.
    Float startX = akTarget.GetPositionX()
    Float startY = akTarget.GetPositionY()
    Float startZ = akTarget.GetPositionZ()

    ; Start our meditation clock.
    Float startTime = Utility.GetCurrentRealTime()

    Bool meditationActive = True
    Bool meditationInterrupted = False

    While meditationActive

        Utility.Wait(CheckInterval)

        ; Combat interrupts meditation.
        If akTarget.IsInCombat()
            DebugMessage("Meditation interrupted: combat")
            meditationInterrupted = True
            meditationActive = False
        EndIf

        ; Only check movement if combat did not already interrupt us.
        If meditationActive

            Float deltaX = Math.Abs(akTarget.GetPositionX() - startX)
            Float deltaY = Math.Abs(akTarget.GetPositionY() - startY)
            Float deltaZ = Math.Abs(akTarget.GetPositionZ() - startZ)

            If deltaX > MovementTolerance
                DebugMessage("Meditation interrupted: movement")
                meditationInterrupted = True
                meditationActive = False

            ElseIf deltaY > MovementTolerance
                DebugMessage("Meditation interrupted: movement")
                meditationInterrupted = True
                meditationActive = False

            ElseIf deltaZ > MovementTolerance
                DebugMessage("Meditation interrupted: movement")
                meditationInterrupted = True
                meditationActive = False
            EndIf

        EndIf

        ; Check for successful completion.
        If meditationActive

            Float elapsedTime = Utility.GetCurrentRealTime() - startTime

            If elapsedTime >= MeditationDuration
                meditationActive = False
            EndIf

        EndIf

    EndWhile

    If meditationInterrupted == False
        DebugMessage("Meditation complete")
    EndIf

    ; Clean up the regeneration buff.
    akTarget.DispelSpell(ResonantMeditationBuff)

    Utility.Wait(0.25)

    DebugActorValues(akTarget)

    ; End the controller.
    Dispel()

EndEvent


Function DebugActorValues(Actor akTarget)

    If DebugMode
        Debug.Notification("HealRateMult: " + akTarget.GetActorValue("HealRateMult"))
        Debug.Notification("MagickaRateMult: " + akTarget.GetActorValue("MagickaRateMult"))
        Debug.Notification("StaminaRateMult: " + akTarget.GetActorValue("StaminaRateMult"))
    EndIf

EndFunction


Function DebugMessage(String debugText)

    If DebugMode
        Debug.Notification(debugText)
        Debug.Trace("[SoundHealing] " + debugText)
    EndIf

EndFunction
