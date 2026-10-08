-- sourcekit-lsp via native vim.lsp.config (0.12) — no lspconfig, no mason.
-- Guarded on `xcrun --find sourcekit-lsp` so machines without Xcode/CLT
-- never error at startup: the check only runs when a Swift-family file opens.
--
-- App-target types (the .xcodeproj half) need index-while-building data:
-- run one CLI `xcodebuild` build per checkout/machine or go-to-definition
-- and app-target completion go stale. xcode-build-server + buildServer.json
-- feed sourcekit from those build logs (per-machine, never synced).

local group = vim.api.nvim_create_augroup("user.lsp", { clear = true })

local sourcekit = {
    filetypes = { "swift", "objc", "objcpp", "c", "cpp" },
    configured = false,
}

local function configure_sourcekit()
    if sourcekit.configured then return end
    sourcekit.configured = true

    local out = vim.system({ "/usr/bin/xcrun", "--find", "sourcekit-lsp" }):wait()
    if out.code ~= 0 or not (out.stdout or ""):find("sourcekit") then
        vim.notify("lsp: sourcekit-lsp not found — install Xcode or the CLT", vim.log.levels.WARN)
        return
    end

    -- blink.cmp advertises snippet/label_details support to the server;
    -- without it sourcekit sends plain-text items and Swift completions
    -- lose their parameter placeholders.
    local ok, blink = pcall(require, "blink.cmp")

    vim.lsp.config("sourcekit", {
        cmd = { "/usr/bin/xcrun", "sourcekit-lsp" },
        filetypes = sourcekit.filetypes,
        root_markers = { "buildServer.json", "Package.swift", ".git" },
        capabilities = ok and blink.get_lsp_capabilities() or nil,
    })
    vim.lsp.enable("sourcekit") -- doautoall covers the buffer that triggered this
end

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = sourcekit.filetypes,
    callback = configure_sourcekit,
})

-- nvim 0.12 defaults already map grr, gri, grn, gra, grt, gO, <C-S>,
-- [d, ]d, <C-W>d — these are the remaining muscle-memory mappings.
vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
        local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
        end

        map("gd", vim.lsp.buf.definition, "LSP definition")
        map("gr", vim.lsp.buf.references, "LSP references")
        map("gi", vim.lsp.buf.implementation, "LSP implementation")
        map("K", vim.lsp.buf.hover, "LSP hover")
        map("<leader>rn", vim.lsp.buf.rename, "LSP rename")
        map("<leader>ca", vim.lsp.buf.code_action, "LSP code action")
        map("<leader>d", vim.diagnostic.open_float, "Diagnostic at cursor")
    end,
})

return {}
