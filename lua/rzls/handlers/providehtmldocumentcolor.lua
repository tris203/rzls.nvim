local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

local empty_response = {}

---@class rzls.provideHtmlDocumentColorParams
---@field textDocument lsp.TextDocumentIdentifier
---@field _razor_hostDocumentVersion integer

---@param _err lsp.ResponseError
---@param result rzls.provideHtmlDocumentColorParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    local virtual_document = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.html,
        result._razor_hostDocumentVersion
    )
    if not virtual_document then
        return empty_response
    end

    ---@type lsp.DocumentColorParams
    local document_color_params = {
        textDocument = {
            uri = virtual_document.uri,
        },
    }

    local document_color_response, request_err =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_documentColor, document_color_params)

    if request_err then
        return empty_response, nil
    end

    return document_color_response
end
