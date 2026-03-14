-- ============================================================================
-- METARP CHAT - SERVER MAIN (SERVER)
-- ============================================================================
-- Version: 1.0.0
-- Description: Server-side entry point, initialization guard, and time sync
-- ============================================================================

-- ============================================================================
-- MARK: INITIALIZATION
-- ============================================================================

local initialized = false

--- Startup guard: ensures initialization runs only once
CreateThread(function()
    if initialized then return end
    initialized = true

    Wait(2000) -- Allow all scripts and frameworks to settle before use

    Debug.Success('SERVER', 'Server initialized')
end)

-- ============================================================================
-- MARK: TIME BROADCAST
-- ============================================================================

--- Broadcast real server time (os.date) to all clients every second.
--- Clients cache this value and use it to respond to app.js NUI time callbacks.
--- os.date is only available server-side in FiveM.
CreateThread(function()
    while true do
        Wait(1000)
        TriggerClientEvent('metarp_chat:client:syncTime', -1, os.date('%H:%M'))
    end
end)