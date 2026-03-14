-- ============================================================================
-- METARP CHAT - SHARED CONFIGURATION
-- ============================================================================
-- Version: 1.0.0
-- Description: Central configuration for all chat commands and 3D text display
-- Features:
-- - Per-command enable/disable and cooldown settings
-- - 3D overhead text with distance-based scale and fade
-- - Proximity radius per command type
-- - Debug system and locale language settings
-- ============================================================================

Config = {}

-- ============================================================================
-- MARK: LANGUAGE
-- ============================================================================

Config.Language = 'es' -- Language code for locale system ('en', 'es', ...)

-- ============================================================================
-- MARK: ROLEPLAY COMMANDS
-- ============================================================================

Config.Do = {
    Enabled = true,
    Color   = {100, 100, 255}, -- 3D text color (RGB)
    Delay   = 0                -- Cooldown in seconds between uses
}

Config.Me = {
    Enabled = true,
    Color   = {255, 100, 100},
    Delay   = 0
}

Config.OOC = {
    Enabled  = true,
    Color    = {200, 200, 200},
    Delay    = 5,
    AceGroup = 'owner' -- Ace permission group that receives OOC globally
}

-- ============================================================================
-- MARK: GLOBAL COMMANDS
-- ============================================================================

Config.Twitter = {
    Enabled = true,
    Item    = 'phone', -- Required inventory item
    Color   = {0, 172, 237},
    Delay   = 30
}

Config.Anon = {
    Enabled = true,
    Item    = 'phone',
    Cost    = 500, -- Bank cost per anonymous message
    Color   = {128, 128, 128},
    Delay   = 60
}

-- ============================================================================
-- MARK: STAFF COMMANDS
-- ============================================================================

Config.PM = {
    Enabled = true,
    Color   = {255, 255, 0},
    Delay   = 0,
    Staff   = {'support', 'mod', 'admin', 'manager', 'pmanagment', 'owner'}
}

Config.GH = {
    Enabled = true,
    Color   = {255, 0, 0},
    Delay   = 0,
    Staff   = {'support', 'mod', 'admin', 'manager', 'pmanagment', 'owner'}
}

-- ============================================================================
-- MARK: 3D OVERHEAD TEXT
-- ============================================================================

Config.TextDuration    = 7500         -- Milliseconds a 3D message stays visible
Config.TextScale       = 0.40         -- Base text scale
Config.TextOffset      = 0.35         -- Vertical offset above head bone (meters)
Config.LineSpacing     = 0.15         -- Spacing between stacked lines (meters)
Config.MaxMessages     = 5            -- Maximum stacked messages per player
Config.Outline         = true         -- Enable text outline for readability
Config.OutlineColor    = {0, 0, 0, 255} -- Outline color (RGBA)

-- ============================================================================
-- MARK: 3D TEXT DISTANCE SCALING
-- ============================================================================

Config.TextScaleNear   = 0.55  -- Scale at close range
Config.TextScaleFar    = 0.15  -- Scale at far range
Config.ScaleDistNear   = 2.0   -- Distance where near scale applies (meters)
Config.ScaleDistFar    = 10.0  -- Distance where far scale applies (meters)
Config.DrawMaxDistance = 25.0  -- Beyond this, 3D text is not drawn
Config.FadeWithDistance = true -- Fade alpha as player approaches max distance

-- ============================================================================
-- MARK: PROXIMITY RADII
-- ============================================================================

-- Maximum distance (meters) at which each command message is received
Config.Proximity = {
    Do  = 25.0,
    Me  = 25.0,
    OOC = 25.0
}

-- ============================================================================
-- MARK: INVENTORY
-- ============================================================================

Config.PhoneItem = 'phone' -- Inventory item required for phone-dependent commands

-- ============================================================================
-- MARK: DEBUG
-- ============================================================================

Config.Debug = {
    Enabled        = false, -- Master switch; false = only ERRORs are shown
    ShowTimestamps = false, -- Prepend [HH:MM:SS] to server-side log lines

    --- Log type filters — set any to false to suppress that type globally
    Types = {
        INFO     = true,
        WARN     = true,
        ERROR    = true,    -- Always shown (overridden in IsDebugEnabled)
        SUCCESS  = true,
        EVENT    = true,
        FUNCTION = true,    -- Verbose function entry tracing (dev only)
        RETURN   = true     -- Verbose function return tracing (dev only)
    },

    --- Per-module category filters — set any to false to silence that module
    Categories = {
        Server   = true, -- sv_utils / sv_main
        Client   = true, -- cl_main / cl_config
        Commands = true, -- sv_proximity / sv_global / sv_staff
        Webhooks = true, -- sv_webhooks
        Dom3D    = true, -- cl_dome 3D text rendering
        NUI      = true, -- cl_config NUI callbacks
        Locales  = true  -- sh_locales loading and key lookups
    }
}