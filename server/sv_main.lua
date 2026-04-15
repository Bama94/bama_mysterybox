local config = require 'config.server'
local sharedConfig = require 'config.shared'

-----------------
--- FUNCTIONS ---
-----------------
local function getClosestBox(pedCoords)
    local boxCoords = vec3(sharedConfig.boxLocations[1].coords.x, sharedConfig.boxLocations[1].coords.y, sharedConfig.boxLocations[1].coords.z)
    print(boxCoords, pedCoords)
    print(#(pedCoords - boxCoords))
    local distance = #(pedCoords - boxCoords)
    local closest = 1
    for i = 1, #sharedConfig.boxLocations do
        local boxCoords = vec3(sharedConfig.boxLocations[i].coords.x, sharedConfig.boxLocations[i].coords.y, sharedConfig.boxLocations[i].coords.z)
        local dist = #(pedCoords - boxCoords)
        if dist < distance then
            distance = dist
            closest = i
        end
    end
    return closest
end

local function distanceCheck(source)
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local closestBox = getClosestBox(playerCoords)
    local boxCoords = vec3(sharedConfig.boxLocations[closestBox].coords.x, sharedConfig.boxLocations[closestBox].coords.y, sharedConfig.boxLocations[closestBox].coords.z)
    if #(playerCoords - boxCoords) >= 20.0 then return false end
    return true
end
--------------
--- EVENTS ---
--------------
RegisterNetEvent('bama_mysterybox:server:useBox', function (boxLocation)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if not player then return end
    if not distanceCheck(src) then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mystery Box',
            description = 'You are too far away from the box!',
            type = 'error'
        })
    end

    if not player.Functions.RemoveMoney(sharedConfig.account, sharedConfig.price) then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mystery Box',
            description = 'You do not have enough money!',
            type = 'error'
        })
    end

    TriggerClientEvent('bama_mysterybox:client:useBox', -1, boxLocation)
end)

RegisterNetEvent('bama_mysterybox:server:usedBox', function (weapon)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if not player then return end
    if not distanceCheck(src) then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mystery Box',
            description = 'You are too far away from the box!',
            type = 'error'
        })
    end

    if exports.ox_inventory:CanCarryItem(src, weapon, 1) then
        return exports.ox_inventory:AddItem(src, weapon, 1)
    else
        player.Functions.AddMoney(sharedConfig.account, sharedConfig.price)
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mystery Box',
            description = 'You cannot carry the weapon!',
            type = 'error'
        })
    end
end)

-- Relocate Box Admin Command
lib.addCommand('relocation_box', {
    help = "Relocate the Mystery Box",
    params = {},
    retricted = 'group.admin',
}, function (source, args, raw)
    TriggerClientEvent('bama_mysterybox:client:relocatebox', -1)
end)