-- blink.cmp source: [[wiki-link]] completion for the notes vault.
-- Loaded by blink from lua/plugins/blink.lua (sources.providers.wiki_links).
-- Disabled outside $NOTES (blink filters it per-buffer).

local CACHE_TTL = 30 -- seconds

local Source = {}
Source.__index = Source

function Source.new()
    local self = setmetatable({}, Source)
    self.vault = vim.fn.expand(os.getenv("NOTES") or "")
    self.cache = {}
    self.cache_time = 0
    return self
end

function Source:enabled()
    local bufpath = vim.api.nvim_buf_get_name(0)
    return self.vault ~= "" and vim.startswith(bufpath, self.vault)
end

function Source:get_trigger_characters()
    return { "[" }
end

function Source:scan_notes()
    local now = os.time()
    if #self.cache > 0 and now - self.cache_time < CACHE_TTL then
        return self.cache
    end

    local results = {}
    local files = vim.fn.globpath(self.vault, "**/*.md", false, true)
    for _, file in ipairs(files) do
        local rel = file:sub(#self.vault + 1)
        table.insert(results, {
            label = vim.fs.basename(rel):gsub("%.md$", ""),
            insertText = vim.fs.basename(rel):gsub("%.md$", ""),
            detail = rel:gsub("%.md$", ""),
            kind = 18, -- Reference
        })
    end

    self.cache = results
    self.cache_time = now
    return results
end

function Source:get_completions(context, callback)
    local prefix = context.line:sub(1, context.cursor[2])

    -- Only offer notes inside an unclosed [[...]]
    if not prefix:match("%[%[[^%]]*$") then
        callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
        return
    end

    callback({
        items = self:scan_notes(),
        is_incomplete_backward = false,
        is_incomplete_forward = false,
    })
end

return Source
