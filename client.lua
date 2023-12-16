config = {
    -- enables version checking (if this is enabled and there is no new version it won't display a message anyways)
    versionCheck = true,

    text = {
        -- The text to display on-screen for the nearest postal. 
        -- Formatted using Lua strings, http://www.lua.org/pil/20.html
        format = '~y~Nearest Postal~w~: %s (~g~%.2fm~w~)',

        -- ScriptHook PLD Position
        --posX = 0.225,
        --posY = 0.963,

        -- vMenu PLD Position
        posX = 0.22,
        posY = 0.963
    },

    blip = {
        -- The text to display in chat when setting a new route. 
        -- Formatted using Lua strings, http://www.lua.org/pil/20.html
        blipText = 'Postal Route %s',

        -- The sprite ID to display, the list is available here:
        -- https://docs.fivem.net/docs/game-references/blips/#blips
        sprite = 8,

        -- The color ID to use (default is 3, light blue)
        -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
        color = 3,

        -- When the player is this close (in meters) to the destination, 
        -- the blip will be removed.
        distToDelete = 100.0,

        -- The text to display in chat when a route is deleted
        deleteText = 'Route deleted',

        -- The text to display in chat when drawing a new route
        drawRouteText = 'Drawing a route to %s',

        -- The text to display when a postal is not found.
        notExistText = "That postal doesn't exist"
    },

    -- How often in milliseconds the postal code is updated on each client.
    -- I wouldn't recommend anything lower than 50ms for performance reasons
    updateDelay = nil,
}
local postals = {}

-- Load the postals from JSON
CreateThread(function()
    local data = LoadResourceFile(GetCurrentResourceName(), "ocrp.json")
    postals = json.decode(data)
end)

CreateThread(function()
    while true do
        Wait(1000)
        
        if not IsPauseMenuActive() then
            local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), false))
            local heading = GetEntityHeading(PlayerPedId())
            
            local direction = GetCardinalDirectionFromHeading(heading)
            
            local nearestPostal = GetNearestPostal(x, y)
            
            local streetHash = GetStreetNameAtCoord(x, y, z)
            local streetName = GetStreetNameFromHashKey(streetHash)

            SendNUIMessage({
                type = "updatePostal",
                postal = nearestPostal,
                street = streetName,
                direction = direction
            })
        end
    end
end)


function GetCardinalDirectionFromHeading(heading)
    if heading >= 337.5 or heading < 22.5 then
        return "N"
    elseif heading >= 22.5 and heading < 67.5 then
        return "NE"
    elseif heading >= 67.5 and heading < 112.5 then
        return "E"
    elseif heading >= 112.5 and heading < 157.5 then
        return "SE"
    elseif heading >= 157.5 and heading < 202.5 then
        return "S"
    elseif heading >= 202.5 and heading < 247.5 then
        return "SW"
    elseif heading >= 247.5 and heading < 292.5 then
        return "W"
    elseif heading >= 292.5 and heading < 337.5 then
        return "NW"
    end
end


function GetNearestPostal(px, py)
    local nearestPostal = nil
    local nearestDistance = math.huge

    for _, postal in pairs(postals) do
        local distance = CalculateDistance(px, py, postal.x, postal.y)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestPostal = postal.code
        end
    end

    return nearestPostal
end

function CalculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
-- credits to dev blocky for the command
local ipairs = ipairs
local upper = string.upper
local format = string.format
-- end optimizations

---
--- [[ Nearest Postal Commands ]] ---
---

TriggerEvent('chat:addSuggestion', '/postal', 'Set the GPS to a specific postal',
             { { name = 'Postal Code', help = 'The postal code you would like to go to' } })

RegisterCommand('postal', function(_, args)
    if #args < 1 then
        if pBlip then
            RemoveBlip(pBlip.hndl)
            pBlip = nil
            TriggerEvent('chat:addMessage', {
                color = { 255, 0, 0 },
                args = {
                    'Postals',
                    config.blip.deleteText
                }
            })
        end
        return
    end

    local userPostal = upper(args[1])
    local foundPostal

    for _, p in ipairs(postals) do
        if upper(p.code) == userPostal then
            foundPostal = p
            break
        end
    end

    if foundPostal then
        if pBlip then RemoveBlip(pBlip.hndl) end
        local blip = AddBlipForCoord(foundPostal[1][1], foundPostal[1][2], 0.0)
        pBlip = { hndl = blip, p = foundPostal }
        SetBlipRoute(blip, true)
        SetBlipSprite(blip, config.blip.sprite)
        SetBlipColour(blip, config.blip.color)
        SetBlipRouteColour(blip, config.blip.color)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(format(config.blip.blipText, pBlip.p.code))
        EndTextCommandSetBlipName(blip)

        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = {
                'Postals',
                format(config.blip.drawRouteText, foundPostal.code)
            }
        })
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = {
                'Postals',
                config.blip.notExistText
            }
        })
    end
end)
