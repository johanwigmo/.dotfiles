-- nvim-treesitter (main branch, Neovim 0.12+)
-- Installs parsers/queries only; highlighting/indent are enabled below.
local languages = {
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "javascript",
    "html",
    "kotlin",
    "swift",
    "todotxt",
}

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",

    config = function()
        -- Custom parser: todotxt
        vim.api.nvim_create_autocmd("User", {
            pattern = "TSUpdate",
            callback = function()
                require("nvim-treesitter.parsers").todotxt = {
                    install_info = {
                        url = "https://github.com/arnarg/tree-sitter-todotxt",
                        branch = "main",
                    },
                }
            end,
        })

        require("nvim-treesitter").install(languages)

        -- Enable highlighting + indent wherever a parser exists
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                if not pcall(vim.treesitter.start, args.buf) then return end
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })

        local todo_root = vim.fn.expand("$TODO_ROOT")
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            pattern = {
                todo_root .. "/*.txt",
                todo_root .. "/**/*.txt",
            },
            command = "set filetype=todotxt",
        })
    end,
}
