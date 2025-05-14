local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.CodeActionParams
---@return (lsp.Command | lsp.CodeAction)[] | nil
return function(params)
    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)

    if not rvd then
        return
    end

    local code_action, code_action_err = rvd:lsp_request(vim.lsp.protocol.Methods.textDocument_codeAction, params)

    if code_action_err then
        vim.notify("Error requesting code action: " .. code_action_err.message, vim.log.levels.ERROR, {
            title = "rzls",
        })
        return
    end

    return code_action
end
