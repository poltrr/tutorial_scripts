using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

<#
An NPC capable of following and staring at the Player.

This version has the following limitations:
- The NPC will go through any object between it and the Player.
- The NPC can only move horizontally.
- Only works in a singleplayer experience.

Created by Poltrr.
Twitter: @poltrrfn  Youtube: @poltrr
#>
npc := class(creative_device):

    <#
    A reference to the prop in charge of translating the NPC.
    The RotationProp will be this prop's child.
    #>
    @editable
    TranslationProp<private> : creative_prop = creative_prop{}
    <#
    A reference to the prop in charge of rotating the NPC.
    The NPC will be this prop's child.
    #>
    @editable
    RotationProp<private> : creative_prop = creative_prop{}
    <#
    Centimeters that the NPC will traverse per second.
    The higher the number, the faster the NPC will be.
    #>
    @editable
    UnitsPerSecond<private> : float = 100.0
    <#
    The maximum distance that the NPC can be from the Player, before it moves closer.
    The lower the number, the closer the NPC will stay to the Player.
    #>
    @editable
    MaxDistanceToPlayer<private> : float = 25.0
    <#
    A reference to the Running/Walking animation.
    #>
    @editable
    AnimationRun<private> : cinematic_sequence_device = cinematic_sequence_device{}
    
    <#
    A reference to the Player.
    #>
    var MaybePlayer<private> : ?player = false
    <#
    Describes if the NPC is currently moving.
    #>
    var IsMoving<private> : logic = false

    OnBegin<override>()<suspends>:void=
        StorePlayerReference()
        loop:
            RotateToPlayer()
            Sleep(0.0)
            if:
                not IsMoving?
            then:
                set IsMoving = true
                spawn{MoveToPlayer()}
    
    <#
    Stores a reference to the Player.
    #>
    StorePlayerReference() : void =
        if:
            Player : player = Self.GetPlayspace().GetPlayers()[0]
        then:
            set MaybePlayer = option{Player}

    <#
    Rotates the NPC in the direction of the Player.
    The rotation is only horizontal.
    #>
    RotateToPlayer() : void =
        if:
            FortCharacter : fort_character = MaybePlayer?.GetFortCharacter[]
        then:
            PlayerTranslation : vector3 = FortCharacter.GetTransform().Translation
            CurrentTranslation : vector3 = TranslationProp.GetTransform().Translation

            # Calculates the rotation to the Player.
            VectorToPlayer : vector3 = PlayerTranslation - CurrentTranslation
            RadiansToPlayer : float = ArcTan(VectorToPlayer.X, VectorToPlayer.Y)
            RotationAxis := vector3:
                X := 0.0,
                Y := 0.0,
                Z := -1.0
            NewRotation : rotation = MakeRotation(RotationAxis, RadiansToPlayer)

            # Looks at Player.
            if (RotationProp.TeleportTo[CurrentTranslation, NewRotation]) {}
            
    <#
    Moves the NPC to the Player's position.
    The movement is only horizontal.
    #>
    MoveToPlayer()<suspends> : void =
        defer:
            set IsMoving = false
        if:
            FortCharacter : fort_character = MaybePlayer?.GetFortCharacter[]
        then:
            PlayerTranslation : vector3 = 
                FortCharacter.GetTransform().Translation
            CurrentTranslation : vector3 = 
                TranslationProp.GetTransform().Translation
            CurrentRotation : rotation = 
                TranslationProp.GetTransform().Rotation
            TranslationToPlayer := vector3:
                X := PlayerTranslation.X
                Y := PlayerTranslation.Y
                Z := CurrentTranslation.Z

            DistanceToPlayer : float =
                Distance(CurrentTranslation, TranslationToPlayer)

            if:
                # Doesn't move if Player is inside its range.
                DistanceToPlayer > MaxDistanceToPlayer
            then:
                AnimationRun.Play()
                # Moves TranslationProp to the Player's translation.
                TranslationProp.MoveTo(
                    TranslationToPlayer,
                    CurrentRotation,
                    DistanceToPlayer / UnitsPerSecond
                )
                AnimationRun.Stop()
                # Waits 3 frames before continuing.
                # This helps the NPC from glitching between movements.
                Sleep(0.0); Sleep(0.0); Sleep(0.0)
