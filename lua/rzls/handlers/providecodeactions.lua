local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@class rzls.razorDelegatedCodeAction;
---@field hostDocumentVersion integer
---@field codeActionParams lsp.CodeActionParams
---@field languageKind razor.LanguageKind

local empty_response = {}

---@param err lsp.ResponseError
---@param result rzls.razorDelegatedCodeAction
---@param _ctx lsp.HandlerContext
---@param _config table
---@return lsp.CodeAction | lsp.CodeAction[] | nil
---@return lsp.ResponseError | nil
return function(err, result, _ctx, _config)
    assert(not err, vim.inspect(err))

    local virtual_document = documentstore.get_virtual_document(
        result.codeActionParams.textDocument.uri,
        result.languageKind,
        result.hostDocumentVersion
    )

    -- VSCode is only handling C# code actions
    if not virtual_document or result.languageKind ~= razor.language_kinds.csharp then
        return empty_response
    end

    local code_actions_params = vim.tbl_extend("force", result.codeActionParams, {
        textDocument = vim.lsp.util.make_text_document_params(virtual_document.buf),
    })

    local code_action_response, code_action_err =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_codeAction, code_actions_params)

    if code_action_err then
        return nil, code_action_err
    end

    return code_action_response
end
