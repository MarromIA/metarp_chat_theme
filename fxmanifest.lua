fx_version 'cerulean'
game 'common'
lua54 'yes'

name 'metarp_chat'
description 'mantine-styled theme for the chat resource.'
version '1.0.0'

nui_callback_strict_mode 'false'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/sh_debug.lua',
    'shared/sh_locales.lua',
}

files {
    'locales/*.json',
}

client_scripts {
    'client/cl_config.lua',
    'client/cl_main.lua',
    'client/cl_death.lua',
    'client/cl_dome.lua'
}

server_scripts {
    'server/sv_webhooks.lua',
    'server/sv_main.lua',
    'server/sv_utils.lua',
    'server/commands/sv_proximity.lua',
    'server/commands/sv_global.lua',
    'server/commands/sv_staff.lua'
}

files {
    'theme/**',
}

-- need extra spans around {0} and {1} because of a bug in chat
-- see https://github.com/citizenfx/fivem/pull/3705
chat_theme 'qbox_chat' {
    styleSheet = 'theme/app.css',
    script = 'theme/app.js',
    msgTemplates = {
        -- Fallback templates for console/external messages
        default    = '<p class="message-wrapper msg-tagged msg-fallback"><span class="msg-tag"><span>···</span></span><span class="msg-content"><span class="author alt"><span>{0}</span></span><span><span>{1}</span></span></span></p>',
        defaultAlt = '<p class="message-wrapper msg-tagged msg-fallback"><span class="msg-tag"><span>···</span></span><span class="msg-content"><span class="alt"><span>{0}</span></span></span></p>',
        print      = '<p class="message-wrapper msg-tagged msg-print"><span class="msg-tag"><span>CON</span></span><span class="msg-content"><span class="author console">Console</span><span class="print color-7"><span>{0}</span></span></span></p>',

        -- System join/quit and user chat templates
        join    = '<p class="message-wrapper"><span class="join"><span>{0}</span></span></p>',
        quit    = '<p class="message-wrapper"><span class="quit"><span>{0}</span></span></p>',
        user    = '<p class="message-wrapper"><span class="author user"><span>{0}</span></span><span><span>{1}</span></span></p>',
        command = '<p class="message-wrapper command-msg"><span class="cmd-bar"></span><span class="author cmd-author"><span>{0}</span></span><span><span>{1}</span></span></p>',

        -- Roleplay command templates
        -- anon: static "Anónimo" author label so the message is not top-aligned
        -- gh:   static "Anuncio de Staff" label for the same layout reason
        twt    = '<p class="message-wrapper msg-tagged msg-twt"><span class="msg-tag"><span>BIRDY</span></span><span class="msg-content"><span class="author"><span>{0}</span></span><span><span>{1}</span></span></span></p>',
        anon   = '<p class="message-wrapper msg-tagged msg-anon"><span class="msg-tag"><span>ANON</span></span><span class="msg-content"><span class="author"><span>Anónimo</span></span><span><span>{0}</span></span></span></p>',
        ['do'] = '<p class="message-wrapper msg-tagged msg-do"><span class="msg-tag"><span>DO</span></span><span class="msg-content"><span class="author"><span>{0}</span></span><span><span>{1}</span></span></span></p>',
        me     = '<p class="message-wrapper msg-tagged msg-me"><span class="msg-tag"><span>ME</span></span><span class="msg-content"><span class="author"><span>{0}</span></span><span><span>{1}</span></span></span></p>',
        ooc    = '<p class="message-wrapper msg-tagged msg-ooc"><span class="msg-tag"><span>OOC</span></span><span class="msg-content"><span class="author"><span>{0}</span></span><span><span>{1}</span></span></span></p>',
        pm     = '<p class="message-wrapper msg-tagged msg-pm"><span class="msg-tag"><span>PM</span></span><span class="msg-content"><span class="author"><span>{0}</span></span><span><span>{1}</span></span></span></p>',
        gh     = '<p class="message-wrapper msg-tagged msg-gh"><span class="msg-tag"><span>STAFF</span></span><span class="msg-content"><span class="author"><span>Anuncio de Staff</span></span><span><span>{0}</span></span></span></p>',
    },
}
