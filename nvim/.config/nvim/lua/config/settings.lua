vim.wo.number = true
vim.wo.relativenumber = true

vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

-- === Searching ===
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.showmatch = true

-- === Auto-reload files if changed outside of nvim ===
vim.opt.autoread = true

-- Check if file changed when regaining focus, entering buffer, or idle
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold", "CursorHoldI"}, {
  command = "checktime"
})

-- Notify when a file was reloaded
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None"
})

-- === Autosave only in specific directories ===
local autosave_dirs = {
    vim.env.NOTES_ROOT,
    vim.env.TODO_ROOT,
}

vim.api.nvim_create_autocmd({"InsertLeave", "FocusLost"}, {
    callback = function()
        local cwd = vim.fn.getcwd()

        for _, dir in ipairs(autosave_dirs) do
            if vim.startswith(cwd, dir) then
                vim.cmd("silent! wall")
                return
            end
        end
    end,
})
