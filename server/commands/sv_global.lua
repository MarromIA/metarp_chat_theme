-- ============================================================================
-- METARP CHAT - GLOBAL COMMANDS (SERVER)
-- ============================================================================
-- Version: 1.0.0
-- Description: /twt and /anon commands broadcast to all connected players
-- Features:
--   - Phone item requirement via ox_inventory
--   - Per-player cooldown tracked in memory
--   - /anon deducts from bank account before sending
--   - Identity hidden from chat; real author logged via webhook only
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================================================
-- MARK: STATE VARIABLES
-- ============================================================================

local lastTweet = {} -- [source] = os.time() of last tweet
local lastAnon  = {} -- [source] = os.time() of last anon message

-- ============================================================================
-- MARK: COMMAND: TWT
-- ============================================================================

lib.addCommand('twt', {
    help   = 'Post a tweet visible to all players (requires phone)',
    params = {
        { name = 'mensaje', type = 'longString', help = 'Tweet content' }
    }
}, function(source, args)
    if not Config.Twitter.Enabled then
        Debug.Warn('COMMANDS', '/twt used while disabled', {source = source})
        return
    end

    local msg    = args.mensaje
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        Debug.Error('COMMANDS', '/twt: player object not found', {source = source})
        return
    end

    -- Phone check
    if not HasPhone(source) then
        Notify(source, _L('errors.no_phone'), 'error')
        return
    end

    -- Cooldown check
    local now = os.time()
    if lastTweet[source] and (now - lastTweet[source]) < Config.Twitter.Delay then
        local remaining = Config.Twitter.Delay - (now - lastTweet[source])
        Notify(source, _L('errors.cooldown_active', {remaining = remaining}), 'error')
        return
    end

    lastTweet[source] = now

    local char       = player.PlayerData.charinfo
    local playerName = ('%s %s'):format(char.firstname, char.lastname)

    Debug.Event('COMMANDS', '/twt sent', {source = source, name = playerName})

    for _, v in pairs(GetPlayers()) do
        TriggerClientEvent('chat:addMessage', v, {
            templateId = 'twt',
            multiline  = true,
            args       = {playerName, msg}
        })
    end

    Notify(source, _L('success.tweet_sent'), 'success')

    local wh = Config.Webhook.Twitter
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = 'Mi2SiS Chat | Twitter',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'Player', value = ('%s [%s]'):format(playerName, source), inline = true },
                { name = 'Steam',  value = ids.steam,                               inline = true }
            }
        })
    end
end)

-- ============================================================================
-- MARK: COMMAND: ANON
-- ============================================================================

-- Sender identity is intentionally hidden in chat.
-- Real author is logged in the webhook for moderation purposes.
lib.addCommand('anon', {
    help   = ('Post anonymous message (phone + ${cost} bank)'):format(Config.Anon.Cost),
    params = {
        { name = 'mensaje', type = 'longString', help = 'Anonymous message content' }
    }
}, function(source, args)
    if not Config.Anon.Enabled then
        Debug.Warn('COMMANDS', '/anon used while disabled', {source = source})
        return
    end

    local msg    = args.mensaje
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        Debug.Error('COMMANDS', '/anon: player object not found', {source = source})
        return
    end

    -- Phone check
    if not HasPhone(source) then
        Notify(source, _L('errors.no_phone'), 'error')
        return
    end

    -- Bank balance check
    local bankMoney = GetPlayerCash(player, 'bank')
    if bankMoney < Config.Anon.Cost then
        Notify(source, _L('errors.insufficient_funds', {amount = Config.Anon.Cost}), 'error')
        return
    end

    -- Cooldown check
    local now = os.time()
    if lastAnon[source] and (now - lastAnon[source]) < Config.Anon.Delay then
        local remaining = Config.Anon.Delay - (now - lastAnon[source])
        Notify(source, _L('errors.cooldown_active', {remaining = remaining}), 'error')
        return
    end

    -- Deduct bank payment
    if not RemovePlayerMoney(source, 'bank', Config.Anon.Cost, 'Mensaje Anónimo') then
        Notify(source, _L('errors.payment_failed'), 'error')
        return
    end

    lastAnon[source] = now

    local char       = player.PlayerData.charinfo
    local playerName = ('%s %s'):format(char.firstname, char.lastname)

    Debug.Event('COMMANDS', '/anon sent', {source = source, cost = Config.Anon.Cost})

    for _, v in pairs(GetPlayers()) do
        TriggerClientEvent('chat:addMessage', v, {
            templateId = 'anon',
            multiline  = true,
            args       = {msg}
        })
    end

    Notify(source, _L('success.anon_sent', {cost = Config.Anon.Cost}), 'success')

    local wh = Config.Webhook.Anon
    if wh.Url and wh.Url ~= '' then
        local ids = GetPlayerIdentifiers(source)
        SendWebhook(wh.Url, {
            title       = 'Mi2SiS Chat | Anon',
            description = msg,
            color       = wh.Color,
            fields      = {
                { name = 'Real Author', value = playerName,                       inline = true },
                { name = 'Player',      value = tostring(source),                  inline = true },
                { name = 'Cost',        value = ('$%d'):format(Config.Anon.Cost),  inline = true }
            }
        })
    end
end)