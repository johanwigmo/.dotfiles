-- fzf-native sorter (C, fast on large Swift/SPM trees) + pickers.
return {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
        },
    },

    config = function()
        require('telescope').setup({
            extensions = { fzf = {} },
        })
        pcall(require('telescope').load_extension, 'fzf')

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Git files' })
        vim.keymap.set('n', '<leader>ps', builtin.live_grep, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>pw', builtin.grep_string, { desc = 'Grep word under cursor' })

        -- LSP pickers
        vim.keymap.set('n', '<leader>ds', builtin.lsp_document_symbols, { desc = 'Document symbols' })
        vim.keymap.set('n', '<leader>dw', builtin.lsp_workspace_symbols, { desc = 'Workspace symbols' })
        vim.keymap.set('n', '<leader>dd', builtin.diagnostics, { desc = 'Diagnostics' })
    end
}
