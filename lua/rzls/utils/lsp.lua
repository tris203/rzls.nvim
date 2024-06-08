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

return M
