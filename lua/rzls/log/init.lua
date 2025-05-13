local _buffers = {}

---@class rzls.Logger
---@field rzls string
---@field rzlsnvim string
---@field aftershave string

---@type rzls.Logger
---@diagnostic disable-next-line: missing-fields
local Logger = {
    _buffers = _buffers,
}

local function format_message(message)
    return string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), message)
end

setmetatable(Logger, {
    __index = function(self, k)
        if self._buffers[k] then
            return self._buffers[k]._items or {}
        end
        return {}
    end,
    __newindex = function(self, k, v)
        if type(v) == "string" then
            if not self._buffers[k] then
                self._buffers[k] = vim.ringbuf(150)
                self._buffers[k]:push(format_message("New Log Initialized"))
            end
            self._buffers[k]:push(format_message(v))
        else
            error("Unsupported type for log value")
        end
    end,
    __call = function(_, _)
        local data = {}
        for k, v in pairs(_buffers) do
            data[k] = v._items
        end
        return next, data, nil
    end,
})

return Logger
