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

    local virtual_client = virtual_document:get_lsp_client()
    assert(virtual_client, "Could not find LSP client for virtual document")

    ---@type lsp.DocumentDiagnosticParams
    local diagnostic_params = vim.tbl_deep_extend("force", result, {
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
        },
    })

    local diagnostic_response = virtual_client.request_sync(
        vim.lsp.protocol.Methods.textDocument_diagnostic,
        diagnostic_params,
        nil,
        virtual_document.buf
    )
    if not diagnostic_response then
        return empty_response
    end

    if diagnostic_response.err then
        return nil, diagnostic_response.err
    end

    return diagnostic_response.result
end
