---@class rzls.RefreshQueues
---@field diagnostics rzls.RefreshQueue

---@class rzls.RefreshQueue
---@field add fun(bufnr: integer): nil --- add a buffer to the refresh queue
---@field __refresh fun(self: table<number, boolean>): nil --- refresh all buffers in the queue

--- @alias rzls.RefreshFunc fun(self: table<number, boolean>): nil

local refresh_queue = {}
local documentstore = require("rzls.documentstore")
local Log = require("rzls.log")

---@credit to @Willothy
---Debounces calls to a function, and ensures it only runs once per delay
---even if called repeatedly.
---@param fn fun(...: any)
---@param delay integer
local function debounce(fn, delay)
    local running = false
    local timer = assert(vim.uv.new_timer())

    -- Ugly hack to ensure timer is closed when the function is garbage collected
    -- unfortunate but necessary to avoid creating a new timer for each call.
    --
    -- In LuaJIT, only userdata can have finalizers. `newproxy` creates an opaque userdata
    -- which we can attach a finalizer to and use as a "canary."
    local proxy = newproxy(true)
    getmetatable(proxy).__gc = function()
        if not timer:is_closing() then
            timer:close()
        end
    end

    return function(...)
        local _ = proxy
        if running then
            return
        end
        running = true
        local args = { ... }
        timer:start(
            delay,
            0,
            vim.schedule_wrap(function()
                fn(unpack(args))
                running = false
            end)
        )
    end
end

---Initializes a new refresh queue.
---@param refresh_func rzls.RefreshFunc
---@return table
function refresh_queue:new(refresh_func, delay)
    local debounced = debounce(refresh_func, delay)
    return setmetatable({
        add = function(bufnr)
            if bufnr and not self[bufnr] then
                self[bufnr] = true
            end
            debounced(self)
        end,
    }, self)
end

---@type rzls.RefreshFunc
local function refresh_diagnostics(self)
    for bufnr in pairs(self) do
        if type(bufnr) == "number" then
            if vim.api.nvim_buf_is_valid(bufnr) then
                Log.rzlsnvim = string.format("Refreshing diagnostics for buffer: %d", bufnr)
                vim.lsp.util._refresh(vim.lsp.protocol.Methods.textDocument_diagnostic, { bufnr = bufnr })
            end
            local ok, rvd = pcall(documentstore.get_razor_document_by_bufnr, bufnr)
            if ok then
                Log.rzlsnvim = string.format("Refreshing diagnostics for razor buffer: %d", rvd.buf)
                vim.lsp.util._refresh(vim.lsp.protocol.Methods.textDocument_diagnostic, { bufnr = rvd.buf })
            end
            self[bufnr] = nil
        end
    end
end

---@type rzls.RefreshQueues
local queue = {
    ---@diagnostic disable-next-line: assign-type-mismatch
    diagnostics = refresh_queue:new(refresh_diagnostics, 500),
}

return queue
