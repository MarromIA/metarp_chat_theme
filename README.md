# metarp_chat

Chat resource for FiveM with a Mantine-inspired theme, proximity-based roleplay commands, Discord webhook logging, and a debug + locale system.

Built on top of **qbx_chat** (QBox), compatible with **QBCore** and **QBX**.

---

## Features

- Custom NUI theme with colored sidebar tags per command type
- Proximity chat: `/do`, `/me`, `/ooc`
- Global commands: `/twt`, `/anon`
- Staff-only commands: `/pm`, `/gh`
- 3D overhead text above player heads for proximity messages
- Per-message server timestamp displayed inside each chat bubble
- Discord webhook logging per command
- Debug system with per-type and per-module filtering
- Multi-language locale system (`es` / `en`)

---

## Dependencies

| Resource | Required |
|---|---|
| [qbx_chat](https://github.com/qbox-org/qbx_chat) | ✅ |
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ |
| [qbx_core](https://github.com/qbox-org/qbx_core) or qb-core | ✅ |
| [ox_inventory](https://github.com/overextended/ox_inventory) | ✅ |
| [osp_ambulance](https://github.com/osp-group/osp_ambulance) | Optional |

---

## Installation

1. Drop the `metarp_chat` folder into your `resources` directory
2. Add `ensure metarp_chat` to your `server.cfg` — **after** `qbx_chat` and `ox_lib`
3. Configure `shared/config.lua` to match your server settings
4. Add your Discord webhook URLs to `server/sv_webhooks.lua`
5. Set your language in `config.lua`: `Config.Language = 'es'` or `'en'`

---

## Commands

| Command | Description | Restriction |
|---|---|---|
| `/do [message]` | Third-person action (proximity) | All players |
| `/me [message]` | Character action (proximity) | All players |
| `/ooc [message]` | Out-of-character (proximity / global for staff) | All players |
| `/twt [message]` | Twitter-style global broadcast (requires phone) | All players |
| `/anon [message]` | Anonymous global message (requires phone + bank) | All players |
| `/pm [id] [message]` | Private message to a player | Staff (`Config.PM.AceGroup`) |
| `/gh [message]` | Global staff announcement | Staff (`Config.GH.AceGroup`) |
| `/clear` | Clear your chat window | All players |

---

## Configuration

All settings are in `shared/config.lua`. Webhook URLs are in `server/sv_webhooks.lua` (server-side only, never exposed to clients).

Theme colors and fonts can be changed in `client/cl_config.lua`.

---

## Structure

```
metarp_chat/
├── shared/
│   ├── config.lua
│   ├── sh_debug.lua
│   └── sh_locales.lua
├── client/
│   ├── cl_config.lua
│   ├── cl_main.lua
│   ├── cl_death.lua
│   └── cl_dome.lua
├── server/
│   ├── sv_webhooks.lua
│   ├── sv_main.lua
│   ├── sv_utils.lua
│   └── commands/
│       ├── sv_proximity.lua
│       ├── sv_global.lua
│       └── sv_staff.lua
├── theme/
│   ├── app.css
│   └── app.js
├── locales/
│   ├── en.json
│   └── es.json
└── fxmanifest.lua
```
