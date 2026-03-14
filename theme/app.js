(async () => {
    const RESOURCE_NAME = 'metarp_chat';

    // ── fetchNui ────────────────────────────────────────────────────────────

    async function fetchNui(endpoint, data) {
        const body = typeof data === 'undefined' || data === null ? null : JSON.stringify(data);
        const response = await fetch(`https://${RESOURCE_NAME}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body,
        });
        return await response.json();
    }

    // ── CSS variables ───────────────────────────────────────────────────────

    const data = await fetchNui('config');

    /** @type {{ property: string; value: string | null }[]} */
    const vars = [
        { property: '--main-color',             value: data.mainColor },
        { property: '--border-color',           value: data.borderColor },
        { property: '--text-color',             value: data.textColor },
        { property: '--faint-color',            value: data.faintColor },
        { property: '--font-family',            value: data.fontFamily },
        { property: '--console-font-family',    value: data.consoleFontFamily },
        { property: '--suggestion-font-family', value: data.suggestionFontFamily },
        { property: '--input-icon-url',         value: `url(${data.inputIconUrl})` },
        { property: '--message-icon-url',       value: `url(${data.messageIconUrl})` },
        { property: '--console-icon-url',       value: `url(${data.consoleIconUrl})` },
        { property: '--join-icon-url',          value: `url(${data.joinIconUrl})` },
        { property: '--quit-icon-url',          value: `url(${data.quitIconUrl})` },
        { property: '--user-icon-url',          value: `url(${data.userIconUrl})` },
        { property: '--tag-twt-color',          value: data.tagTwt },
        { property: '--tag-anon-color',         value: data.tagAnon },
        { property: '--tag-do-color',           value: data.tagDo },
        { property: '--tag-me-color',           value: data.tagMe },
        { property: '--tag-ooc-color',          value: data.tagOoc },
        { property: '--tag-pm-color',           value: data.tagPm },
        { property: '--tag-gh-color',           value: data.tagGh },
        { property: '--tag-fallback-color',     value: data.tagFallback },
        { property: '--tag-print-color',        value: data.tagPrint },
    ];

    for (const { property, value } of vars) {
        document.documentElement.style.setProperty(property, value);
    }

    // ── Cached server time ──────────────────────────────────────────────────
    // We only need cachedTime for injecting timestamps on new messages.
    // No clock element is rendered on screen.

    let cachedTime = '--:--';

    const syncTime = async () => {
        try {
            const t = await fetchNui('time');
            cachedTime = t.time;
        } catch (_) {}
    };
    syncTime();
    setInterval(syncTime, 1000);

    // ── Chat observer ────────────────────────────────────────────────────────

    const attachScrollObserver = () => {
        const chatMessages = document.querySelector('.chat-messages');
        if (!chatMessages) return;

        const scrollToBottom = () => {
            chatMessages.scrollTop = chatMessages.scrollHeight;
        };

        new MutationObserver((mutations) => {
            for (const mutation of mutations) {
                for (const node of mutation.addedNodes) {
                    if (node.nodeType !== 1) continue;

                    const wrappers = node.classList?.contains('message-wrapper')
                        ? [node]
                        : [...(node.querySelectorAll?.('.message-wrapper') ?? [])];

                    for (const wrapper of wrappers) {
                        if (wrapper.querySelector('.msg-time')) continue;

                        const timeSpan = document.createElement('span');
                        timeSpan.className = 'msg-time';
                        timeSpan.textContent = cachedTime;
                        wrapper.appendChild(timeSpan);
                    }
                }
            }

            scrollToBottom();
        }).observe(chatMessages, { childList: true, subtree: true });

        scrollToBottom();
    };

    const domObserver = new MutationObserver(() => {
        if (document.querySelector('.chat-messages')) {
            domObserver.disconnect();
            attachScrollObserver();
        }
    });
    domObserver.observe(document.body, { childList: true, subtree: true });

})();