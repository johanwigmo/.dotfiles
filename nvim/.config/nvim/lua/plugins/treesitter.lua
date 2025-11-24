return {
    'nvim-treesitter/nvim-treesitter', 
    build = ":TSUpdate",

    config = function() 
        require("nvim-treesitter.configs").setup({
            ensure_installed = { 
                "lua", 
                "vim", 
                "vimdoc", 
                "query", 
                "javascript", 
                "html", 
                "kotlin", 
                "swift",
                "todotxt"
            },
            sync_install = false,
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },  
        })

        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        parser_config.todotxt = {
            install_info = {
                url = "https://github.com/arnarg/tree-sitter-todotxt",
                files = { "src/parser.c" },
                branch = "main"
            },
            filetype = "todotxt"
        }

        local todo_root = vim.fn.expand("$TODO_ROOT")
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            pattern = {
                todo_root .. "/*.txt",
                todo_root .. "/**/*.txt"
            },
            command = "set filetype=todotxt"
        })
    end
}

