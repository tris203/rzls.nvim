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

    ---@type lsp.DocumentColorParams
    local document_color_params = {
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
        },
    }

    local document_color_response, request_err =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_documentColor, document_color_params)

    if request_err then
        return nil, request_err
    end

    return document_color_response
end
