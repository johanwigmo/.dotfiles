local paths = {
    subdir = "00 Meta/01 Inbox",
    templates = "00 Meta/03 Templates",
    daily = "00 Meta/02 Journal/02.01 Daily",
    weekly = "00 Meta/02 Journal/02.02 Weekly",
    monthly = "00 Meta/02 Journal/02.03 Monthly"
}

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

            frontmatter = { enabled = false }, 
            prefer_wiki_links = true,
            ui = { enable = false },
            statusline = { enabled = false }, 
            footer = { enabled = false }, 
            legacy_commands = false,

            templates = {
                folder = paths.templates,
                date_format = "%Y-%m-%d", 
                time_format = "%H:%M",
            },

            daily_notes = {
                folder = paths.daily,
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
        if next(opts) == nil then return end

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

        -- Global Obsidian keymaps
        vim.keymap.set("n", "<leader>on", ":Obsidian new ", { desc = "New note" })
        --
        -- Won't do custom template thingy, but should already be created
        vim.keymap.set("n", "<leader>oy", ":Obsidian yesterday<CR>", { desc = "Yesterday's note" }) 

        -- Custom daily note (adjust template when created from desktop)
        vim.keymap.set("n", "<leader>ot", function()
            vim.cmd("Obsidian today")

            -- wait for template
            vim.defer_fn(function()
                local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
                if first_line and first_line:match("^#") then
                    local date = os.date("%Y-%m-%d")
                    vim.api.nvim_buf_set_lines(0, 0, 1, false, {"# Daily Notes - " .. date})
                end
            end, 100)
        end, { desc = "Today's note" })

        -- Custoom weekly note creation
        vim.keymap.set("n", "<leader>ow", function()
            local vault_root = vim.fn.expand(vim.env.NOTES_ROOT)
            local date = os.date("%Y/%Y-W%V")
            local filename = string.format("%s/%s/%s.md", vault_root, paths.weekly, date)

            vim.fn.mkdir(vim.fs.dirname(filename), "p")
            vim.cmd("edit " .. vim.fn.fnameescape(filename))

            if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then 
                vim.cmd("Obsidian template WeeklyReview.md")

                vim.defer_fn(function()
                    local week  = os.date("W%V")
                    vim.api.nvim_buf_set_lines(0, 0, 1, false, {"# Weekly Review " .. week})
                end, 100)
            end
        end, { desc = "Weekly note" })

        -- Custom month note creation
        vim.keymap.set("n", "<leader>om", function()
            local vault_root = vim.fn.expand(vim.env.NOTES_ROOT)
            local date = os.date("%Y/%Y-%m")
            local filename = string.format("%s/%s/%s.md", vault_root, paths.monthly, date)

            vim.fn.mkdir(vim.fs.dirname(filename), "p")
            vim.cmd("edit " .. vim.fn.fnameescape(filename))

            if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then 
                vim.cmd("Obsidian template MonthlyReview.md")

                vim.defer_fn(function()
                    local month  = os.date("%B %Y")
                    vim.api.nvim_buf_set_lines(0, 0, 1, false, {"# Monthly Review - " .. month})
                end, 100)
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
