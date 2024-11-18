local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local empty_response = {}

---@param _err lsp.ResponseError
---@param result lsp.DocumentDiagnosticParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    assert(not _err, vim.inspect(_err))
    local virtual_document =
        documentstore.get_virtual_document(result.textDocument.uri, razor.language_kinds.html, "any")
    assert(virtual_document, "html document was not found")
    local virtual_client = virtual_document:get_lsp_client()
    assert(virtual_client, "Could not find LSP client for virtual document")
    --@type lsp.DocumentColorParams
    local document_color_params = vim.tbl_deep_extend("force", result, {
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
        },
    })
    local document_color_response = virtual_client.request_sync(
        vim.lsp.protocol.Methods.textDocument_documentColor,
        document_color_params,
        nil,
        virtual_document.buf
    )
    if not document_color_response then
        return empty_response
    end

    if document_color_response.err then
        return nil, document_color_response.err
    end

    return document_color_response.result
end
