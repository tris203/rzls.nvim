local M = {}

--- Gets the line count of a virtual buffer
---@param buffnr integer
---@return integer
function M.get_virtual_lines_count(buffnr)
    local lines = vim.api.nvim_buf_line_count(buffnr)
    --NOTE: Remove version line
    lines = lines - 1
    return lines
end

return M
