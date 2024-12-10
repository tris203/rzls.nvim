local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

-- HACK: neovim does not deserialize `null`s and rzls expects an explicit `null` value
-- in the `data.delegatedDocumentUri` field of a code action.
-- This issue is being tracker here: https://github.com/neovim/neovim/issues/31368
-- We can remove code actions from aftershave when this issue is resolved.
local code_action_required_fields = {
    data = {
        delegatedDocumentUri = vim.NIL,
    },
}

---@param code_action lsp.CodeAction
---@return lsp.CodeAction | nil
return function(code_action)
    ---@diagnostic disable-next-line: undefined-field
    local rvd = documentstore.get_virtual_document(code_action.data.TextDocument.uri, razor.language_kinds.razor)

    if not rvd then
        return
    end

    local params = vim.tbl_deep_extend("keep", code_action, code_action_required_fields)
    local resolve, resolve_err = rvd:lsp_request(vim.lsp.protocol.Methods.codeAction_resolve, params)

    if resolve_err then
        vim.notify("Error resolving code action: " .. resolve_err.message, vim.log.levels.ERROR, {
            title = "rzls",
        })
        return
    end

    return resolve
end
