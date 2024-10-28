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

return M
