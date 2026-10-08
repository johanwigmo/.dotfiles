-- In-buffer git hunks — review agent diffs line-by-line.
return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns
            local function map(lhs, rhs, desc, modes)
                vim.keymap.set(modes or "n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
            end

            map("]h", function() gs.nav_hunk("next") end, "Next hunk")
            map("[h", function() gs.nav_hunk("prev") end, "Previous hunk")
            map("<leader>hs", gs.stage_hunk, "Stage hunk")
            map("<leader>hr", gs.reset_hunk, "Reset hunk")
            map("<leader>hp", gs.preview_hunk, "Preview hunk")
            map("<leader>hb", gs.toggle_current_line_blame, "Toggle line blame")

            map("ih", "<Cmd><C-U>Gitsigns select_hunk<CR>", "inside hunk", { "o", "x" })
        end,
    },
}
