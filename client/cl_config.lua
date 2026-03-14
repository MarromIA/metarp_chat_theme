-- ============================================================================
-- METARP CHAT - NUI CONFIG CALLBACK (CLIENT)
-- ============================================================================
-- Version: 1.0.0
-- Description: Serves theme configuration to app.js via NUI callback
-- Features:
--   - Base chat colors and fonts
--   - Sidebar tag colors per command type
--   - Server time cache for the clock widget (os.date is server-only in FiveM)
-- ============================================================================

-- ============================================================================
-- MARK: STATE VARIABLES
-- ============================================================================

-- NOTE: os.date is not available on the FiveM client.
-- We receive real server time via metarp_chat:client:syncTime and cache it here.
local cachedTime = '--:--'

-- ============================================================================
-- MARK: EVENT: TIME SYNC
-- ============================================================================

--- Cache the server time broadcast from sv_main.lua (fires every second)
RegisterNetEvent('metarp_chat:client:syncTime')
AddEventHandler('metarp_chat:client:syncTime', function(time)
    cachedTime = time
end)

-- ============================================================================
-- MARK: CALLBACK: CONFIG
-- ============================================================================

--- Respond to app.js fetchNui('config') with the full theme configuration.
--- Edit values directly here — changes take effect on next resource restart.
RegisterNUICallback('config', function(_data, cb)
    Debug.Info('NUI', 'config callback triggered')
    cb({
        -- ===== Base Colors =====
        mainColor   = '#291C19', -- Chat bubble background
        borderColor = '#373a40', -- Chat bubble border
        textColor   = '#ffffff', -- Primary text color
        faintColor  = '#c1c2c5', -- Secondary/metadata text

        -- ===== Fonts =====
        fontFamily           = "'Segoe UI', Arial, Helvetica, sans-serif",
        consoleFontFamily    = 'monospace',
        suggestionFontFamily = 'monospace',

        -- ===== Icons =====
        inputIconUrl   = 'https://cfx-nui-metarp_chat/theme/icons/duck.png',
        messageIconUrl = 'https://cfx-nui-metarp_chat/theme/icons/message.svg',
        consoleIconUrl = 'https://cfx-nui-metarp_chat/theme/icons/console.svg',
        joinIconUrl    = 'https://cfx-nui-metarp_chat/theme/icons/join.svg',
        quitIconUrl    = 'https://cfx-nui-metarp_chat/theme/icons/quit.svg',
        userIconUrl    = 'https://cfx-nui-metarp_chat/theme/icons/user.svg',

        -- ===== Sidebar Tag Colors (hex) =====
        tagTwt      = '#41b6ff', -- /twt
        tagAnon     = '#9fa2a5', -- /anon
        tagDo       = '#2067f4', -- /do
        tagMe       = '#ff6b6b', -- /me
        tagOoc      = '#252525', -- /ooc
        tagPm       = '#cc5de8', -- /pm
        tagGh       = '#ffdf6b', -- /gh (staff announcement)
        tagFallback = '#495057', -- default/console messages
        tagPrint    = '#868e96', -- print messages
    })
end)

-- ============================================================================
-- MARK: CALLBACK: TIME
-- ============================================================================

--- Respond to app.js fetchNui('time') with the cached server time.
--- Called every second by the clock widget in app.js.
--- Returns '--:--' until the first sync packet arrives from the server.
RegisterNUICallback('time', function(_data, cb)
    cb({ time = cachedTime })
end)