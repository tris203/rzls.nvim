---@class rzls.EventEmitter
---@field listeners (fun(...))[]
local EventEmitter = {}

EventEmitter.__index = EventEmitter

function EventEmitter:new()
    return setmetatable({
        listeners = {},
    }, self)
end

function EventEmitter:fire(...)
    local args = { ... }
    vim.schedule(function()
        for _, handler in ipairs(self.listeners) do
            handler(unpack(args))
        end
    end)
end

function EventEmitter:on(handler)
    table.insert(self.listeners, handler)

    return function()
        local handler_index = 0
        for index, cur_handler in ipairs(self.listeners) do
            if rawequal(cur_handler, handler) then
                handler_index = index
                break
            end
        end

        if handler_index > 0 then
            table.remove(self.listeners, handler_index)
        end
    end
end

return EventEmitter
