Scriptname JP_SH_ResonantMeditationScript extends ActiveMagicEffect

Sound Property JP_SH_ResonantMeditationSound Auto
Spell Property ResonantMeditationBuff Auto

Float Property MovementTolerance = 10.0 Auto
Float Property CheckInterval = 0.25 Auto
Float Property MeditationDuration = 30.0 Auto
Bool Property DebugMode = True Auto

; Each active magic effect has its own script instance and its own state.
Actor MeditationTarget
Float StartX
Float StartY
Float StartZ
Float StartRealTime
Bool MeditationActive = False
Bool CleanupComplete = False


Event OnEffectStart(Actor akTarget, Actor akCaster)
    MeditationTarget = akTarget
    CleanupComplete = False
    MeditationActive = True

    If MeditationTarget == None
        StopMeditation("Meditation ended: no target")
        Return
    EndIf

    ; Record position and start time before scheduling asynchronous checks.
    StartX = MeditationTarget.GetPositionX()
    StartY = MeditationTarget.GetPositionY()
    StartZ = MeditationTarget.GetPositionZ()
    StartRealTime = Utility.GetCurrentRealTime()

    DebugMessage("Resonant Meditation started")

    If JP_SH_ResonantMeditationSound != None
        JP_SH_ResonantMeditationSound.Play(MeditationTarget)
    EndIf

    If ResonantMeditationBuff != None
        ResonantMeditationBuff.Cast(MeditationTarget, MeditationTarget)
    Else
        StopMeditation("Meditation ended: buff property is missing")
        Return
    EndIf

    RegisterForSingleUpdate(CheckInterval)
EndEvent


Event OnUpdate()
    If !MeditationActive
        Return
    EndIf

    If MeditationTarget == None
        StopMeditation("Meditation ended: target unavailable")
        Return
    EndIf

    If MeditationTarget.IsInCombat()
        StopMeditation("Meditation interrupted: combat")
        Return
    EndIf

    ; MovementTolerance is an axis-wise distance from the start point,
    ; matching the previous implementation (not Euclidean distance).
    If Math.Abs(MeditationTarget.GetPositionX() - StartX) > MovementTolerance
        StopMeditation("Meditation interrupted: movement")
        Return
    EndIf

    If Math.Abs(MeditationTarget.GetPositionY() - StartY) > MovementTolerance
        StopMeditation("Meditation interrupted: movement")
        Return
    EndIf

    If Math.Abs(MeditationTarget.GetPositionZ() - StartZ) > MovementTolerance
        StopMeditation("Meditation interrupted: movement")
        Return
    EndIf

    Float currentRealTime = Utility.GetCurrentRealTime()
    Float elapsedTime = currentRealTime - StartRealTime

    ; Real-time clocks can restart across game sessions. Rebase rather than
    ; leaving this instance waiting indefinitely for an unreachable deadline.
    ; The controller record also has a 35-second native effect duration.
    If elapsedTime < 0.0
        StartRealTime = currentRealTime
        elapsedTime = 0.0
        DebugMessage("Meditation clock restarted")
    EndIf

    If elapsedTime >= MeditationDuration
        StopMeditation("Meditation complete")
        Return
    EndIf

    RegisterForSingleUpdate(CheckInterval)
EndEvent


; Called for natural completion and expected interruptions. Cleanup happens
; BEFORE dispelling this controller effect, so the buff is removed even if
; OnEffectFinish is delayed; OnEffectFinish remains the safety net.
Function StopMeditation(String reason)
    If !MeditationActive
        Return
    EndIf

    DebugMessage(reason)
    CleanupMeditation()
    Dispel()
EndFunction


; Idempotent: can be called from StopMeditation and OnEffectFinish.
Function CleanupMeditation()
    If CleanupComplete
        Return
    EndIf

    CleanupComplete = True
    MeditationActive = False
    UnregisterForUpdate()

    If MeditationTarget != None && ResonantMeditationBuff != None
        MeditationTarget.DispelSpell(ResonantMeditationBuff)
        DebugActorValues(MeditationTarget)
    EndIf
EndFunction


; Handles external dispels and expiry of the controller's native duration.
Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If MeditationActive
        DebugMessage("Meditation controller ended")
    EndIf

    CleanupMeditation()
EndEvent


Function DebugActorValues(Actor akTarget)
    If DebugMode && akTarget != None
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
