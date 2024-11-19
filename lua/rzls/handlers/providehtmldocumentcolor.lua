local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local empty_response = {}

---@class rzls.provideHtmlDocumentColorParams
---@field textDocument lsp.TextDocumentIdentifier
---@field _razor_hostDocumentVersion integer

---@param err lsp.ResponseError
---@param result rzls.provideHtmlDocumentColorParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(err, result, _ctx, _config)
    assert(not err, vim.inspect(err))
    local virtual_document = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.html,
        result._razor_hostDocumentVersion
    )
    if not virtual_document then
        Log.rzls = "razor/provideHtmlDocumentColor: virtual document not found"
        return empty_response
    end
    local virtual_client = virtual_document:get_lsp_client()
    if not virtual_client then
        Log.rzls = "razor/provideHtmlDocumentColor: HTML LSP client not attached to virtual document"
        return empty_response
    end
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
