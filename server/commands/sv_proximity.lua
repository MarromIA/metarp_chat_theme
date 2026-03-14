-- ============================================================================
-- METARP CHAT - PROXIMITY COMMANDS (SERVER)
-- ============================================================================
-- Version: 1.0.0
-- Description: /do, /me, and /ooc commands with proximity-based delivery
-- Features:
--   - Message delivered only to players within Config.Proximity radius
--   - 3D overhead text triggered on receiving clients
--   - OOC global broadcast for staff (Config.OOC.AceGroup)
--   - Discord webhook logging per command
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================================================
-- MARK: COMMAND: DO
-- ============================================================================

lib.addCommand('do', {
    help   = 'Describe an action in third person (proximity)',
    params = {
        { name = 'mensaje', type = 'longString', help = 'Action to describe' }
    }
}, function(source, args)
    if not Config.Do.Enabled then
        Debug.Warn('COMMANDS', '/do used while disabled', {source = source})
        return
    end

    local msg         = args.mensaje
    local displayName = GetDisplayName(source)
    local ped         = GetPlayerPed(source)
    local coords      = GetEntityCoords(ped)

    Debug.Event('COMMANDS', '/do executed', {source = source, display = displayName})

    for _, v in pairs(GetPlayers()) do
        local tCoords = GetEntityCoords(GetPlayerPed(v))

        if #(coords - tCoords) < Config.Proximity.Do then
            TriggerClientEvent('chat:addMessage', v, {
                templateId = 'do',
                multiline  = true,
                args       = {displayName, msg}
            })

            TriggerClientEvent('metarp_chat:client:show3dText', v, source, msg, Config.Do.Color)
        end
    end

    local wh = Config.Webhook.Do
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = 'Mi2SiS Chat | Do',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'Player', value = displayName, inline = true },
                { name = 'Steam',  value = ids.steam,   inline = true }
            }
        })
    end
end)

-- ============================================================================
-- MARK: COMMAND: ME
-- ============================================================================

lib.addCommand('me', {
    help   = 'Describe a character action (proximity)',
    params = {
        { name = 'mensaje', type = 'longString', help = 'Character action' }
    }
}, function(source, args)
    if not Config.Me.Enabled then
        Debug.Warn('COMMANDS', '/me used while disabled', {source = source})
        return
    end

    local msg         = args.mensaje
    local displayName = GetDisplayName(source)
    local ped         = GetPlayerPed(source)
    local coords      = GetEntityCoords(ped)

    Debug.Event('COMMANDS', '/me executed', {source = source, display = displayName})

    for _, v in pairs(GetPlayers()) do
        local tCoords = GetEntityCoords(GetPlayerPed(v))

        if #(coords - tCoords) < Config.Proximity.Me then
            TriggerClientEvent('chat:addMessage', v, {
                templateId = 'me',
                multiline  = true,
                args       = {displayName, msg}
            })

            TriggerClientEvent('metarp_chat:client:show3dText', v, source, msg, Config.Me.Color)
        end
    end

    local wh = Config.Webhook.Me
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = 'Mi2SiS Chat | Me',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'Player', value = displayName, inline = true },
                { name = 'Steam',  value = ids.steam,   inline = true }
            }
        })
    end
end)

-- ============================================================================
-- MARK: COMMAND: OOC
-- ============================================================================

-- OOC is proximity-based for regular players.
-- Players with Config.OOC.AceGroup receive all OOC messages globally.
lib.addCommand('ooc', {
    help   = 'Out-of-character message (proximity; global for staff)',
    params = {
        { name = 'mensaje', type = 'longString', help = 'OOC message' }
    }
}, function(source, args)
    if not Config.OOC.Enabled then
        Debug.Warn('COMMANDS', '/ooc used while disabled', {source = source})
        return
    end

    local msg         = args.mensaje
    local displayName = GetDisplayName(source)
    local isStaff     = IsStaff(source, Config.OOC.AceGroup)
    local ped         = GetPlayerPed(source)
    local coords      = GetEntityCoords(ped)

    Debug.Event('COMMANDS', '/ooc executed', {
        source  = source,
        display = displayName,
        global  = isStaff
    })

    for _, v in pairs(GetPlayers()) do
        local send = false

        -- Sender always receives their own message
        if v == tostring(source) then
            send = true
        -- Staff receive all OOC globally
        elseif isStaff then
            send = true
        -- Regular players only if within proximity radius
        else
            local tCoords = GetEntityCoords(GetPlayerPed(v))
            if #(coords - tCoords) < Config.Proximity.OOC then
                send = true
            end
        end

        if send then
            TriggerClientEvent('chat:addMessage', v, {
                templateId = 'ooc',
                multiline  = true,
                args       = {displayName, msg}
            })
        end
    end

    local wh = Config.Webhook.OOC
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = isStaff and 'Mi2SiS Chat | OOC Global' or 'Mi2SiS Chat | OOC',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'Player', value = displayName,                    inline = true },
                { name = 'Steam',  value = ids.steam,                      inline = true },
                { name = 'Type',   value = isStaff and 'GLOBAL' or 'LOCAL', inline = true }
            }
        })
    end
end)