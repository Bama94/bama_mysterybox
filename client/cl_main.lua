local config = require 'config.client'
local sharedConfig = require 'config.shared'
local weapons = require 'config.weapons'.weapons
local bears = require 'config.weapons'.bearModelName
local boxEntity, newBoxEntity
local isRolling = false
local locations, emptyBoxEntity = {}, {}

-----------------
--- FUNCTIONS ---
-----------------
local function isBearModel(name)
    for i = 1, #bears do
        if bears[i] == name then
            return true
        end
    end
    return false
end
local function createTargetOptions(entity, boxLocation)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'mysterybox_use',
            label = "Use Mystery Box ($" .. sharedConfig.price .. ")",
            icon = 'fa-solid fa-gift',
            distance = 3.5,
            onSelect = function (data)
                if isRolling then
                    lib.notify({
                        title = 'Mystery Box',
                        description = 'Someone is already using the box!',
                        type = 'error'
                    })
                    return
                end
                TriggerServerEvent('bama_mysterybox:server:useBox', boxLocation)
            end
        }
    })
end
local function spawnMysteryBox(location, createTarget)
    if boxEntity then DeleteEntity(boxEntity) end
    if newBoxEntity then DeleteEntity(newBoxEntity) end
    if emptyBoxEntity[location.id] and DoesEntityExist(emptyBoxEntity[location.id]) then 
        DeleteEntity(emptyBoxEntity[location.id]) 
        emptyBoxEntity[location.id] = nil
    end

    lib.requestModel(joaat(location.model), 5000)

    boxEntity = CreateObjectNoOffset(
        location.model,
        location.coords.x,
        location.coords.y,
        location.coords.z,
        true,
        false,
        false
    )
    SetEntityRotation(boxEntity, 0.0, 0.0, location.coords.w, 2, true)
    FreezeEntityPosition(boxEntity, true)
    SetModelAsNoLongerNeeded(location.model)
    PlaceObjectOnGroundProperly(boxEntity)

    if createTarget then createTargetOptions(boxEntity, location) end
end

local function spawnEmptyBoxes(data)
    print(json.encode(data))
    -- CASE 1: single location passed
    if data and data.id then
        local location = data
        local id = location.id

        if DoesEntityExist(emptyBoxEntity[id]) then
            DeleteEntity(emptyBoxEntity[id])
        end

        local model = joaat(location.empty)
        lib.requestModel(model, 5000)

        emptyBoxEntity[id] = CreateObjectNoOffset(
            model,
            location.coords.x,
            location.coords.y,
            location.coords.z,
            true,
            false,
            false
        )

        SetEntityRotation(emptyBoxEntity[id], 0.0, 0.0, location.coords.w, 2, true)
        FreezeEntityPosition(emptyBoxEntity[id], true)
        SetModelAsNoLongerNeeded(model)
        PlaceObjectOnGroundProperly(emptyBoxEntity[id])

        return
    end

    -- CASE 2: batch spawn (startup)
    for _, location in pairs(data) do
        local id = location.id

        if DoesEntityExist(emptyBoxEntity[id]) then
            DeleteEntity(emptyBoxEntity[id])
        end

        local model = joaat(location.empty)
        lib.requestModel(model, 5000)

        emptyBoxEntity[id] = CreateObjectNoOffset(
            model,
            location.coords.x,
            location.coords.y,
            location.coords.z,
            true,
            false,
            false
        )

        SetEntityRotation(emptyBoxEntity[id], 0.0, 0.0, location.coords.w, 2, true)
        FreezeEntityPosition(emptyBoxEntity[id], true)
        SetModelAsNoLongerNeeded(model)
        PlaceObjectOnGroundProperly(emptyBoxEntity[id])
    end
end

local function playSound(coords, sound)
    if config.nativeAudio then
       RequestScriptAudioBank('audiodirectory/mysterybox_sounds', false)
        local soundId = GetSoundId()

        PlaySoundFromCoord(soundId, sound, coords.x, coords.y, coords.z, 'MYSTERYBOX_SOUNDS_SOUNDSET', false, 0, false)
        ReleaseSoundId(soundId)
        ReleaseNamedScriptAudioBank('audiodirectory/mysterybox_sounds')
    else
        local volume = (0.01 * GetProfileSetting(300)) / 1.0
        if volume > 1 then volume = 1 end

        SendNUIMessage({
            action = 'playSound',
            data = {
                sound = sound or 'openmysterybox',
                volume = volume
            }
        })
    end
end

local function createTeddyBearAnimation(location, teddyBear)
    if not DoesEntityExist(teddyBear) and not DoesEntityExist(newBoxEntity) then return end

    -- Store original positions
    local teddyCoords = DoesEntityExist(teddyBear) and GetEntityCoords(teddyBear) or location.coords
    
    CreateThread(function()
        -- =====================
        -- PHASE 0: SWAP OPENED BOX TO CLOSED MODEL
        -- =====================
        if not DoesEntityExist(boxEntity) then spawnMysteryBox(location, false) end
        SetEntityCollision(boxEntity, false, false)

        local fadeAlpha = 255
        local fadeAlpha2 = 0
        while fadeAlpha > 0 do
            Wait(0)
            SetEntityAlpha(boxEntity, fadeAlpha, false)
            SetEntityAlpha(boxEntity, fadeAlpha2, false)
            fadeAlpha = fadeAlpha - 30
            fadeAlpha2 = fadeAlpha2 + 30
            Wait(10)
        end
        
        -- =====================
        -- PHASE 1: TEDDY BEAR RISES WITH EVIL LAUGH
        -- =====================
        
        -- Play evil laugh sound
        playSound(teddyCoords, config.sounds.teddybear)
        
        if DoesEntityExist(teddyBear) then
            FreezeEntityPosition(teddyBear, false)
            local startHeight = teddyCoords.z
            local targetHeight = startHeight + config.teddyBearAnimation.teddyRiseHeight
            local startTime = GetGameTimer()
            local riseDuration = config.teddyBearAnimation.teddyRiseDuration
            
            -- Teddy rises up
            while DoesEntityExist(teddyBear) and GetGameTimer() - startTime < riseDuration do
                Wait(0)
                local elapsed = GetGameTimer() - startTime
                local progress = elapsed / riseDuration
                local easeProgress = 1 - math.cos(progress * math.pi / 2) -- Ease out
                
                local currentHeight = startHeight + (targetHeight - startHeight) * easeProgress
                
                SetEntityCoordsNoOffset(teddyBear, teddyCoords.x, teddyCoords.y, currentHeight, false, false, false)
                
                -- Gentle spin while rising
                local spin = (elapsed / 1000.0) * 180.0
                SetEntityRotation(teddyBear, 0.0, 0.0, spin % 360, 2, true)
            end
            
            -- Teddy fades away
            local fadeStart = GetGameTimer()
            local fadeDuration = config.teddyBearAnimation.teddyFadeDuration
            local alpha = 255
            
            while alpha > 0 and DoesEntityExist(teddyBear) do
                Wait(0)
                local elapsed = GetGameTimer() - fadeStart
                alpha = math.floor(255 * (1 - (elapsed / fadeDuration)))
                if alpha < 0 then alpha = 0 end
                SetEntityAlpha(teddyBear, alpha, false)
            end
            
            -- Delete teddy bear
            if DoesEntityExist(teddyBear) then
                DeleteEntity(teddyBear)
            end
        end
        
        -- =====================
        -- PHASE 2: BOX LIFTS AND SPINS
        -- =====================
        
        Wait(500) -- Brief pause
        
        -- Play box lift sound
        playSound(vec3(location.coords.x, location.coords.y, location.coords.z), config.sounds.boxLift)
        
        if DoesEntityExist(boxEntity) then
            FreezeEntityPosition(boxEntity, false)
            local startHeight = location.coords.z
            local targetHeight = startHeight + config.boxAnimation.liftHeight
            local startTime = GetGameTimer()
            local spinAngle = 0.0
            
            -- Lift box off ground while starting to spin
            while DoesEntityExist(boxEntity) and GetGameTimer() - startTime < config.boxAnimation.liftDuration do
                Wait(0)
                local elapsed = GetGameTimer() - startTime
                local progress = elapsed / config.boxAnimation.liftDuration
                local easeProgress = 1 - math.cos(progress * math.pi / 2)
                
                local currentHeight = startHeight + (targetHeight - startHeight) * easeProgress
                
                -- Start with slow spin
                spinAngle = spinAngle + (config.boxAnimation.initialSpinSpeed / 60.0)
                if spinAngle >= 360.0 then spinAngle = spinAngle - 360.0 end
                
                SetEntityCoordsNoOffset(boxEntity, location.coords.x, location.coords.y, currentHeight, false, false, false)
                SetEntityRotation(boxEntity, 0.0, 0.0, spinAngle, 2, true)
            end
            
            -- =====================
            -- PHASE 3: BOX SPINS INSANELY FAST
            -- =====================
            
            local spinStartTime = GetGameTimer()
            local spinDuration = config.boxAnimation.spinDuration
            local currentSpinSpeed = config.boxAnimation.initialSpinSpeed
            local maxSpinSpeed = config.boxAnimation.maxSpinSpeed
            local accelerationTime = config.boxAnimation.spinAccelerationTime
            local boxCurrentHeight = targetHeight
            
            while DoesEntityExist(boxEntity) and GetGameTimer() - spinStartTime < spinDuration do
                Wait(0)
                local elapsed = GetGameTimer() - spinStartTime
                
                -- Accelerate spin speed over time
                local spinProgress = math.min(elapsed / accelerationTime, 1.0)
                currentSpinSpeed = config.boxAnimation.initialSpinSpeed + (maxSpinSpeed - config.boxAnimation.initialSpinSpeed) * spinProgress
                
                -- Apply spin (Y-axis spin)
                spinAngle = spinAngle + (currentSpinSpeed / 60.0)
                if spinAngle >= 360.0 then spinAngle = spinAngle - 360.0 end
                
                -- Slight bobbing while spinning
                local bobOffset = math.sin(elapsed * 0.01) * 0.05
                boxCurrentHeight = targetHeight + bobOffset
                
                SetEntityCoordsNoOffset(boxEntity, location.coords.x, location.coords.y, boxCurrentHeight, false, false, false)
                SetEntityRotation(boxEntity, 0.0, 0.0, spinAngle, 2, true)
                
                -- Draw spinning light effect
                DrawLightWithRange(location.coords.x, location.coords.y, boxCurrentHeight, 255, 100, 50, 5.0, 1.0)
            end
            
            -- =====================
            -- PHASE 4: BOX SHOOTS UP AND DISAPPEARS
            -- =====================
            
            -- Play poof sound
            playSound(location.coords, config.sounds.poof)
            
            -- Wait brief moment
            Wait(200)
            
            -- Box shoots up into sky
            local shootStart = GetGameTimer()
            local shootDuration = config.boxAnimation.shootDuration
            local shootStartHeight = boxCurrentHeight
            local shootTargetHeight = shootStartHeight + config.boxAnimation.shootHeight
            
            while DoesEntityExist(boxEntity) and GetGameTimer() - shootStart < shootDuration do
                Wait(0)
                local elapsed = GetGameTimer() - shootStart
                local progress = elapsed / shootDuration
                
                -- Fast linear interpolation for shooting up
                local currentHeight = shootStartHeight + (shootTargetHeight - shootStartHeight) * progress
                
                -- Keep spinning fast
                spinAngle = spinAngle + (maxSpinSpeed / 60.0)
                if spinAngle >= 360.0 then spinAngle = spinAngle - 360.0 end
                
                SetEntityCoordsNoOffset(boxEntity, location.coords.x, location.coords.y, currentHeight, false, false, false)
                SetEntityRotation(boxEntity, 0.0, 0.0, spinAngle, 2, true)
            end
            
            -- Delete box
            if DoesEntityExist(boxEntity) then
                DeleteEntity(boxEntity)
            end
        end
        
        -- =====================
        -- PHASE 5: REAL LIGHTNING STRIKES
        -- =====================

        Wait(300)

        CreateThread(function()
            local coords = location.coords

            lib.requestNamedPtfxAsset('core', 5000)

            for i = 1, 3 do
                Wait(math.random(150, 300))

                -- ⚡ REAL SKY LIGHTNING
                ForceLightningFlash()

                -- Randomize impact position slightly
                local offsetX = coords.x + math.random(-2, 2)
                local offsetY = coords.y + math.random(-2, 2)

                -- 💥 GROUND IMPACT (sells the strike location)
                UseParticleFxAsset('core')
                StartParticleFxNonLoopedAtCoord(
                    'exp_grd_rpg',
                    offsetX, offsetY, coords.z,
                    0.0, 0.0, 0.0,
                    0.25,
                    false, false, false
                )

                -- ⚡ ELECTRICAL BURST
                StartParticleFxNonLoopedAtCoord(
                    'ent_sht_electrical_box',
                    offsetX, offsetY, coords.z + 1.0,
                    0.0, 0.0, 0.0,
                    1.0,
                    false, false, false
                )

                -- 💡 LOCAL FLASH (so it feels like it hit HERE)
                local flashStart = GetGameTimer()
                while GetGameTimer() - flashStart < 120 do
                    Wait(0)
                    DrawLightWithRange(offsetX, offsetY, coords.z + 1.0, 255, 255, 255, 25.0, 8.0)
                end

                -- 🌫️ SMOKE AFTER STRIKE
                StartParticleFxNonLoopedAtCoord(
                    'exp_grd_grenade_smoke',
                    offsetX, offsetY, coords.z,
                    0.0, 0.0, 0.0,
                    2.5,
                    false, false, false
                )
            end

            -- 🌪️ FINAL BIG STRIKE (center)
            Wait(200)

            ForceLightningFlash()

            UseParticleFxAsset('core')
            StartParticleFxNonLoopedAtCoord(
                'exp_grd_rpg',
                coords.x, coords.y, coords.z,
                0.0, 0.0, 0.0,
                2.0,
                false, false, false
            )

            -- 💡 MASSIVE FINAL FLASH
            local flashStart = GetGameTimer()
            while GetGameTimer() - flashStart < 200 do
                Wait(0)
                DrawLightWithRange(coords.x, coords.y, coords.z + 1.0, 255, 255, 255, 30.0, 10.0)
            end
        end)
        
        -- =====================
        -- PHASE 6: RESPAWN BOX AT NEW LOCATION
        -- =====================
        
        Wait(1500) -- Wait for lightning effect to complete
        
        -- Spawn box at new random location
        local possibleLocations = {}
        for i = 1, #sharedConfig.boxLocations do
            if sharedConfig.boxLocations[i].coords ~= location.coords then
                possibleLocations[#possibleLocations + 1] = sharedConfig.boxLocations[i]
            end
        end
        local random = math.random(1, #possibleLocations)
        spawnMysteryBox(possibleLocations[random], true)
        spawnEmptyBoxes(location)
    end)
end


local function startBoxLightEffect(coords, duration)
    CreateThread(function()
        local startTime = GetGameTimer()

        while GetGameTimer() - startTime < duration do
            Wait(0)
            DrawLightWithRange(coords.x, coords.y, coords.z + 0.5, 255, 180, 80, 7.0, 1.5)
        end
    end)
end

local function startRisingWeaponEffect(location)
    CreateThread(function()
        local startTime = GetGameTimer()
        local currentWeapon
        local weaponList = {}

        local startZ = location.coords.z + 0.20
        local endZ = location.coords.z + 1.5

        -- Calculate total weight for weighted random
        local totalWeight = 0
        for k, v in pairs(weapons) do
            totalWeight = totalWeight + v.chance
        end

        local currentWeaponName = nil
        local nextSwap = GetGameTimer() + math.random(50, 300)

        while GetGameTimer() - startTime < config.weaponAnimation.duration do
            local now = GetGameTimer()
            local elapsed = now - startTime

            local progress_raw = math.min(elapsed / 5000, 1.0)
            local progress = 1 - math.cos(progress_raw * math.pi / 2)  -- Ease out for floating effect
            local currentZ = startZ + (endZ - startZ) * progress

            if elapsed < 7000 and (now >= nextSwap or not DoesEntityExist(currentWeapon)) then  -- Stop switching after 7 seconds
                if currentWeapon then DeleteEntity(currentWeapon) end

                -- Weighted random selection
                local rand = math.random() * totalWeight
                local cumulative = 0
                local selected
                for k, v in pairs(weapons) do
                    cumulative = cumulative + v.chance
                    if rand <= cumulative then
                        selected = {name = k, model = v.model}
                        break
                    end
                end
                local model = selected.model
                currentWeaponName = selected.name
                if not IsModelInCdimage(joaat(model)) then
                    return print('[MysteryBox]: Model not found: ' .. model)
                end
                lib.requestModel(joaat(model), 5000)

                currentWeapon = CreateObjectNoOffset(
                    model,
                    location.coords.x,
                    location.coords.y,
                    currentZ,
                    true,
                    false,
                    false
                )
                SetEntityCollision(currentWeapon, false, false)
                FreezeEntityPosition(currentWeapon, true)
                SetModelAsNoLongerNeeded(model)

                SetEntityHeading(currentWeapon, location.coords.w)

                nextSwap = now + math.random(150, 300)
            end

            -- Update Z position every frame for smooth movement
            if DoesEntityExist(currentWeapon) then
                SetEntityCoordsNoOffset(
                    currentWeapon,
                    location.coords.x,
                    location.coords.y,
                    currentZ,
                    false, false, false
                )
            end

            Wait(0)
        end

        local bearModel = isBearModel(currentWeaponName)

        if bearModel then
            createTeddyBearAnimation(location, currentWeapon)
        else
            Wait(3000)
            if DoesEntityExist(currentWeapon) then DeleteEntity(currentWeapon) end
            if DoesEntityExist(newBoxEntity) then DeleteEntity(newBoxEntity) end
            spawnMysteryBox(location, true)
            TriggerServerEvent("bama_mysterybox:server:usedBox", currentWeaponName)
        end
        isRolling = false
    end)
end
---------------
--- THREADS ---
---------------
CreateThread( function ()
    Wait(1000)
    
    -- Spawn box at new random location
    local random = math.random(1, #sharedConfig.boxLocations)
    local location = sharedConfig.boxLocations[random]
    spawnMysteryBox(location, true)

    for i = 1, #sharedConfig.boxLocations do
        sharedConfig.boxLocations[i].id = i
        if sharedConfig.boxLocations[i] ~= location then
            locations[#locations + 1] = sharedConfig.boxLocations[i]
        end
    end

    spawnEmptyBoxes(locations)
end)

--------------
--- EVENTS ---
--------------
RegisterNetEvent('bama_mysterybox:client:useBox', function (location)
    if isRolling then return end
    isRolling = true

    -- change to the opened box model
    lib.requestModel(joaat(location.openedModel), 5000)

    -- Create new entity
    newBoxEntity = CreateObjectNoOffset(
        location.openedModel,
        location.coords.x,
        location.coords.y,
        location.coords.z + 0.15,
        true,
        false,
        false
    )
    SetEntityRotation(newBoxEntity, 0.0, 0.0, location.coords.w, 2, true)
    FreezeEntityPosition(newBoxEntity, true)
    SetModelAsNoLongerNeeded(location.openedModel)
    -- Fade animation
    local alpha = 0
    local alpha2 = 255
    local number = 255
    while number > 0 do
        Wait(0)
        SetEntityAlpha(boxEntity, alpha2, false)
        SetEntityAlpha(newBoxEntity, alpha, false)

        alpha += 20
        alpha2 -= 20
        number -= 20

        Wait(25)
    end

    -- Delete old entity
    DeleteEntity(boxEntity)
    PlaceObjectOnGroundProperly(newBoxEntity)


    playSound(location.coords, config.sounds.boxOpen)

    if config.weaponAnimation.enabled then startRisingWeaponEffect(location) end
    if config.lightingEffect.enabled then startBoxLightEffect(location.coords, config.lightingEffect.duration) end
end)
----------------------
--- EVENT HANDLERS ---
----------------------
AddEventHandler('onResourceStop', function (resource)
    if GetCurrentResourceName() ~= resource then return end

    if boxEntity then DeleteEntity(boxEntity) end
    if newBoxEntity then DeleteEntity(newBoxEntity) end
    for k, v in pairs(emptyBoxEntity) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
            emptyBoxEntity[k] = nil
        end
    end
end)