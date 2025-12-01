local function get_env_path(env_var)
    local p = os.getenv(env_var)
    if not p or p == "" then return nil end
    return p
end

return {
    "obsidian-nvim/obsidian.nvim", 
    version = "*",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
        "hrsh7th/nvim-cmp",
        "nvim-telescope/telescope.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
        local vault = vim.fn.expand(os.getenv("NOTES_ROOT"))

        if vault == ""or vim.fn.isdirectory(vault) == 0 then 
            return {}
        end

        return {
            workspaces = {
                {
                    name = "Wigmo",
                    path = vault,
                }
            },

            frontmatter = {
                enabled = false
            },            

            prefer_wiki_links = true,
            ui = { enable = false },

            legacy_commands = false,

            notes_subdir = get_env_path("NOTES_SUBDIR"),

            templates = {
                folder = get_env_path("NOTES_TEMPLATES"),
                date_format = "%Y-%m-%d", 
                time_format = "%H:%M",
            },

            daily_notes = {
                folder = get_env_path("NOTES_DAILY"),
                date_format = "%Y/%m %b/%Y-%m-%d", 
                template = "DailyNote.md"
            },

            completion = {
                nvim_cmp = true,
                min_chars = 2,
            },
        }
    end,

    config = function(_, opts)
        if next(opts) == nil then 
            return
        end

        local obsidian = require("obsidian")
        obsidian.setup(opts)

        -- Disable swap files for Obsidian vault
        local vault_path = vim.fn.expand(vim.env.NOTES_ROOT)
        if vault_path ~= "" then 
            vim.api.nvim_create_autocmd("BufEnter", {
                pattern = vault_path .. "/*",
                callback = function()
                    vim.opt_local.swapfile = false
                    vim.opt_local.backup= false
                    vim.opt_local.writebackup = false
                end,
            })
        end

        -- Markdown-specific keymaps
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "markdown", 
            callback = function()

                vim.keymap.set("n", "gf", function()
                    if obsidian.util.cursor_on_markdown_link() then 
                        return "<cmd>Obsidian follow<CR>"
                    else 
                        return "gf"
                    end
                end, { buffer = true, expr = true, noremap = false})
            end,
        })

        -- Global Obsidian keymaps
        vim.keymap.set("n", "<leader>on", ":Obsidian new ", { desc = "New note" })
        vim.keymap.set("n", "<leader>ot", ":Obsidian today<CR>", { desc = "Today's note" })
        vim.keymap.set("n", "<leader>oy", ":Obsidian yesterday<CR>", { desc = "Yesterday's note" })

        -- Custoom weekly note creation
        vim.keymap.set("n", "<leader>ow", function()
            local vault_root = vim.fn.expand(vim.env.NOTES_ROOT)
            local weekly_folder = vim.env.NOTES_WEEKLY
            local template = "WeeklyReview.md"
            local date = os.date("%Y/%Y-W%V")
            local filename = string.format("%s/%s/%s.md", vault_root, weekly_folder, date)

            vim.fn.mkdir(vim.fs.dirname(filename), "p")
            vim.cmd("edit " .. vim.fn.fnameescape(filename))

            if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then 
                vim.cmd("Obsidian template " .. template)
            end
        end, { desc = "Weekly note" })

        -- Custom month note creation
        vim.keymap.set("n", "<leader>om", function()
            local vault_root = vim.fn.expand(vim.env.NOTES_ROOT)
            local monthly_folder = vim.env.NOTES_MONTHLY
            local template = "MonthlyReview.md"
            local date = os.date("%Y/%Y-%m")
            local filename = string.format("%s/%s/%s.md", vault_root, weekly_folder, date)

            vim.fn.mkdir(vim.fs.dirname(filename), "p")
            vim.cmd("edit " .. vim.fn.fnameescape(filename))

            if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then 
                vim.cmd("Obsidian template " .. template)
            end
        end, { desc = "Monthly note" })

        vim.keymap.set("n", "<leader>os", ":Obsidian search<CR>", { desc = "Search notes" })
        vim.keymap.set("n", "<leader>oq", ":Obsidian quick_switch<CR>", { desc = "Quick switch" })
        vim.keymap.set("n", "<leader>ob", ":Obsidian backlinks<CR>", { desc = "Show backlinks" })
        vim.keymap.set("n", "<leader>oi", ":Obsidian template<CR>", { desc = "Insert template" })

        vim.keymap.set("v", "<leader>ol", ":Obsidian link<CR>", { desc = "Link selection" })
        vim.keymap.set("n", "<leader>ol", ":Obsidian link_new<CR>", { desc = "Link to note" })
    end,
}
