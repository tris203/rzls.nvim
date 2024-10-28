local M = {}

---@param f function
function M.run(f, callback)
    local thread = coroutine.create(f)

    local function step(...)
        local stat, ret = coroutine.resume(thread, ...)
        assert(stat, "stat was null")
        assert(ret, "ret was null")

        if coroutine.status(thread) == "dead" then
            (callback or function() end)(ret)
        else
            ret(step)
        end
    end

    step()
end

return M
