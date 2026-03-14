-- ============================================================================
-- METARP CHAT - LOCALES SYSTEM (SHARED)
-- ============================================================================
-- Version: 1.0.0
-- Description: Multi-language support with hierarchical dot-notation access
-- Features:
--   - Dot-notation key access (e.g. 'errors.no_phone')
--   - Variable interpolation with {placeholder} syntax
--   - Fallback chain: configured language → English → hardcoded
--   - Graceful degradation: returns key string if translation missing
--   - Global _L() alias for concise usage
-- ============================================================================

-- ============================================================================
-- MARK: STATE VARIABLES
-- ============================================================================

Locale = {}

local currentLanguage  = 'es'  -- Active language code
local fallbackLanguage = 'en'  -- Fallback if primary load fails
local translations     = {}    -- Loaded translation data (populated on init)

-- ============================================================================
-- MARK: INTERNAL HELPERS
-- ============================================================================

--- Traverse a nested table using a dot-separated key string.
---@param tbl table  Root table to traverse
---@param key string Dot-notation key (e.g. 'errors.no_phone')
---@return any|nil value Resolved value or nil if path not found
local function GetNestedValue(tbl, key)
    local current = tbl
    for segment in string.gmatch(key, '([^.]+)') do
        if type(current) ~= 'table' then return nil end
        current = current[segment]
        if current == nil then return nil end
    end
    return current
end

--- Replace {placeholder} tokens in a string with values from a table.
---@param str  string     Template string with {key} placeholders
---@param vars table|nil  Map of placeholder names to replacement values
---@return string result  String with all matched placeholders replaced
local function ReplaceVariables(str, vars)
    if not vars or type(vars) ~= 'table' then return str end
    for key, value in pairs(vars) do
        str = string.gsub(str, '{' .. key .. '}', tostring(value))
    end
    return str
end

-- ============================================================================
-- MARK: PUBLIC API
-- ============================================================================

--- Load translations for the given language code.
--- Reads from locales/<lang>.json inside this resource.
---@param lang string Language code (e.g. 'en', 'es')
---@return boolean success True if file was found and parsed successfully
function Locale.Load(lang)
    local path = 'locales/' .. lang .. '.json'
    local raw  = LoadResourceFile(GetCurrentResourceName(), path)

    if not raw then
        Debug.Error('LOCALES', 'Language file not found', {path = path, lang = lang})
        return false
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        Debug.Error('LOCALES', 'Failed to parse language file', {path = path})
        return false
    end

    translations    = decoded
    currentLanguage = lang
    Debug.Success('LOCALES', 'Language loaded', {lang = lang})
    return true
end

--- Get a translated string by dot-notation key with optional variable substitution.
--- Returns the key itself if the translation is missing (graceful degradation).
---@param key  string     Dot-notation translation key (e.g. 'errors.no_phone')
---@param vars table|nil  Variable substitution map ({placeholder = value})
---@return string translation Translated string or key if not found
function Locale.Get(key, vars)
    local value = GetNestedValue(translations, key)

    if value == nil then
        Debug.Warn('LOCALES', 'Missing translation key', {key = key})
        return key
    end

    if type(value) ~= 'string' then
        return key
    end

    return ReplaceVariables(value, vars)
end

--- Check if a translation key exists in the current language.
---@param key string Dot-notation key to check
---@return boolean exists
function Locale.Has(key)
    return GetNestedValue(translations, key) ~= nil
end

--- Get the currently active language code.
---@return string lang Current language code
function Locale.GetCurrent()
    return currentLanguage
end

-- Global shorthand alias
_L = Locale.Get

-- ============================================================================
-- MARK: INITIALIZATION
-- ============================================================================

--- Load the language configured in Config.Language.
--- Falls back to English, then to hardcoded emergency strings if all else fails.
CreateThread(function()
    Wait(100) -- Wait for Config to be available

    local configLang = (Config and Config.Language) or fallbackLanguage

    if not Locale.Load(configLang) then
        -- Primary failed: attempt English fallback
        if configLang ~= fallbackLanguage then
            Debug.Warn('LOCALES', 'Falling back to English', {attempted = configLang})
            if not Locale.Load(fallbackLanguage) then
                -- Both failed: use hardcoded emergency defaults
                Debug.Error('LOCALES', 'All language files failed — using hardcoded defaults')
                translations = {
                    errors  = { no_phone = 'No phone', player_not_found = 'Player not found',
                                insufficient_funds = 'Insufficient funds', cooldown_active = 'Cooldown: {remaining}s',
                                payment_failed = 'Payment error', system_disabled = 'Disabled' },
                    success = { tweet_sent = 'Tweet sent', anon_sent = 'Anonymous sent (-${cost})',
                                pm_sent = 'PM sent to {name}', announcement_sent = 'Announcement sent' },
                    info    = { pm_received = 'PM from {name}' }
                }
            end
        end
    end
end)