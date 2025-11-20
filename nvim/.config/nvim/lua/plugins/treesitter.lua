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

        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            pattern = {
                "/Users/johanwigmo/Library/Mobile Documents/com~apple~CloudDocs/Todo/*.txt",
                "/Users/johanwigmo/Library/Mobile Documents/com~apple~CloudDocs/Todo/**/*.txt",
                "todo.txt"
            },
            command = "set filetype=todotxt"
        })
    end
}

