-- ============================================================================
-- METARP CHAT - WEBHOOK CONFIGURATION & DISPATCHER (SERVER)
-- ============================================================================
-- Version: 1.0.0
-- Description: Discord webhook URLs and embed sender for all chat commands
-- Features:
--   - Per-command webhook URL and embed color
--   - Kept server-side only to prevent URL exposure to clients
--   - Embed footer with resource version and server timestamp
--   - Configurable bot username
-- ============================================================================

-- ============================================================================
-- MARK: WEBHOOK CONFIGURATION
-- ============================================================================

-- NOTE: Webhooks live here (server-only) and NOT in shared/config.lua
-- to prevent Discord URLs from being exposed to connected clients.
Config.Webhook = {
    Do = {
        Url   = 'https://discord.com/api/webhooks/1409069023487983736/dDdCa3R3A9RxPebyUDFPoTQTDPG3uOcvx-hL7TNgcON6Zx0rc_d7WDfLjYxB6qEL9Rhj',
        Color = 3066993
    },
    Me = {
        Url   = 'https://discord.com/api/webhooks/1409069023487983736/dDdCa3R3A9RxPebyUDFPoTQTDPG3uOcvx-hL7TNgcON6Zx0rc_d7WDfLjYxB6qEL9Rhj',
        Color = 15105570
    },
    OOC = {
        Url   = 'https://discord.com/api/webhooks/1402524340288753704/LazeHKsqKhQEXY71bfkScK-eHKN40cdhuBV6bJUbdRYOt3y40byx2hD4iBt_AVXFCWJm',
        Color = 9807270
    },
    Twitter = {
        Url   = 'https://discord.com/api/webhooks/1402524798701146122/s2wAHOxCDHQR4l_M9b5mwh36sslL8htw59abFsRMD3pVwh2gQ1tMVP7RtLEZhfWKMaFx',
        Color = 1942002
    },
    Anon = {
        Url   = 'https://discord.com/api/webhooks/1402524798701146122/s2wAHOxCDHQR4l_M9b5mwh36sslL8htw59abFsRMD3pVwh2gQ1tMVP7RtLEZhfWKMaFx',
        Color = 8421504
    },
    PM = {
        Url   = 'https://discord.com/api/webhooks/1409077252473356438/Sq4N3cCjsCAYkk-fuJGAqYkgkgCLATFxmxuitwELTjbIVsSq_M_0U4rBYrrbiT4tWUvw',
        Color = 10181046
    },
    GH = {
        Url   = 'https://discord.com/api/webhooks/1409079653007884308/ov__44YrVeP-Mfz6qy_kLBrkMabkr_uo2cdxhuv0sDvSos2gDtIv39sUjWWmfclgsDpg',
        Color = 16776960
    },
}

-- ============================================================================
-- MARK: DISPATCHER
-- ============================================================================

--- Send a Discord embed via webhook.
--- Silently skips placeholder URLs to avoid noise in development.
---@param webhookUrl string  Target Discord webhook URL
---@param data       table   Embed data { title, description, color, fields }
---@return boolean   sent    True if the request was dispatched
function SendWebhook(webhookUrl, data)
    if not webhookUrl or webhookUrl == '' then
        Debug.Warn('WEBHOOKS', 'SendWebhook called with empty URL')
        return false
    end

    -- Skip development placeholder values
    if webhookUrl:find('YOUR_WEBHOOK') or webhookUrl:find('TU_WEBHOOK') then
        Debug.Warn('WEBHOOKS', 'Skipping placeholder webhook URL')
        return false
    end

    local embed = {
        {
            title       = data.title or 'Mi2SiS Chat',
            description = data.description or '',
            color       = data.color or 3447003,
            fields      = data.fields or {},
            footer      = {
                text = 'metarp_chat v2.2.0 | ' .. os.date('%Y-%m-%d %H:%M:%S')
            }
        }
    }

    -- Wrap in pcall to prevent a failed HTTP request from crashing the thread
    pcall(function()
        PerformHttpRequest(webhookUrl, function(statusCode)
            if statusCode >= 400 then
                Debug.Error('WEBHOOKS', 'HTTP request failed', {
                    status = statusCode,
                    title  = data.title
                })
            else
                Debug.Success('WEBHOOKS', 'Embed sent', {title = data.title, status = statusCode})
            end
        end, 'POST', json.encode({
            username = 'Mi2SiS Chat',
            embeds   = embed
        }), {['Content-Type'] = 'application/json'})
    end)

    return true
end

exports('SendWebhook', SendWebhook)