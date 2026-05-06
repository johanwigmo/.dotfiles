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
-- Wiki-link follow (gd)
-------------------------------------------------------------------------------

local function follow_link()
    if not ensure_vault() then return end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

    -- Find [[...]] surrounding cursor
    local link
    local s = 1
    while true do
        local open_start, open_end = line:find("%[%[", s)
        if not open_start then break end
        local close_start, close_end = line:find("%]%]", open_end + 1)
        if not close_start then break end

        if col >= open_start and col <= close_end then
            link = line:sub(open_end + 1, close_start - 1)
            break
        end
        s = close_end + 1
    end

    if not link then
        vim.notify("notes: no [[wiki-link]] under cursor", vim.log.levels.WARN)
        return
    end

    -- Strip heading/alias: [[file#heading|alias]] → file
    link = link:gsub("#.*$", ""):gsub("|.*$", "")

    -- Search vault for a matching .md file
    local target = link .. ".md"
    local found = vim.fn.globpath(vault, "**/" .. target, false, true)

    if #found > 0 then
        vim.cmd("edit " .. vim.fn.fnameescape(found[1]))
    else
        -- Offer to create in _inbox/
        local answer = vim.fn.input(string.format("'%s' not found. Create in _inbox/? (y/n) ", link))
        if answer == "y" then
            local path = vault .. "_inbox/" .. target
            vim.fn.mkdir(vim.fs.dirname(path), "p")
            vim.cmd("edit " .. vim.fn.fnameescape(path))
        end
    end
end

-------------------------------------------------------------------------------
-- Wiki-link completion (nvim-cmp source)
-------------------------------------------------------------------------------

local note_cache = {}
local cache_time = 0
local cache_ttl = 30 -- seconds

local function scan_notes()
    local now = os.time()
    if now - cache_time < cache_ttl and #note_cache > 0 then
        return note_cache
    end

    local results = {}
    local files = vim.fn.globpath(vault, "**/*.md", false, true)
    for _, file in ipairs(files) do
        local rel = file:sub(#vault + 1)
        local name = rel:gsub("%.md$", "")
        -- Use just the filename (no path) as the label, full relative path as detail
        local basename = vim.fs.basename(rel):gsub("%.md$", "")
        table.insert(results, {
            label = basename,
            insertText = basename,
            detail = name,
            kind = 18, -- Reference
        })
    end

    note_cache = results
    cache_time = now
    return results
end

local function register_cmp_source()
    local ok, cmp = pcall(require, "cmp")
    if not ok then return end

    local source = {}

    function source:is_available()
        local bufpath = vim.api.nvim_buf_get_name(0)
        return vault ~= "" and vim.startswith(bufpath, vault)
    end

    function source:get_trigger_characters()
        return { "[" }
    end

    function source:complete(request, callback)
        local line = request.context.cursor_before_line
        -- Only trigger inside [[
        if not line:match("%[%[[^%]]*$") then
            callback({ items = {}, isIncomplete = false })
            return
        end
        callback({ items = scan_notes(), isIncomplete = false })
    end

    cmp.register_source("wiki_links", source)

    -- Add to cmp sources for markdown files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            local bufpath = vim.api.nvim_buf_get_name(0)
            if vault == "" or not vim.startswith(bufpath, vault) then return end

            local config = cmp.get_config()
            local sources = config.sources or {}

            -- Check if already added
            for _, s in ipairs(sources) do
                if s.name == "wiki_links" then return end
            end

            table.insert(sources, 1, { name = "wiki_links", keyword_length = 1 })
            cmp.setup.buffer({ sources = sources })
        end,
    })
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
    -- Dependencies: telescope (for :NewNote), nvim-cmp (for [[wiki-link completion)
    local deps = { ["telescope.pickers"] = "telescope.nvim", ["cmp"] = "nvim-cmp" }
    for mod, name in pairs(deps) do
        if not pcall(require, mod) then
            vim.notify("notes: optional dependency " .. name .. " not found, some features disabled", vim.log.levels.WARN)
        end
    end

    -- Commands
    vim.api.nvim_create_user_command("Today",     function() open_daily(0) end,  {})
    vim.api.nvim_create_user_command("Yesterday",  function() open_daily(-1) end, {})
    vim.api.nvim_create_user_command("Tomorrow",  function() open_daily(1) end, {})
    vim.api.nvim_create_user_command("Weekly",     open_weekly,  {})
    vim.api.nvim_create_user_command("Monthly",    open_monthly, {})
    vim.api.nvim_create_user_command("NewNote",    new_note,     {})

    vim.api.nvim_create_user_command("Inbox",   function() open_todo_file("inbox") end,   {})
    vim.api.nvim_create_user_command("Waiting", function() open_todo_file("waiting") end, {})

    -- Keymaps (leader-o namespace, matching your old setup)
    vim.keymap.set("n", "<leader>ot", function() open_daily(0) end,  { desc = "Today's note" })
    vim.keymap.set("n", "<leader>oy", function() open_daily(-1) end, { desc = "Yesterday's note" })
    vim.keymap.set("n", "<leader>ow", open_weekly,  { desc = "Weekly note" })
    vim.keymap.set("n", "<leader>om", open_monthly, { desc = "Monthly note" })
    vim.keymap.set("n", "<leader>on", new_note,     { desc = "New note from template" })

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

                -- Buffer-local gd to follow wiki-links
                vim.keymap.set("n", "gd", follow_link, {
                    buffer = true,
                    desc = "Follow [[wiki-link]]",
                })
            end,
        })
    end

    -- Register wiki-link completion source
    register_cmp_source()
end

-------------------------------------------------------------------------------
-- Bootstrap: run setup on VeryLazy, return empty spec for lazy.nvim
--
-- Dependencies (declare these in your plugin specs):
--   nvim-telescope/telescope.nvim  — :NewNote template picker
--   hrsh7th/nvim-cmp               — [[wiki-link]] completion
-------------------------------------------------------------------------------

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = M.setup,
})

return {}
