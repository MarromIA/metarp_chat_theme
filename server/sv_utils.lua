-- ============================================================================
-- METARP CHAT - SERVER UTILITIES (SHARED)
-- ============================================================================
-- Version: 1.0.0
-- Description: Framework-agnostic helpers shared across all server scripts
-- Features:
-- - QBX / QBCore auto-detection with unified GetPlayer wrapper
-- - Money removal and balance read helpers
-- - Player identifier extraction (steam, license, discord)
-- - Phone and death state checks
-- - StaffSys permission check
-- - Discord webhook dispatcher
-- - Chat message hook: routes regular chat through 'user' template
-- - Chat message hook: cancels direct chat messages that are not commands
-- ============================================================================

-- ============================================================================
-- MARK: FRAMEWORK DETECTION
-- ============================================================================

local QBX, QBCore = nil, nil

--- Route regular player chat through the 'user' template for consistent styling
exports.chat:registerMessageHook(function(source, _outMessage, hookRef)
    hookRef.updateMessage({ templateId = 'user' })
end)

--- Detect active framework after server startup (1s delay for resource order)
CreateThread(function()
    Wait(1000)
    if GetResourceState('qbx_core') == 'started' then
        local ok = pcall(function()
            QBX = exports.qbx_core
            return QBX ~= nil
        end)
        Debug.Info('SERVER', 'Framework detected', {framework = ok and 'QBX' or 'QBCore'})
    end
end)

-- ============================================================================
-- MARK: PLAYER HELPERS
-- ============================================================================

--- Get the framework player object for a given server source.
--- Supports QBX and QBCore; returns nil if neither is available.
---@param source number Player server ID
---@return table|nil player Framework player object
function GetPlayer(source)
    if QBX   then return QBX:GetPlayer(source) end
    if QBCore then return QBCore.Functions.GetPlayer(source) end
    return nil
end

--- Remove money from a player's account via the active framework.
---@param source number Player server ID
---@param account string Account name ('bank', 'cash', etc.)
---@param amount number Amount to remove
---@param reason string Reason string logged by the framework
---@return boolean success
function RemovePlayerMoney(source, account, amount, reason)
    local player = GetPlayer(source)
    if not player then
        Debug.Error('SERVER', 'RemovePlayerMoney: player not found', {source = source})
        return false
    end
    return player.Functions.RemoveMoney(account, amount, reason)
end

--- Read the current balance of a player's account.
---@param player table Framework player object
---@param account string Account name ('bank', 'cash', etc.)
---@return number balance Account balance or 0 if unavailable
function GetPlayerCash(player, account)
    if not player or not player.PlayerData then return 0 end
    local money = player.PlayerData.money
    return (type(money) == 'table' and money[account]) or 0
end

_G.GetPlayer         = GetPlayer
_G.RemovePlayerMoney = RemovePlayerMoney
_G.GetPlayerCash     = GetPlayerCash

-- ============================================================================
-- MARK: PLAYER IDENTIFIERS
-- ============================================================================

-- Save native reference before redefining to avoid stack overflow
local _GetPlayerIdentifiers = GetPlayerIdentifiers

--- Return a structured table of common player identifiers.
--- Redefines the native to add steam/license/discord extraction.
---@param source number Player server ID
---@return table ids { steam, license, discord } with 'N/A' as fallback
function GetPlayerIdentifiers(source)
    local ids = { steam = 'N/A', license = 'N/A', discord = 'N/A' }

    for _, id in ipairs(_GetPlayerIdentifiers(source)) do
        if     id:find('steam:')   then ids.steam   = id
        elseif id:find('license:') then ids.license = id
        elseif id:find('discord:') then ids.discord = id:gsub('discord:', '')
        end
    end

    return ids
end

-- ============================================================================
-- MARK: STATE CHECKS
-- ============================================================================

--- Check if the player is currently dead or in last-stand.
--- First reads framework metadata; falls back to a client callback.
---@param source number Player server ID
---@return boolean isDead
function IsPlayerDead(source)
    local player = GetPlayer(source)

    if player and player.PlayerData and player.PlayerData.metadata then
        local md = player.PlayerData.metadata
        if md.isdead or md.is_dead or md.inlaststand or md.inLastStand then
            return true
        end
    end

    -- Fallback: ask the client directly (1 second timeout)
    local ok, result = pcall(function()
        return lib.callback.await('metarp_chat:client:isDead', source, 1000)
    end)

    return (ok and result) or false
end

--- Check if the player has the required phone item in their ox_inventory.
---@param source number Player server ID
---@return boolean hasPhone
function HasPhone(source)
    if GetResourceState('ox_inventory') ~= 'started' then
        Debug.Warn('SERVER', 'ox_inventory not started; phone check skipped', {source = source})
        return false
    end

    local ok, hasItem = pcall(function()
        return exports.ox_inventory:GetItem(source, Config.PhoneItem, nil, true) > 0
    end)

    return ok and hasItem or false
end

-- ============================================================================
-- MARK: PERMISSIONS
-- ============================================================================

--- Validate staff access using metarp_staffsys in three sequential steps:
--- 1. Is the player registered as staff?
--- 2. Does their rank appear in the allowedRanks table?
--- 3. Are they currently on duty?
---@param source number Player server ID
---@param allowedRanks table Array of allowed rank strings
---@return boolean allowed
---@return string|nil errorMsg Reason for denial, or nil if allowed
function CheckStaffPermissions(source, allowedRanks)
    local isStaff = exports.metarp_staffsys:IsStaff(source)
    if not isStaff then
        return false, 'No perteneces al equipo de staff.'
    end

    local rank = exports.metarp_staffsys:GetStaffRank(source)
    local hasRank = false
    if rank then
        for _, allowed in ipairs(allowedRanks) do
            if rank == allowed then
                hasRank = true
                break
            end
        end
    end

    if not hasRank then
        return false, ('Tu rango (%s) no tiene permisos para este comando.'):format(rank or 'ninguno')
    end

    local onDuty = exports.metarp_staffsys:IsStaffOnDuty(source)
    if not onDuty then
        return false, 'Debes estar en servicio (On-Duty) para usar este comando.'
    end

    return true, nil
end

_G.CheckStaffPermissions = CheckStaffPermissions

-- ============================================================================
-- MARK: NOTIFICATIONS
-- ============================================================================

--- Send an ox_lib notification to a player.
---@param source number Player server ID
---@param message string Notification description text
---@param notifType string Notification type ('info', 'success', 'error', 'warning')
function Notify(source, message, notifType)
    TriggerClientEvent('ox_lib:notify', source, {
        description = message,
        type        = notifType or 'info'
    })
end

-- ============================================================================
-- MARK: DISPLAY NAME
-- ============================================================================

--- Return a display string combining FiveM player name and server ID.
--- Format: "PlayerName | ID"
---@param source number Player server ID
---@return string displayName
function GetDisplayName(source)
    local name = GetPlayerName(source) or 'Unknown'
    return ('%s | %s'):format(name, source)
end

-- ============================================================================
-- MARK: CHAT MESSAGE HOOK
-- ============================================================================

--- Block direct chat messages that are not slash commands.
--- Prevents players from bypassing command-only chat by typing normally.
exports.chat:registerMessageHook(function(source, outMessage, hookRef)
    if not source or source == 0 then return end

    local msg = outMessage and outMessage.args and outMessage.args[2]
    if type(msg) ~= 'string' then return end

    -- Cancel the message unless it begins with '/'
    if msg:sub(1, 1) ~= '/' then
        hookRef.cancel()
    end
end)

-- ============================================================================
-- MARK: EXPORTS
-- ============================================================================

exports('GetPlayerIdentifiers',  GetPlayerIdentifiers)
exports('IsPlayerDead',          IsPlayerDead)
exports('HasPhone',               HasPhone)
exports('CheckStaffPermissions', CheckStaffPermissions)
exports('Notify',                 Notify)
exports('GetDisplayName',         GetDisplayName)