local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---This is a workaround for a ser/de issue in Neovim
---https://github.com/neovim/neovim/issues/31368
---When this is resolved we can remove this method from aftershave
local missing_data = {
    data = {
        delegatedDocumentUri = vim.NIL,
    },
}

---@param params lsp.CodeAction
---@return lsp.CodeAction | {}
return function(params)
    params = vim.tbl_deep_extend("keep", params, missing_data)
    ---@diagnostic disable-next-line: undefined-field
    local rvd = documentstore.get_virtual_document(params.data.TextDocument.uri, razor.language_kinds.razor)
    if not rvd then
        return {}
    end
    local resolved_action, err = rvd:lsp_request(vim.lsp.protocol.Methods.codeAction_resolve, params)
    if err then
        return {}
    end

    resolved_action = vim.tbl_deep_extend("force", resolved_action, missing_data)
    return resolved_action
end
