return {
    nativeAudio = true, -- (CURRENTLY NOT SET UP)Set to false to use NUI audio instead (allows for custom sounds and better volume control, but may have a delay on first play)
    sounds = {
        boxOpen = 'openmysterybox', -- Sound played when the box is opened
        teddybear = 'evil_laugh', -- Sound played when the teddy bear rises
        boxLift = 'byebye', -- Sound played when the box lifts up
        poof = 'box_poof', -- Sound played when the box shoots up and disappears
    },
    lightingEffect = {
        enabled = true, -- Enable the lighting effect when the box is opened
        duration = 12000, -- Duration of the box light effect in milliseconds
    },
    weaponAnimation = {
        enabled = true, -- Enable the weapon rising animation when the box is opened
        duration = 7000, -- Duration of the weapon rising animation in milliseconds
    },
    boxAnimation = {
        enabled = true,
        liftHeight = 2.0,
        liftDuration = 1500,
        initialSpinSpeed = 90.0,
        maxSpinSpeed = 2880.0,
        spinAccelerationTime = 3000,
        spinDuration = 4000,

        shootHeight = 10.0,
        shootDuration = 500,

        lightningFlashDuration = 500,

        animationType = 'lift_and_spin',
    },
    teddyBearAnimation = {
        enabled = true, -- Enable special animation for teddy bear
        
        -- Phase 1: Teddy Bear Rise
        teddyRiseHeight = 10.0, -- How high the teddy bear rises into the sky
        teddyRiseDuration = 3000, -- Duration of teddy bear rising in milliseconds
        teddyFadeDuration = 1000, -- Duration of teddy bear fade out
    }
}