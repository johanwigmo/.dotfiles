-- bulletmark.nvim — BulletMark task syntax in the vault (spec 2.0.0)
-- Published: https://github.com/johanwigmo/bulletmark.nvim
--
-- lazy = false on purpose: :BulletMark search must exist in every buffer;
-- scoping to the vault happens at attach time (activation: detect + roots).
-- When a dev checkout exists, use it (this machine); otherwise lazy clones
-- the published repo — same spec on every machine, pinned via lazy-lock.
local dev_dir = vim.fs.normalize("~/Developer/BulletMark/bulletmark.nvim")
local use_dev = vim.fn.isdirectory(dev_dir) == 1

local plugin
if use_dev then
    plugin = { dir = dev_dir, name = "bulletmark.nvim" }
else
    plugin = { "johanwigmo/bulletmark.nvim", name = "bulletmark.nvim" }
end

plugin.lazy = false
plugin.opts = {
    activate = "detect",
    roots = vim.env.NOTES and { vim.env.NOTES } or {},
    search_paths = vim.env.NOTES and { vim.env.NOTES } or {},
    -- + / @ candidates skip archived and done files; search stays unscoped
    completion_paths_exclude = { "archive", "done-" },
}

return plugin
