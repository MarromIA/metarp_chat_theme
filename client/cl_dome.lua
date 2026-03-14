-- ============================================================================
-- METARP CHAT - 3D OVERHEAD TEXT (CLIENT)
-- ============================================================================
-- Version: 1.0.0
-- Description: Renders proximity chat messages as 3D text above player heads
-- Features:
--   - Distance-based scale interpolation (near/far thresholds)
--   - Alpha fade as player approaches max draw distance
--   - Stacked message support with configurable max per player
--   - Automatic message expiry by duration
--   - Periodic cleanup of disconnected player entries
-- ============================================================================

-- ============================================================================
-- MARK: STATE VARIABLES
-- ============================================================================

--- Active 3D text messages indexed by server player ID
local playerMessages = {}

-- ============================================================================
-- MARK: EVENT: SHOW 3D TEXT
-- ============================================================================

--- Receive a 3D text message from the server and store it for rendering.
--- Messages expire after Config.TextDuration milliseconds.
RegisterNetEvent('metarp_chat:client:show3dText')
AddEventHandler('metarp_chat:client:show3dText', function(playerId, message, color)
    if not playerMessages[playerId] then
        playerMessages[playerId] = {}
    end

    table.insert(playerMessages[playerId], {
        text     = message,
        color    = color,
        time     = GetGameTimer(),
        duration = Config.TextDuration
    })

    -- Enforce max stacked messages per player (remove oldest first)
    while #playerMessages[playerId] > Config.MaxMessages do
        table.remove(playerMessages[playerId], 1)
    end

    Debug.Event('DOM3D', '3D text received', {
        playerId = playerId,
        stacked  = #playerMessages[playerId]
    })
end)

-- ============================================================================
-- MARK: HELPER: DRAW 3D TEXT
-- ============================================================================

--- Draw a single text string at world coordinates with distance-based scaling.
--- Skips draw if the target is beyond Config.DrawMaxDistance.
---@param x     number World X coordinate
---@param y     number World Y coordinate
---@param z     number World Z coordinate
---@param text  string Text to render
---@param scale number Base scale (overridden by distance logic)
---@param r     number Red channel (0-255)
---@param g     number Green channel (0-255)
---@param b     number Blue channel (0-255)
---@param a     number Alpha channel (0-255)
local function DrawText3DWithOutline(x, y, z, text, scale, r, g, b, a)
    local camCoords = GetFinalRenderedCamCoord()
    local distance  = #(camCoords - vector3(x, y, z))

    if distance > Config.DrawMaxDistance then return end

    -- Interpolate scale between near and far thresholds
    local finalScale
    if distance <= Config.ScaleDistNear then
        finalScale = Config.TextScaleNear
    elseif distance >= Config.ScaleDistFar then
        finalScale = Config.TextScaleFar
    else
        local range = Config.ScaleDistFar - Config.ScaleDistNear
        local ratio = (distance - Config.ScaleDistNear) / range
        finalScale  = Config.TextScaleNear - (ratio * (Config.TextScaleNear - Config.TextScaleFar))
    end

    -- Fade alpha as the player approaches the draw distance limit
    local finalAlpha = a
    if Config.FadeWithDistance then
        local fadeStart = Config.DrawMaxDistance * 0.7
        if distance > fadeStart then
            local fadeRatio = (distance - fadeStart) / (Config.DrawMaxDistance - fadeStart)
            finalAlpha = math.floor(a * (1.0 - fadeRatio))
        end
    end

    SetTextScale(finalScale, finalScale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextEntry('STRING')
    SetTextCentre(true)
    SetTextColour(r, g, b, finalAlpha)
    if Config.Outline then SetTextOutline() end
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- ============================================================================
-- MARK: THREAD: RENDER LOOP
-- ============================================================================

--- Per-frame render loop: iterates all active messages and draws them.
--- Uses probabilistic debug logging (1%) to avoid console flooding.
CreateThread(function()
    while true do
        Wait(0)

        local currentTime = GetGameTimer()
        local myPed       = PlayerPedId()
        local myCoords    = GetEntityCoords(myPed)

        for playerId, messages in pairs(playerMessages) do
            local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))

            if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance     = #(myCoords - targetCoords)

                if distance <= Config.DrawMaxDistance then
                    local headCoords = GetPedBoneCoords(targetPed, 0x796e, 0.0, 0.0, 0.0)
                    local baseZ      = headCoords.z + Config.TextOffset

                    -- Expire messages that have exceeded their display duration
                    for i = #messages, 1, -1 do
                        if currentTime - messages[i].time > messages[i].duration then
                            table.remove(messages, i)
                        end
                    end

                    for i, msg in ipairs(messages) do
                        local zOffset = baseZ + ((i - 1) * Config.LineSpacing)

                        DrawText3DWithOutline(
                            headCoords.x, headCoords.y, zOffset,
                            msg.text,
                            Config.TextScale,
                            msg.color[1], msg.color[2], msg.color[3],
                            255
                        )
                    end

                    -- NOTE: 1% probabilistic logging to avoid flooding in hot loop
                    if math.random(1, 100) <= 1 then
                        Debug.Info('DOM3D', 'Rendering messages', {
                            playerId = playerId,
                            count    = #messages,
                            distance = math.floor(distance)
                        })
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- MARK: THREAD: CLEANUP
-- ============================================================================

--- Every 5 seconds, remove entries for players who have disconnected.
CreateThread(function()
    while true do
        Wait(5000)

        for playerId in pairs(playerMessages) do
            local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))

            if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
                playerMessages[playerId] = nil
                Debug.Info('DOM3D', 'Cleaned up messages for disconnected player', {
                    playerId = playerId
                })
            end
        end
    end
end)