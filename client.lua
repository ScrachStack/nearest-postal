local postals = {}

-- Load the postals from JSON
Citizen.CreateThread(function()
    local data = LoadResourceFile(GetCurrentResourceName(), "ocrp.json")
    postals = json.decode(data)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
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
