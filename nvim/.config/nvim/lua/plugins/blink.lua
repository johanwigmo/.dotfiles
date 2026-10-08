-- blink.cmp — LSP/snippet/path/buffer completion (replaces nvim-cmp)
-- Pinned to v1: v2 ships breaking changes; re-check if it ever releases.
return {
    "saghen/blink.cmp",
    version = "1.*", -- v1.10.2 is latest (re-checked 2026-10-08)
    event = "InsertEnter",

    opts = {
        keymap = {
            preset = "default",
            -- scroll docs in the intuitive direction (old cmp config had these swapped)
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },
            ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        },
        completion = {
            documentation = { auto_show = true, auto_show_delay_ms = 100 },
            -- keep the old noinsert behavior: nothing inserted until confirmed
            list = { selection = { auto_insert = false } },
        },
        signature = { enabled = true },

        sources = {
            default = { "lsp", "snippets", "path", "buffer" },
            per_filetype = {
                -- notes vault markdown; wiki_links is unavailable outside $NOTES
                markdown = { "wiki_links", "buffer", "path" },
            },
            providers = {
                wiki_links = { module = "notes.wiki_links" },
            },
        },
    },
}
