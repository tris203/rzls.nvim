local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

local empty_response = {}

---@param _err lsp.ResponseError
---@param result lsp.DocumentDiagnosticParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    local virtual_document =
        documentstore.get_virtual_document(result.textDocument.uri, razor.language_kinds.csharp, "any")
    assert(virtual_document, "csharp document was not found")

    ---@type lsp.DocumentDiagnosticParams
    local diagnostic_params = vim.tbl_deep_extend("force", result, {
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
        },
    })

    ---@type lsp.Diagnostic[]
    local diagnostic_response =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_diagnostic, diagnostic_params)
    if not diagnostic_response then
        return empty_response
    end

    return diagnostic_response
end
