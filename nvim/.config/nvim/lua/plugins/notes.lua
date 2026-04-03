-- notes.nvim — lightweight replacement for obsidian.nvim
-- Drop into your lazy.nvim plugins/ directory or require from init.lua

local M = {}

local vault = vim.fn.expand(os.getenv("NOTES") or "")
local todo = vim.fn.expand(os.getenv("TODO") or "")

local templates_dir = "_meta/templates"

-- Template → default destination mapping
local template_destinations = {
    ["daily-note"]     = "journal/daily/{year}/{month}/",
    ["weekly-review"]  = "journal/weekly/{year}/",
    ["monthly-review"] = "journal/monthly/{year}/",
    ["people"]         = "entities/people/",
    ["organization"]   = "entities/organizations/",
    ["place"]          = "entities/places/",
    ["input"]          = "reference/inputs/",
}

-- Templates that should prompt for a subfolder
local prompt_subfolder = {
    ["people"] = true,
    ["organization"] = true,
    ["input"] = true,
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ensure_vault()
    if vault == "" or vim.fn.isdirectory(vault) == 0 then
        vim.notify("notes: $NOTES is not set or does not exist", vim.log.levels.ERROR)
        return false
    end
    return true
end

local function read_template(name)
    local path = vault .. templates_dir .. "/" .. name .. ".md"
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function fill_template(content, date)
    date = date or os.time()
    local replacements = {
        ["{date}"]      = os.date("%Y-%m-%d", date),
        ["{time}"]      = os.date("%H:%M", date),
        ["{year}"]      = os.date("%Y", date),
        ["{month}"]     = os.date("%m", date),
        ["{week}"]      = os.date("W%V", date),
        ["{month_name}"]= os.date("%B", date),
        ["{day_name}"]  = os.date("%A", date),
    }
    for token, value in pairs(replacements) do
        content = content:gsub(token, value)
    end
    return content
end

local function open_or_create(filepath, template_name, date)
    local dir = vim.fs.dirname(filepath)
    vim.fn.mkdir(dir, "p")

    local is_new = vim.fn.filereadable(filepath) == 0

    vim.cmd("edit " .. vim.fn.fnameescape(filepath))

    if is_new and template_name then
        local tmpl = read_template(template_name)
        if tmpl then
            local lines = vim.split(fill_template(tmpl, date), "\n", { plain = true })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        end
    end
end

local function month_slug(date)
    return os.date("%m", date) .. "-" .. os.date("%b", date):lower()
end

-------------------------------------------------------------------------------
-- Periodic notes
-------------------------------------------------------------------------------

local function open_daily(offset)
    if not ensure_vault() then return end
    local date = os.time() + (offset or 0) * 86400
    local path = string.format(
        "%sjournal/daily/%s/%s/%s.md",
        vault,
        os.date("%Y", date),
        month_slug(date),
        os.date("%Y-%m-%d", date)
    )
    open_or_create(path, "daily-note", date)
end

local function open_weekly()
    if not ensure_vault() then return end
    local date = os.time()
    local path = string.format(
        "%sjournal/weekly/%s/%s-w%s.md",
        vault,
        os.date("%Y", date),
        os.date("%Y", date),
        os.date("%V", date)
    )
    open_or_create(path, "weekly-review", date)
end

local function open_monthly()
    if not ensure_vault() then return end
    local date = os.time()
    local path = string.format(
        "%sjournal/monthly/%s/%s-%s.md",
        vault,
        os.date("%Y", date),
        os.date("%Y", date),
        os.date("%m", date)
    )
    open_or_create(path, "monthly-review", date)
end

-------------------------------------------------------------------------------
-- Template-based note creation via Telescope
-------------------------------------------------------------------------------

local function new_note()
    if not ensure_vault() then return end

    local tmpl_path = vault .. templates_dir
    if vim.fn.isdirectory(tmpl_path) == 0 then
        vim.notify("notes: templates directory not found: " .. tmpl_path, vim.log.levels.ERROR)
        return
    end

    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        vim.notify("notes: telescope.nvim is required for :NewNote", vim.log.levels.ERROR)
        return
    end
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Collect template files
    local templates = {}
    local handle = vim.loop.fs_scandir(tmpl_path)
    if handle then
        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if typ == "file" and name:match("%.md$") then
                table.insert(templates, (name:gsub("%.md$", "")))
            end
        end
    end
    table.sort(templates)

    pickers.new({}, {
        prompt_title = "New Note — pick template",
        finder = finders.new_table({ results = templates }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then return end

                local tmpl_name = selection[1]
                local dest = template_destinations[tmpl_name]
                local date = os.time()

                -- Resolve destination folder
                if dest then
                    dest = dest:gsub("{year}", os.date("%%Y", date))
                               :gsub("{month}", month_slug(date))
                else
                    dest = "_inbox/"
                end

                -- Prompt for subfolder if needed
                if prompt_subfolder[tmpl_name] then
                    local sub = vim.fn.input("Subfolder (blank for none): ")
                    if sub and sub ~= "" then
                        dest = dest .. sub .. "/"
                    end
                end

                -- Prompt for filename
                local name = vim.fn.input("Filename (kebab-case, no extension): ")
                if not name or name == "" then
                    vim.notify("notes: cancelled", vim.log.levels.INFO)
                    return
                end

                local filepath = vault .. dest .. name .. ".md"
                open_or_create(filepath, tmpl_name, date)
            end)
            return true
        end,
    }):find()
end

-------------------------------------------------------------------------------
-- Quick navigation
-------------------------------------------------------------------------------

local function open_todo_file(name)
    if todo == "" then
        vim.notify("notes: $TODO is not set", vim.log.levels.ERROR)
        return
    end
    local path = todo .. name .. ".md"
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------

function M.setup()
    -- Commands
    vim.api.nvim_create_user_command("Today",     function() open_daily(0) end,  {})
    vim.api.nvim_create_user_command("Yesterday",  function() open_daily(-1) end, {})
    vim.api.nvim_create_user_command("Weekly",     open_weekly,  {})
    vim.api.nvim_create_user_command("Monthly",    open_monthly, {})
    vim.api.nvim_create_user_command("NewNote",    new_note,     {})

    vim.api.nvim_create_user_command("Focus",   function() open_todo_file("focus") end,   {})
    vim.api.nvim_create_user_command("Inbox",   function() open_todo_file("inbox") end,   {})
    vim.api.nvim_create_user_command("Waiting", function() open_todo_file("waiting") end, {})

    -- Keymaps (leader-o namespace, matching your old setup)
    vim.keymap.set("n", "<leader>ot", function() open_daily(0) end,  { desc = "Today's note" })
    vim.keymap.set("n", "<leader>oy", function() open_daily(-1) end, { desc = "Yesterday's note" })
    vim.keymap.set("n", "<leader>ow", open_weekly,  { desc = "Weekly note" })
    vim.keymap.set("n", "<leader>om", open_monthly, { desc = "Monthly note" })
    vim.keymap.set("n", "<leader>on", new_note,     { desc = "New note from template" })

    vim.keymap.set("n", "<leader>of", function() open_todo_file("focus") end,   { desc = "Focus" })
    vim.keymap.set("n", "<leader>oi", function() open_todo_file("inbox") end,   { desc = "Inbox" })
    vim.keymap.set("n", "<leader>oa", function() open_todo_file("waiting") end, { desc = "Waiting" })

    -- Disable swap/backup inside the vault
    if vault ~= "" and vim.fn.isdirectory(vault) == 1 then
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = vault .. "*",
            callback = function()
                vim.opt_local.swapfile = false
                vim.opt_local.backup = false
                vim.opt_local.writebackup = false
            end,
        })
    end
end

-------------------------------------------------------------------------------
-- Lazy.nvim plugin spec (self-contained)
-------------------------------------------------------------------------------

return {
    name = "notes.nvim",
    dir = ".",                    -- or point to wherever you place this file
    lazy = true,
    event = "VeryLazy",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        M.setup()
    end,
}
