local M = {}

---@generic T
---@param val T
---@param message string?
---@return T
function M.debug(val, message)
    if true then
        local prefix = message and message .. ": " or ""
        vim.print(prefix .. vim.inspect(val))
    end
    return val
end

local eols = {
    dos = "\r\n",
    unix = "\n",
    mac = "\r",
}

---@param bufnr integer
function M.buffer_eol(bufnr)
    return eols[vim.bo[bufnr].fileformat]
end

function M.uuid()
    local random = math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))
    assert(random, "math.randomseed failed")
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return string.format("%x", v)
    end)
end

return M
