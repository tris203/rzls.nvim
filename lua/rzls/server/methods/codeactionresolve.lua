local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")


---@param code_action lsp.CodeAction
---@return lsp.CodeAction | nil
return function(code_action)
    ---@diagnostic disable-next-line: undefined-field
    local rvd = documentstore.get_virtual_document(code_action.data.TextDocument.uri, razor.language_kinds.razor)

    if not rvd then
        return
    end

    local resolve, resolve_err = rvd:lsp_request(vim.lsp.protocol.Methods.codeAction_resolve, code_action)

    if resolve_err then
        vim.notify("Error resolving code action: " .. resolve_err.message, vim.log.levels.ERROR, {
            title = "rzls",
        })
        return
    end

    return resolve
end
