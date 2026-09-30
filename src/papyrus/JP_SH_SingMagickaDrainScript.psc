Scriptname JP_SH_SingMagickaDrainScript extends ActiveMagicEffect

Float Property MagickaPerSecond = 6.0 Auto
Float Property TickInterval = 0.25 Auto
Bool Property DebugMode = True Auto

Actor CasterActor
Bool SingActive = False

Event OnEffectStart(Actor akTarget, Actor akCaster)
    CasterActor = akCaster
    SingActive = True

    DebugMessage("Sing started")

    RegisterForSingleUpdate(TickInterval)
EndEvent


Event OnUpdate()
    If !SingActive || CasterActor == None
        Return
    EndIf

    Float tickCost = MagickaPerSecond * TickInterval
    Float currentMagicka = CasterActor.GetActorValue("Magicka")

    If currentMagicka <= tickCost
        DebugMessage("Sing stopped: insufficient Magicka")

        SingActive = False
        CasterActor.InterruptCast()
        Return
    EndIf

    CasterActor.DamageActorValue("Magicka", tickCost)

    RegisterForSingleUpdate(TickInterval)
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
    SingActive = False
    UnregisterForUpdate()

    DebugMessage("Sing ended")
EndEvent


Function DebugMessage(String debugText)
    If DebugMode
        Debug.Notification(debugText)
        Debug.Trace("[SoundHealing] " + debugText)
    EndIf
EndFunction