# metarp_chat — Technical Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [File Reference](#file-reference)
4. [Shared Systems](#shared-systems)
   - [Debug System](#debug-system)
   - [Locale System](#locale-system)
   - [Config](#config)
5. [Server Scripts](#server-scripts)
   - [sv_webhooks.lua](#sv_webhookslua)
   - [sv_utils.lua](#sv_utilslua)
   - [sv_main.lua](#sv_mainlua)
   - [sv_proximity.lua](#sv_proximitylua)
   - [sv_global.lua](#sv_globallua)
   - [sv_staff.lua](#sv_stafflua)
6. [Client Scripts](#client-scripts)
   - [cl_config.lua](#cl_configlua)
   - [cl_main.lua](#cl_mainlua)
   - [cl_death.lua](#cl_deathlua)
   - [cl_dome.lua](#cl_domelua)
7. [NUI Theme](#nui-theme)
   - [app.js](#appjs)
   - [app.css](#appcss)
   - [Message Templates](#message-templates)
8. [Commands Reference](#commands-reference)
9. [Webhook System](#webhook-system)
10. [Debug System Reference](#debug-system-reference)
11. [Locale System Reference](#locale-system-reference)
12. [Server Time & Timestamps](#server-time--timestamps)
13. [3D Overhead Text](#3d-overhead-text)
14. [Chat Message Hooks](#chat-message-hooks)
15. [Known Limitations](#known-limitations)

---

## Overview

`metarp_chat` is a full replacement of the default FiveM chat theme, built on top of `qbx_chat`. It provides a custom NUI interface with Mantine-style bubbles, roleplay-specific commands with proximity delivery, Discord webhook logging, per-message timestamps, and a reusable debug and locale framework.

The resource runs on **QBX** or **QBCore** and requires **ox_lib** for command registration and notifications.

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                    CLIENT                        │
│  cl_config.lua   ─── NUI config + time cache     │
│  cl_main.lua     ─── init guard + /clear         │
│  cl_death.lua    ─── isDead callback             │
│  cl_dome.lua     ─── 3D overhead text renderer   │
└──────────────────┬───────────────────────────────┘
                   │ TriggerClientEvent / NetEvent
┌──────────────────┴───────────────────────────────┐
│                    SERVER                        │
│  sv_webhooks.lua ─── Discord embed dispatcher    │
│  sv_utils.lua    ─── shared helpers + hooks      │
│  sv_main.lua     ─── init + time broadcast       │
│  sv_proximity    ─── /do /me /ooc                │
│  sv_global       ─── /twt /anon                  │
│  sv_staff        ─── /pm /gh                     │
└──────────────────────────────────────────────────┘
                   │ fetchNui / RegisterNUICallback
┌──────────────────┴───────────────────────────────┐
│                   NUI (iframe)                   │
│  app.js    ─── CSS vars, time sync, timestamps   │
│  app.css   ─── layout, tagged messages, bubbles  │
└──────────────────────────────────────────────────┘
```

The NUI runs inside an isolated iframe provided by `qbx_chat`. It cannot receive `SendNUIMessage` from the client directly — all communication goes through `RegisterNUICallback` / `fetchNui`.

---

## File Reference

```
metarp_chat/
├── fxmanifest.lua              Resource manifest and msgTemplates
├── shared/
│   ├── config.lua              All configurable values (no secrets)
│   ├── sh_debug.lua            Unified logging framework
│   └── sh_locales.lua          Multi-language string system
├── client/
│   ├── cl_config.lua           NUI callbacks: config + time
│   ├── cl_main.lua             Init guard + /clear command
│   ├── cl_death.lua            ox_lib callback: isDead
│   └── cl_dome.lua             3D text renderer
├── server/
│   ├── sv_webhooks.lua         Config.Webhook + SendWebhook()
│   ├── sv_main.lua             Startup + time broadcast loop
│   ├── sv_utils.lua            Helper functions + message hooks
│   └── commands/
│       ├── sv_proximity.lua    /do /me /ooc
│       ├── sv_global.lua       /twt /anon
│       └── sv_staff.lua        /pm /gh
├── theme/
│   ├── app.js                  NUI script
│   └── app.css                 NUI stylesheet
└── locales/
    ├── en.json                 English strings
    └── es.json                 Spanish strings
```

---

## Shared Systems

### Debug System

**File:** `shared/sh_debug.lua`  
**Loaded:** shared (client + server)

The debug system provides colored, filterable console output with automatic client/server detection.

#### Side detection

```lua
local isClient = IsDuplicityVersion() == false
local side     = isClient and 'CLIENT' or 'SERVER'
```

#### Output format

**Client (F8 console):**
```
^6[CLIENT] [i] [INFO] COMMANDS: /do executed^7
^8  |-> Data: {"source":1,"display":"Marrom | 1"}^7
```

**Server (terminal):**
```
[35m[SERVER] ℹ️  [INFO] COMMANDS: /do executed[0m
[90m  └─ Data: {"source":1,"display":"Marrom | 1"}[0m
```

#### Configuration in `config.lua`

```lua
Config.Debug = {
    Enabled        = false,  -- Master switch
    ShowTimestamps = false,  -- [HH:MM:SS] prefix on server logs

    Types = {
        INFO     = true,
        WARN     = true,
        ERROR    = true,   -- Always shown regardless of Enabled
        SUCCESS  = true,
        EVENT    = true,
        FUNCTION = false,  -- Verbose: function entry tracing
        RETURN   = false   -- Verbose: function return tracing
    },

    Categories = {
        Server   = true,
        Client   = true,
        Commands = true,
        Webhooks = true,
        Dom3D    = true,
        NUI      = true,
        Locales  = true
    }
}
```

#### Public API

```lua
Debug.Info('COMMANDS', 'message', { optional = 'data' })
Debug.Warn('COMMANDS', 'message')
Debug.Error('COMMANDS', 'message')   -- always shown
Debug.Success('COMMANDS', 'message')
Debug.Event('COMMANDS', 'message')
Debug.Function('FunctionName', { param = value })
Debug.Return('FunctionName', result, { returned = value })
```

#### Hot loop rule

Never call `Debug.*` unconditionally inside `Wait(0)` threads. Use probabilistic logging:

```lua
-- Log approximately 1% of iterations to avoid console flooding
if math.random(1, 100) <= 1 then
    Debug.Info('DOM3D', 'Render tick', { count = #messages })
end
```

---

### Locale System

**File:** `shared/sh_locales.lua`  
**Loaded:** shared (client + server)

Provides hierarchical dot-notation string access with variable interpolation.

#### Usage

```lua
-- Simple key
_L('errors.no_phone')
-- → "Necesitas un celular para usar este comando"

-- With variable interpolation
_L('errors.cooldown_active', { remaining = 15 })
-- → "Cooldown activo: 15s restantes"

_L('success.anon_sent', { cost = 500 })
-- → "Mensaje anónimo enviado (-$500)"
```

`_L` is a global alias for `Locale.Get`. All server command files use `_L()` in every `Notify()` call.

#### JSON structure (`locales/es.json`)

```json
{
    "errors": {
        "no_phone":           "Necesitas un celular...",
        "cooldown_active":    "Cooldown activo: {remaining}s restantes",
        "insufficient_funds": "Fondos insuficientes. Necesitas ${amount}"
    },
    "success": {
        "tweet_sent":         "Tweet publicado exitosamente",
        "anon_sent":          "Mensaje anónimo enviado (-${cost})"
    },
    "info": {
        "pm_received":        "Mensaje privado recibido de {name}"
    }
}
```

#### Fallback chain

```
Config.Language ('es')
    ↓ file not found or parse error
fallbackLanguage ('en')
    ↓ also fails
hardcoded emergency table in sh_locales.lua
```

If a key is missing, `Locale.Get` returns the key string itself — it never throws.

#### Language setting

```lua
-- shared/config.lua
Config.Language = 'es'
```

---

### Config

**File:** `shared/config.lua`  
**Loaded:** shared (client + server)

Contains all configurable values **except** webhook URLs, which are server-only in `sv_webhooks.lua`.

Key sections:

| Section | Keys | Notes |
|---|---|---|
| `Config.Language` | `'es'`, `'en'` | Locale file to load |
| `Config.Do/Me/OOC` | `Enabled`, `Color`, `Delay`, `AceGroup` | Per-command settings |
| `Config.Twitter/Anon` | `Enabled`, `Item`, `Cost`, `Delay` | Global commands |
| `Config.PM/GH` | `Enabled`, `Delay`, `AceGroup` | Staff commands |
| `Config.Proximity` | `Do`, `Me`, `OOC` | Radius in meters |
| `Config.TextDuration` | number | 3D text display time (ms) |
| `Config.DrawMaxDistance` | number | Max render distance (m) |
| `Config.Debug` | table | See Debug System section |

---

## Server Scripts

### sv_webhooks.lua

**Loaded first** among server scripts so `Config.Webhook` is available to all command files.

Defines `Config.Webhook` with a `{ Url, Color }` entry per command type:

```lua
Config.Webhook = {
    Do      = { Url = '...', Color = 3066993  },
    Me      = { Url = '...', Color = 15105570 },
    OOC     = { Url = '...', Color = 9807270  },
    Twitter = { Url = '...', Color = 1942002  },
    Anon    = { Url = '...', Color = 8421504  },
    PM      = { Url = '...', Color = 10181046 },
    GH      = { Url = '...', Color = 16776960 },
}
```

#### `SendWebhook(webhookUrl, data)`

```lua
SendWebhook(wh.Url, {
    title       = 'Mi2SiS Chat | Do',
    description = msg,
    color       = wh.Color,
    fields      = {
        { name = 'Player', value = displayName, inline = true },
        { name = 'Steam',  value = ids.steam,   inline = true }
    }
})
```

Skips silently if the URL is empty or contains placeholder text (`YOUR_WEBHOOK`, `TU_WEBHOOK`). All HTTP errors are logged via `Debug.Error`.

---

### sv_utils.lua

Central helper module. Exposes functions globally (via `_G`) and as exports.

#### Framework detection

Detects `qbx_core` at startup (1s delay). Falls back to `QBCore` via `exports['qb-core']` in each command file.

```lua
CreateThread(function()
    Wait(1000)
    if GetResourceState('qbx_core') == 'started' then
        QBX = exports.qbx_core
    end
end)
```

#### Helper functions

| Function | Parameters | Returns | Notes |
|---|---|---|---|
| `GetPlayer(source)` | `number` | `table\|nil` | Framework player object |
| `RemovePlayerMoney(source, account, amount, reason)` | — | `boolean` | Removes money via framework |
| `GetPlayerCash(player, account)` | player object, string | `number` | Reads balance from PlayerData |
| `GetPlayerIdentifiers(source)` | `number` | `{steam, license, discord}` | Wraps native; avoids recursion via `_GetPlayerIdentifiers` alias |
| `IsPlayerDead(source)` | `number` | `boolean` | Reads metadata first, falls back to client callback |
| `HasPhone(source)` | `number` | `boolean` | ox_inventory item check |
| `IsStaff(source, aceGroup)` | `number`, `string` | `boolean` | `IsPlayerAceAllowed` wrapper |
| `Notify(source, message, type)` | — | — | ox_lib notify |
| `GetDisplayName(source)` | `number` | `string` | `"PlayerName \| ID"` |

#### Message hooks

Two hooks are registered on `exports.chat`:

1. **Template hook** — routes all player messages through the `user` template for consistent styling
2. **Cancel hook** — cancels any message that does not start with `/`, preventing direct chat bypass

---

### sv_main.lua

Initialization guard and server time broadcast.

```lua
-- Broadcasts HH:MM to all clients every second
CreateThread(function()
    while true do
        Wait(1000)
        TriggerClientEvent('metarp_chat:client:syncTime', -1, os.date('%H:%M'))
    end
end)
```

`os.date` is only available server-side in FiveM. Clients receive the time via this event and cache it for NUI callbacks.

---

### sv_proximity.lua

Handles `/do`, `/me`, and `/ooc`.

All three commands:
1. Validate `Config.X.Enabled`
2. Build `displayName` via `GetDisplayName(source)`
3. Iterate `GetPlayers()` checking distance against `Config.Proximity.X`
4. Trigger `chat:addMessage` with the appropriate `templateId`
5. Trigger `metarp_chat:client:show3dText` for 3D overhead rendering
6. Send Discord webhook

**OOC special behavior:** if `IsStaff(source, Config.OOC.AceGroup)` is true, all players receive the message regardless of distance. The webhook title changes to `'Mi2SiS Chat | OOC Global'`.

---

### sv_global.lua

Handles `/twt` and `/anon`.

Both commands require `HasPhone(source)` and enforce per-player cooldowns stored in `lastTweet[source]` / `lastAnon[source]` tables.

**`/anon` additional logic:**
- Checks bank balance via `GetPlayerCash(player, 'bank')`
- Deducts `Config.Anon.Cost` via `RemovePlayerMoney`
- The author is **not included** in the chat message — only the content
- The webhook logs the real author for moderation

---

### sv_staff.lua

Handles `/pm` and `/gh`. Both use `restricted = Config.X.AceGroup` in `lib.addCommand` — ox_lib handles the ace check before the callback fires.

**`/pm` flow:**
1. Builds `srcDisplay` and `tgtDisplay` via `GetDisplayName`
2. Sends identical `chat:addMessage` to both source and target
3. Notifies both players with `_L()` strings

**`/gh` flow:**
1. Broadcasts to all players via `GetPlayers()` loop
2. Author name intentionally omitted from chat
3. Webhook logs steam + ID for audit trail

---

## Client Scripts

### cl_config.lua

Serves NUI configuration via two callbacks:

#### `config` callback

Called by `app.js` on startup via `fetchNui('config')`. Returns a flat table of all CSS variable values and icon URLs. Edit this file to change the theme — no convars needed.

#### `time` callback

Called by `app.js` every second via `fetchNui('time')`. Returns `{ time = cachedTime }`.

`cachedTime` is populated by the `metarp_chat:client:syncTime` net event broadcast from `sv_main.lua`. It starts as `'--:--'` until the first server packet arrives.

```lua
-- Why not os.date on client?
-- os.date is a server-side only function in FiveM's Lua runtime.
-- Client-side Lua does not have access to the os library.
```

---

### cl_main.lua

Minimal entry point. Contains:
- An initialization guard that waits for `LocalPlayer.state.isLoggedIn`
- The `/clear` command (`TriggerEvent('chat:clear')`)

---

### cl_death.lua

Registers the `metarp_chat:client:isDead` ox_lib callback used by `sv_utils.IsPlayerDead`.

Priority order:
1. `exports['osp_ambulance']:isDead()` if the resource is running
2. `IsEntityDead(ped)`
3. `IsPedDeadOrDying(ped, true)`
4. `IsPedFatallyInjured(ped)`

---

### cl_dome.lua

Renders 3D overhead text above player heads for proximity commands.

#### State

```lua
local playerMessages = {}
-- [serverId] = { { text, color, time, duration }, ... }
```

#### Event: `metarp_chat:client:show3dText`

Receives `(playerId, message, color)` from the server. Appends to the player's message stack. Enforces `Config.MaxMessages` by removing the oldest entry when exceeded.

#### Render thread

Runs at `Wait(0)`. For each player with active messages:
1. Checks `DoesEntityExist(targetPed)` and `distance <= Config.DrawMaxDistance`
2. Reads head bone coordinates (`0x796e`)
3. Calls `DrawText3DWithOutline` for each message, offset vertically by `Config.LineSpacing`
4. Removes expired messages inline

**Distance-based scale interpolation:**

```
distance ≤ ScaleDistNear  →  TextScaleNear (0.55)
distance ≥ ScaleDistFar   →  TextScaleFar  (0.15)
between                   →  linear interpolation
```

**Alpha fade:** beyond 70% of `DrawMaxDistance`, alpha fades linearly to 0.

Uses 1% probabilistic logging in the render loop to avoid console flooding.

#### Cleanup thread

Runs every 5 seconds. Removes entries for players whose ped no longer exists (disconnected).

---

## NUI Theme

### app.js

Runs inside the `qbx_chat` NUI iframe. Cannot communicate with the client via `SendNUIMessage` — uses `fetchNui` exclusively.

#### Startup sequence

1. `fetchNui('config')` → inject CSS custom properties on `document.documentElement`
2. Start `setInterval(syncTime, 1000)` → keep `cachedTime` updated
3. `MutationObserver` on `document.body` → wait for `.chat-messages` to appear
4. Once found: attach scroll + timestamp observer on `.chat-messages`

#### Clock singleton guard

The IIFE runs every time the iframe reloads (resource restart, chat open/close). The clock element uses `getElementById` before `createElement` to avoid duplicates. In the current version the clock is not rendered to screen — `cachedTime` is purely internal.

#### Timestamp injection

When the `MutationObserver` detects a new `.message-wrapper` node:
```js
const timeSpan = document.createElement('span');
timeSpan.className = 'msg-time';
timeSpan.textContent = cachedTime;
wrapper.appendChild(timeSpan);
```

The guard `wrapper.querySelector('.msg-time')` prevents double-injection on replay events.

---

### app.css

All layout values use CSS custom properties injected by `app.js` from `cl_config.lua`.

#### Key layout rules

`.message-wrapper` — the outer bubble for all non-tagged messages:
- `position: relative` required for `.msg-time` absolute positioning
- `padding-bottom: 1.4rem` reserves space for the timestamp

`.msg-tagged` — overrides `.message-wrapper` for sidebar-tag messages:
- `flex-direction: row` puts the `.msg-tag` sidebar and `.msg-content` side by side
- `padding: 0` on the wrapper; padding lives inside `.msg-content`

`.msg-content` — content area inside tagged messages:
- `padding-bottom: 1.4rem` mirrors the wrapper's reserved timestamp space
- `padding-right: 2.5rem` prevents text from reaching the timestamp area

`.msg-tag` — the vertical colored sidebar:
- `writing-mode: vertical-rl` + `transform: rotate(180deg)` for bottom-to-top text
- Color controlled by per-type CSS variable: `var(--tag-twt-color)`, etc.

`.msg-time` — the per-message timestamp:
- `position: absolute; bottom: 0.3rem; right: 0.5rem`
- Uses `var(--faint-color)` at 60% opacity

#### Timestamp space tuning

To adjust the gap between message content and timestamp, change the `padding-bottom` on both:
- `.message-wrapper` (`padding: 0.6rem 1rem Xrem 1rem`)
- `.msg-content` (`padding: 0.5rem 2.5rem Xrem 0.75rem`)

Keep both values identical.

---

### Message Templates

Defined in `fxmanifest.lua` under `chat_theme.msgTemplates`.

| Template ID | Sidebar label | Author field | Content |
|---|---|---|---|
| `default` | `···` | `{0}` | `{1}` |
| `defaultAlt` | `···` | — | `{0}` |
| `print` | `CON` | `Console` (static) | `{0}` |
| `user` | — | `{0}` | `{1}` |
| `command` | — | `{0}` | `{1}` |
| `twt` | `BIRDY` | `{0}` (char name) | `{1}` |
| `anon` | `ANON` | `Anónimo` (static) | `{0}` |
| `do` | `DO` | `{0}` | `{1}` |
| `me` | `ME` | `{0}` | `{1}` |
| `ooc` | `OOC` | `{0}` | `{1}` |
| `pm` | `PM` | `{0}` | `{1}` |
| `gh` | `STAFF` | `Anuncio de Staff` (static) | `{0}` |

`anon` and `gh` use static author labels because their templates have no `{0}` author argument — without a static label the message floats to the top of `.msg-content` with no vertical balance.

---

## Commands Reference

### `/do [message]`

- **Delivery:** players within `Config.Proximity.Do` meters
- **Author format:** `"PlayerName | ID"`
- **Template:** `do`
- **3D text:** yes, `Config.Do.Color`
- **Webhook:** `Config.Webhook.Do`

### `/me [message]`

- **Delivery:** players within `Config.Proximity.Me` meters
- **Author format:** `"PlayerName | ID"`
- **Template:** `me`
- **3D text:** yes, `Config.Me.Color`
- **Webhook:** `Config.Webhook.Me`

### `/ooc [message]`

- **Delivery:** proximity by default; global if `IsStaff(source, Config.OOC.AceGroup)`
- **Author format:** `"PlayerName | ID"`
- **Template:** `ooc`
- **Webhook title:** `"OOC"` or `"OOC Global"` depending on staff status

### `/twt [message]`

- **Delivery:** all players
- **Requires:** `Config.PhoneItem` in ox_inventory
- **Cooldown:** `Config.Twitter.Delay` seconds
- **Author format:** character first + last name (from QBCore charinfo)
- **Template:** `twt`

### `/anon [message]`

- **Delivery:** all players
- **Requires:** phone item + `Config.Anon.Cost` in bank
- **Cooldown:** `Config.Anon.Delay` seconds
- **Author shown in chat:** `"Anónimo"` (static)
- **Author in webhook:** real character name
- **Template:** `anon`

### `/pm [id] [message]`

- **Delivery:** sender + target only
- **Restriction:** `Config.PM.AceGroup`
- **Author format:** `"SrcName | SrcID → TgtName | TgtID"`
- **Template:** `pm`

### `/gh [message]`

- **Delivery:** all players
- **Restriction:** `Config.GH.AceGroup`
- **Author shown in chat:** `"Anuncio de Staff"` (static)
- **Author in webhook:** FiveM name + steam + ID
- **Template:** `gh`

---

## Webhook System

All webhooks are defined in `server/sv_webhooks.lua`. This file is **server-side only** — webhook URLs are never exposed to connecting clients.

`SendWebhook(url, data)` dispatches a `PerformHttpRequest` POST with a Discord embed payload. It silently skips empty URLs and known placeholder values.

#### Embed structure

```
Title:   "Mi2SiS Chat | CommandName"
Desc:    The message content
Color:   Per-command integer color (Discord decimal format)
Fields:  Player, Steam, and contextual data
Footer:  "metarp_chat v2.2.0 | YYYY-MM-DD HH:MM:SS"
```

#### Adding a new webhook

1. Add an entry to `Config.Webhook` in `sv_webhooks.lua`
2. Call `SendWebhook(Config.Webhook.NewKey.Url, { ... })` in the relevant command

---

## Debug System Reference

See [Debug System](#debug-system) under Shared Systems.

To enable debugging for a specific module only:

```lua
Config.Debug = {
    Enabled = true,
    ShowTimestamps = true,
    Types = {
        INFO = true, WARN = true, ERROR = true,
        SUCCESS = true, EVENT = true,
        FUNCTION = false, RETURN = false
    },
    Categories = {
        Commands = true,   -- only this module
        Server   = false, Client = false, Webhooks = false,
        Dom3D    = false, NUI = false, Locales = false
    }
}
```

---

## Locale System Reference

See [Locale System](#locale-system) under Shared Systems.

#### Adding a new language

1. Create `locales/xx.json` with the same key structure as `en.json`
2. Set `Config.Language = 'xx'` in `config.lua`
3. Add `'locales/*.json'` is already in `fxmanifest.lua` files block — no manifest change needed

#### Adding a new string

1. Add the key to **both** `en.json` and `es.json`
2. Use `_L('category.key', { var = value })` in the Lua file

---

## Server Time & Timestamps

#### Why `os.date` cannot be called on the client

FiveM's client-side Lua runtime does not expose the `os` library. Calling `os.date` on the client throws `attempt to index a nil value (global 'os')`.

#### Solution flow

```
sv_main.lua
  └─ every 1000ms: TriggerClientEvent('metarp_chat:client:syncTime', -1, os.date('%H:%M'))
        ↓
cl_config.lua
  └─ AddEventHandler: cachedTime = time
  └─ RegisterNUICallback('time'): cb({ time = cachedTime })
        ↓
app.js
  └─ setInterval(syncTime, 1000): cachedTime = t.time
  └─ MutationObserver: timeSpan.textContent = cachedTime
```

Each message bubble gets the value of `cachedTime` at the moment it is inserted into the DOM, giving it the server time at send.

---

## 3D Overhead Text

Proximity commands (`/do`, `/me`, `/ooc`) trigger `metarp_chat:client:show3dText` in addition to the chat message. This renders floating text above the sender's head visible to nearby players.

#### Config values

| Key | Default | Description |
|---|---|---|
| `TextDuration` | 7500 | Display time in ms |
| `TextScale` | 0.40 | Base scale |
| `TextOffset` | 0.35 | Vertical offset above head bone |
| `LineSpacing` | 0.15 | Space between stacked messages |
| `MaxMessages` | 5 | Max messages per player at once |
| `Outline` | true | Text outline for readability |
| `TextScaleNear` | 0.55 | Scale at ≤ 2m |
| `TextScaleFar` | 0.15 | Scale at ≥ 10m |
| `DrawMaxDistance` | 25.0 | Render cutoff distance |
| `FadeWithDistance` | true | Alpha fade near cutoff |

---

## Chat Message Hooks

`sv_utils.lua` registers two hooks on `exports.chat`:

#### Hook 1 — Template assignment

```lua
exports.chat:registerMessageHook(function(source, _outMessage, hookRef)
    hookRef.updateMessage({ templateId = 'user' })
end)
```

Routes all player-typed messages through the `user` template, applying the consistent bubble style.

#### Hook 2 — Command filter

```lua
exports.chat:registerMessageHook(function(source, outMessage, hookRef)
    local msg = outMessage and outMessage.args and outMessage.args[2]
    if type(msg) == 'string' and msg:sub(1, 1) ~= '/' then
        hookRef.cancel()
    end
end)
```

Cancels any message that does not start with `/`. This prevents players from sending raw text through the chat box — all interaction must go through registered commands.

---

## Known Limitations

| Issue | Cause | Status |
|---|---|---|
| `os.date` unavailable on client | FiveM Lua client runtime omits `os` library | Worked around via server broadcast |
| NUI iframe reloads on resource restart | `qbx_chat` behavior | Clock singleton guard in `app.js` handles this |
| `GetPlayerIdentifiers` name collision | FiveM native has same name | Resolved via `_GetPlayerIdentifiers` alias before redefining |
| `chat_theme` script runs in isolated iframe | Cannot receive `SendNUIMessage` from client | All data flows through `RegisterNUICallback` / `fetchNui` |
| Timestamp shows `--:--` for ~1s after login | First sync packet from server takes up to 1s | Cosmetic only |
