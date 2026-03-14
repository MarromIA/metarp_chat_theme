-- ============================================================================
-- METARP CHAT - STAFF COMMANDS (SERVER)
-- ============================================================================
-- Version: 1.0.0
-- Description: /pm and /gh commands restricted to staff via metarp_staffsys
-- Features:
-- - /pm: direct message between staff and any player; shown to both parties
-- - /gh: global announcement sent to all connected players
-- - Access controlled via CheckStaffPermissions (Config.*.Staff ranks)
-- - Discord webhook logging for audit trail
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================================================
-- MARK: COMMAND: PM
-- ============================================================================

lib.addCommand('pm', {
    help   = 'Send a private message to a player [STAFF]',
    params = {
        { name = 'id',      type = 'playerId',   help = 'Target player server ID' },
        { name = 'mensaje', type = 'longString',  help = 'Message content'         }
    }
}, function(source, args)
    if not Config.PM.Enabled then
        Debug.Warn('COMMANDS', '/pm used while disabled', {source = source})
        return
    end

    local allowed, errMsg = CheckStaffPermissions(source, Config.PM.Staff)
    if not allowed then
        Notify(source, errMsg, 'error')
        return
    end

    local targetId   = args.id
    local msg        = args.mensaje
    local srcDisplay = GetDisplayName(source)
    local tgtDisplay = GetDisplayName(targetId)

    -- lib.addCommand with type='playerId' validates the target exists,
    -- but we still guard against nil names defensively
    if not GetPlayerName(source) or not GetPlayerName(targetId) then
        Notify(source, _L('errors.player_not_found'), 'error')
        return
    end

    local header = ('%s → %s'):format(srcDisplay, tgtDisplay)

    Debug.Event('COMMANDS', '/pm sent', {from = srcDisplay, to = tgtDisplay})

    -- Deliver to sender and recipient with identical content
    TriggerClientEvent('chat:addMessage', source, {
        templateId = 'pm',
        multiline  = true,
        args       = {header, msg}
    })

    TriggerClientEvent('chat:addMessage', targetId, {
        templateId = 'pm',
        multiline  = true,
        args       = {header, msg}
    })

    Notify(source,   _L('success.pm_sent',    {name = tgtDisplay}), 'success')
    Notify(targetId, _L('info.pm_received',   {name = srcDisplay}), 'info')

    local wh = Config.Webhook.PM
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = 'Mi2SiS Chat | PM',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'From',  value = srcDisplay, inline = true },
                { name = 'To',    value = tgtDisplay, inline = true },
                { name = 'Steam', value = ids.steam,  inline = true }
            }
        })
    end
end)

-- ============================================================================
-- MARK: COMMAND: GH
-- ============================================================================

-- Sender identity is intentionally not shown in chat.
-- The webhook records which staff member sent the announcement.
lib.addCommand('gh', {
    help   = 'Send a global announcement to all players [STAFF]',
    params = {
        { name = 'mensaje', type = 'longString', help = 'Announcement content' }
    }
}, function(source, args)
    if not Config.GH.Enabled then
        Debug.Warn('COMMANDS', '/gh used while disabled', {source = source})
        return
    end

    local allowed, errMsg = CheckStaffPermissions(source, Config.GH.Staff)
    if not allowed then
        Notify(source, errMsg, 'error')
        return
    end

    local msg          = args.mensaje
    local staffDisplay = GetDisplayName(source)

    Debug.Event('COMMANDS', '/gh sent', {staff = staffDisplay})

    for _, v in pairs(GetPlayers()) do
        TriggerClientEvent('chat:addMessage', v, {
            templateId = 'gh',
            multiline  = true,
            args       = {msg}
        })
    end

    Notify(source, _L('success.announcement_sent'), 'success')

    local wh = Config.Webhook.GH
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = 'Mi2SiS Chat | GH',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'Staff', value = staffDisplay,    inline = true },
                { name = 'Steam', value = ids.steam,       inline = true },
                { name = 'ID',    value = tostring(source), inline = true }
            }
        })
    end
end)