local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.CodeAction
---@return lsp.CodeAction | nil
return function(params)
    local rvd = documentstore.get_virtual_document(params.data.TextDocument.uri, razor.language_kinds.razor)

    if not rvd then
        return
    end

    -- HACK: neovim does not deserialize `null`s and rzls expects an explicit `null` value
    -- in the `params.data.delegatedDocumentUri` field.
    params.data.delegatedDocumentUri = vim.NIL

    local resolve, resolve_err = rvd:lsp_request(vim.lsp.protocol.Methods.codeAction_resolve, params)

    if resolve_err then
        vim.notify("Error resolving code action: " .. resolve_err.message, vim.log.levels.ERROR, {
            title = "rzls",
        })
        return
    end

    return resolve
end
