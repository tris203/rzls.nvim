local M = {}

--- Returns the client for the LSP server with the given name
---@param name any
---@return vim.lsp.Client | nil
function M.get_client(name)
    local client = vim.lsp.get_clients({ name = name })
    if not client or #client ~= 1 then
        return nil
    end
    return client[1]
end

---@param cursor_pos integer[]
---@return lsp.Position
function M.cursor_to_lsp_position(cursor_pos)
    return {
        line = cursor_pos[1] - 1,
        character = cursor_pos[2],
    }
end

return M
