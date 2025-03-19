local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

local empty_response = {}

---@param _err lsp.ResponseError
---@param result razor.CSharpPullDiagnosticParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    local virtual_document = documentstore.get_virtual_document(
        result.identifier.textDocumentIdentifier.uri,
        razor.language_kinds.csharp,
        result.identifier.version
    )
    if not virtual_document then
        return empty_response
    end

    ---@type lsp.DocumentDiagnosticParams
    local diagnostic_params = {
        textDocument = {
            uri = virtual_document.uri,
        },
    }

    ---@type lsp.Diagnostic[]
    local diagnostic_response =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_diagnostic, diagnostic_params)
    if not diagnostic_response then
        return empty_response
    end

    return diagnostic_response
end
