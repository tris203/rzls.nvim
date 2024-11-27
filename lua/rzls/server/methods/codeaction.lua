local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.CodeActionParams
---@return lsp.CodeAction[] | lsp.Command | nil
return function(params)
    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    if not rvd then
        return
    end
    local code_actions, err = rvd:lsp_request(vim.lsp.protocol.Methods.textDocument_codeAction, params)
    if err then
        return
    end

    return code_actions
end
