-- ============================================================================
-- METARP CHAT - DEBUG SYSTEM (SHARED)
-- ============================================================================
-- Version: 1.0.0
-- Description: Unified logging framework with automatic client/server detection
-- Features:
--   - Auto client/server detection via IsDuplicityVersion()
--   - FiveM color codes (client) and ANSI escape codes (server)
--   - ASCII icons for client F8, emoji icons for server terminal
--   - Per-type and per-category filtering via Config.Debug
--   - ERROR always shown regardless of master switch
-- ============================================================================

-- ============================================================================
-- MARK: SIDE DETECTION
-- ============================================================================

local isClient = IsDuplicityVersion() == false
local side     = isClient and 'CLIENT' or 'SERVER'

-- ============================================================================
-- MARK: COLOR SYSTEMS
-- ============================================================================

--- FiveM color codes for the F8 client console
local clientColors = {
    red     = '^1',
    green   = '^2',
    yellow  = '^3',
    blue    = '^4',
    cyan    = '^5',
    magenta = '^6',
    white   = '^7',
    gray    = '^8',
    reset   = '^7'
}

--- ANSI escape sequences for the server terminal
local serverColors = {
    red     = '\27[31m',
    green   = '\27[32m',
    yellow  = '\27[33m',
    blue    = '\27[34m',
    magenta = '\27[35m',
    cyan    = '\27[36m',
    white   = '\27[37m',
    gray    = '\27[90m',
    reset   = '\27[0m'
}

local colors = isClient and clientColors or serverColors

-- ============================================================================
-- MARK: LOG TYPE CONFIGURATION
-- ============================================================================

--- Color mapped to each log type
local typeColors = {
    INFO     = colors.magenta,
    WARN     = colors.yellow,
    ERROR    = colors.red,
    SUCCESS  = colors.green,
    EVENT    = colors.blue,
    FUNCTION = colors.white,
    RETURN   = colors.gray
}

--- ASCII icons for the F8 client console (no emoji support)
local clientIcons = {
    INFO     = '[i]',
    WARN     = '[!]',
    ERROR    = '[X]',
    SUCCESS  = '[OK]',
    EVENT    = '[->]',
    FUNCTION = '[F]',
    RETURN   = '[<-]'
}

--- Emoji icons for the server terminal (UTF-8 capable)
local serverIcons = {
    INFO     = 'ℹ️',
    WARN     = '⚠️',
    ERROR    = '❌',
    SUCCESS  = '✅',
    EVENT    = '📡',
    FUNCTION = '🔧',
    RETURN   = '↩️'
}

local icons = isClient and clientIcons or serverIcons

-- ============================================================================
-- MARK: DATA FORMATTING
-- ============================================================================

--- Visual hierarchy prefix for inline data lines
local dataPrefix = isClient and '  |-> Data: ' or '  └─ Data: '

--- Encode data table as JSON string for log output
---@param data table|nil Data to format
---@return string formatted JSON string or empty string if no data
local function FormatData(data)
    if not data or type(data) ~= 'table' then return '' end

    local ok, encoded = pcall(json.encode, data)
    return ok and encoded or tostring(data)
end

-- ============================================================================
-- MARK: FILTER SYSTEM
-- ============================================================================

--- Check whether a log entry should be printed.
--- ERROR always bypasses all filters.
--- Two-axis check: log type must be enabled AND category must be enabled.
---@param logType string  Log type (INFO, WARN, ERROR, etc.)
---@param category string Category key (SERVER, CLIENT, COMMANDS, etc.)
---@return boolean enabled
local function IsDebugEnabled(logType, category)
    -- ERROR is always shown regardless of any setting
    if logType == 'ERROR' then return true end

    if not Config or not Config.Debug then return false end
    if not Config.Debug.Enabled then return false end

    -- Type-axis filter: suppress this type globally if disabled
    if Config.Debug.Types and Config.Debug.Types[logType] ~= nil then
        if not Config.Debug.Types[logType] then return false end
    end

    -- Category-axis filter: suppress this module if disabled
    -- NOTE: category names in code are UPPERCASE; config keys are PascalCase
    local normalizedCategory = category:sub(1,1):upper() .. category:sub(2):lower()
    if Config.Debug.Categories then
        local byCaps    = Config.Debug.Categories[category]
        local byPascal  = Config.Debug.Categories[normalizedCategory]
        local enabled   = byCaps ~= nil and byCaps or byPascal
        if enabled ~= nil then return enabled end
    end

    return true
end

-- ============================================================================
-- MARK: TIMESTAMP
-- ============================================================================

--- Return a formatted timestamp prefix for server logs.
--- Client timestamps are not available (no os.date on client).
---@return string timestamp "[HH:MM:SS] " or empty string
local function GetTimestamp()
    if not Config or not Config.Debug or not Config.Debug.ShowTimestamps then
        return ''
    end
    if not isClient then
        return '[' .. os.date('%H:%M:%S') .. '] '
    end
    return ''
end

-- ============================================================================
-- MARK: CORE LOG FUNCTION
-- ============================================================================

--- Build and print a single log entry.
--- Exits early if the entry is filtered out to avoid string formatting cost.
---@param logType  string     Log type (INFO, WARN, ERROR, etc.)
---@param category string     Module category (COMMANDS, WEBHOOKS, etc.)
---@param message  string     Human-readable description
---@param data     table|nil  Optional structured data to display
local function Log(logType, category, message, data)
    if not IsDebugEnabled(logType, category) then return end

    local color     = typeColors[logType] or colors.white
    local icon      = icons[logType] or '•'
    local timestamp = GetTimestamp()

    local logLine = string.format(
        '%s%s[%s] %s [%s] %s: %s%s',
        timestamp, color,
        side, icon,
        logType, category,
        message, colors.reset
    )

    print(logLine)

    if data then
        local formatted = FormatData(data)
        if formatted ~= '' then
            print(string.format('%s%s%s%s', colors.gray, dataPrefix, formatted, colors.reset))
        end
    end
end

-- ============================================================================
-- MARK: PUBLIC API
-- ============================================================================

Debug = {}

--- Log informational message
---@param category string    Module category
---@param message  string    Message
---@param data     table|nil Optional data
function Debug.Info(category, message, data)    Log('INFO',    category, message, data) end

--- Log warning message
---@param category string    Module category
---@param message  string    Message
---@param data     table|nil Optional data
function Debug.Warn(category, message, data)    Log('WARN',    category, message, data) end

--- Log error message (always shown)
---@param category string    Module category
---@param message  string    Message
---@param data     table|nil Optional data
function Debug.Error(category, message, data)   Log('ERROR',   category, message, data) end

--- Log success message
---@param category string    Module category
---@param message  string    Message
---@param data     table|nil Optional data
function Debug.Success(category, message, data) Log('SUCCESS', category, message, data) end

--- Log network event trigger
---@param category string    Module category
---@param message  string    Message
---@param data     table|nil Optional data
function Debug.Event(category, message, data)   Log('EVENT',   category, message, data) end

--- Log function entry (verbose, dev only)
---@param fnName string    Function name
---@param data   table|nil Optional parameters
function Debug.Function(fnName, data)
    Log('FUNCTION', 'CALL', string.format('→ Call to %s()', fnName), data)
end

--- Log function return (verbose, dev only)
---@param fnName string  Function name
---@param result any     Return value (truthy = success)
---@param data   table|nil Optional return data
function Debug.Return(fnName, result, data)
    local symbol = result and '✓' or '✗'
    Log('RETURN', 'RESULT', string.format('← %s %s() returned', symbol, fnName), data)
end

-- ============================================================================
-- MARK: INIT CONFIRMATION
-- ============================================================================

--- Confirm debug system is ready after Config loads
CreateThread(function()
    Wait(100)
    Debug.Success('DEBUG', 'Debug system initialized', {
        side       = side,
        enabled    = Config and Config.Debug and Config.Debug.Enabled or false,
        colorSystem = isClient and 'FiveM' or 'ANSI',
        iconSystem  = isClient and 'ASCII' or 'Emoji'
    })
end)