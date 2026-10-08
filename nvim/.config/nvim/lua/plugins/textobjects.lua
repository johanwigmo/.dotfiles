-- Treesitter textobjects: syntax-aware o/x-mode objects + n-motion jumps.
-- Standalone since the nvim-treesitter main-branch rewrite; Swift queries
-- live here: queries/swift/textobjects.scm (function/class/call/parameter).
return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,

    config = function()
        local select = require("nvim-treesitter-textobjects.select")
        local move = require("nvim-treesitter-textobjects.move")

        require("nvim-treesitter-textobjects").setup({
            select = { lookahead = true },
            move = { set_jumps = true },
        })

        local function sel(lhs, object, desc)
            vim.keymap.set({ "x", "o" }, lhs, function()
                select.select_textobject(object, "textobjects")
            end, { silent = true, desc = desc })
        end

        sel("af", "@function.outer", "a function")
        sel("if", "@function.inner", "inside function")
        sel("ac", "@class.outer", "a class/type")
        sel("ic", "@class.inner", "inside class/type")
        sel("aa", "@parameter.outer", "an argument")
        sel("ia", "@parameter.inner", "inside argument")

        local function mv(lhs, fn, object, desc)
            vim.keymap.set({ "n", "x", "o" }, lhs, function()
                move[fn](object, "textobjects")
            end, { silent = true, desc = desc })
        end

        mv("]m", "goto_next_start", "@function.outer", "Next function start")
        mv("[m", "goto_previous_start", "@function.outer", "Previous function start")
        mv("]]", "goto_next_start", "@class.outer", "Next type start")
        mv("[[", "goto_previous_start", "@class.outer", "Previous type start")
    end
}
