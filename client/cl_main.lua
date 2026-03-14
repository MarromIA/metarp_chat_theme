-- ============================================================================
-- METARP CHAT - CLIENT MAIN (CLIENT)
-- ============================================================================
-- Version: 1.0.0
-- Description: Client-side entry point, initialization guard, and /clear command
-- ============================================================================

-- ============================================================================
-- MARK: INITIALIZATION
-- ============================================================================

local initialized = false

--- Wait for the player to be logged in before marking the client as ready
CreateThread(function()
    if initialized then return end
    initialized = true

    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end

    Debug.Success('CLIENT', 'Client initialized')
end)

-- ============================================================================
-- MARK: COMMAND: CLEAR
-- ============================================================================

--- Clear all messages from the chat window
RegisterCommand('clear', function()
    TriggerEvent('chat:clear')
end, false)