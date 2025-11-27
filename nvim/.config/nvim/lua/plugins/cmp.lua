return {
    "hrsh7th/nvim-cmp", 
    event = "InsertEnter", 
    dependencies = {
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path"
    },
    config = function()
        local cmp = require("cmp")

        cmp.setup({
            mapping = cmp.mapping.preset.insert({
                ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                ["<C-u>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.close(),
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = true,
                }),
            }),
            sources = cmp.config.sources({
                { name = "buffer" },
                { name = "path" },
            }),
        })

        cmp.setup.filetype("markdown", {
            sources = cmp.config.sources({
                { name = "obsidian" },
                { name = "obsidian_new" },
            })
        })

        vim.cmd([[
            set completeopt=menuone,noinsert,noselect
            highlight! default link CmpItemKind CmpItemMenuDefault
            ]])
    end,
}
