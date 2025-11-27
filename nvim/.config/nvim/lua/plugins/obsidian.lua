return {
    "epwalsh/obsidian.nvim", 
    version = "*",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
        "nvim-telescope/telescope.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
        local vault = vim.fn.expand(os.getenv("NOTES_ROOT"))

        local function get_env_path(env_var)
            local p = os.getenv(env_var)
            if not p or p == "" then return nil end
            return p
        end

        return {
            workspaces = {
                {
                    name = "Wigmo",
                    path = vault,
                }
            },

            disable_frontmatter = true,
            prefer_wiki_links = true,
            ui = { enable = false },

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

            weekly_notes = {
                folder = get_env_path("NOTES_WEEKLY"),
                date_format = "%Y/%Y-W%V", 
                template = "WeeklyNote.md"
            },

            monthly_notes = {
                folder = get_env_path("NOTES_MONTHLY"),
                date_format = "%Y/%Y-%m", 
                template = "MonthlyNote.md"
            },

            completion = {
                nvim_cmp = true,
                min_chars = 2,
            },

            mappings = {
                ["gf"] = {
                    action = function ()
                        return require("obsidian").util.gf_passthrough()
                    end,
                    opts = { noremap = false, expr = true, buffer = true },
                },
            },
        }
    end,

    config = function(_, opts)
        require("obsidian").setup(opts)

        vim.keymap.set("n", "<leader>on", ":ObsidianNew ", { desc = "New note" })
        vim.keymap.set("n", "<leader>ot", ":ObsidianToday<CR>", { desc = "Today's note" })
        vim.keymap.set("n", "<leader>oy", ":ObsidianYesterday<CR>", { desc = "Yesterday's note" })
        vim.keymap.set("n", "<leader>ow", ":ObsidianWeekly<CR>", { desc = "Weekly note" })
        vim.keymap.set("n", "<leader>om", ":ObsidianMonthly<CR>", { desc = "Monthly note" })

        vim.keymap.set("n", "<leader>os", ":ObsidianSearch<CR>", { desc = "Search notes" })
        vim.keymap.set("n", "<leader>oq", ":ObsidianQuickSwitch<CR>", { desc = "Quick switch" })
        vim.keymap.set("n", "<leader>ob", ":ObsidianBacklinks<CR>", { desc = "Show backlinks" })
        vim.keymap.set("n", "<leader>oi", ":ObsidianTemplate<CR>", { desc = "Insert template" })

        vim.keymap.set("v", "<leader>ol", ":ObsidianLink<CR>", { desc = "Link selection" })
    end,
}
