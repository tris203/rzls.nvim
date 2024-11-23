local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@class rzls.razorResolveCodeActionParams;
---@field hostDocumentVersion integer
---@field identifier lsp.TextDocumentIdentifier
---@field languageKind razor.LanguageKind
---@field codeAction lsp.CodeAction

local empty_response = {}

---@param err lsp.ResponseError
---@param result rzls.razorResolveCodeActionParams
---@param _ctx lsp.HandlerContext
---@param _config table
---@return lsp.CodeAction | lsp.CodeAction[] | nil
---@return lsp.ResponseError | nil
return function(err, result, _ctx, _config)
    assert(not err, vim.inspect(err))

    local virtual_document =
        documentstore.get_virtual_document(result.identifier.uri, result.languageKind, result.hostDocumentVersion)

    -- VSCode is only handling C# code actions
    if not virtual_document or result.languageKind ~= razor.language_kinds.csharp then
        return empty_response
    end

    local code_action_resolve_response, code_action_resolve_err =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.codeAction_resolve, result.codeAction)

    if code_action_resolve_err then
        return nil, code_action_resolve_err
    end

    return code_action_resolve_response
end
