-- Format on save. swiftformat is optional per-machine (lands in the
-- Brewfile in Phase 4); the function form keeps other machines quiet
-- instead of erroring on every save.
return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
        formatters_by_ft = {
            swift = function(bufnr)
                if require("conform").get_formatter_info("swiftformat", bufnr).available then
                    return { "swiftformat" }
                end
                return {}
            end,
        },
        format_on_save = {
            lsp_format = "fallback",
            timeout_ms = 500,
        },
    },
}
