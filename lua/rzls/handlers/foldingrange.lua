local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@class rzls.foldingRangeParams
---@field textDocument lsp.TextDocumentIdentifier
---@field hostDocumentVersion integer

local empty_response = {}

---@param _err lsp.ResponseError
---@param result rzls.foldingRangeParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    local cvd = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.csharp,
        result.hostDocumentVersion
    )
    local hvd = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.html,
        result.hostDocumentVersion
    )

    local csharp_folds = empty_response
    ---@type lsp.ResponseError|nil
    local cerr
    local html_folds = empty_response
    ---@type lsp.ResponseError|nil
    local herr
    if cvd then
        ---@type lsp.FoldingRange[]
        csharp_folds, cerr = cvd:lsp_request(
            vim.lsp.protocol.Methods.textDocument_foldingRange,
            { textDocument = vim.lsp.util.make_text_document_params(cvd.buf) },
            cvd.buf
        )
    end
    if hvd then
        ---@type lsp.FoldingRange[]
        html_folds, herr = hvd:lsp_request(
            vim.lsp.protocol.Methods.textDocument_foldingRange,
            { textDocument = vim.lsp.util.make_text_document_params(hvd.buf) },
            hvd.buf
        )
    end

    ---NOTE: VsCode remaps the start and end characters back to the begining of the row, but we dont seem to need to

    return {
        csharpRanges = not cerr and csharp_folds or empty_response,
        htmlRanges = not herr and html_folds or empty_response,
    }
end
