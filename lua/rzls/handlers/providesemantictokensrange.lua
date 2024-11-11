local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@type number[]
local empty_response = {}

---@param _err lsp.ResponseError
---@param result razor.ProvideSemanticTokensParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    local vd = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.csharp,
        result.requiredHostDocumentVersion
    )
    if not vd then
        return { tokens = empty_response, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
    end

    local roslyn_client = vd:get_lsp_client()
    if not roslyn_client then
        return { tokens = empty_response, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
    end

    local tokens = roslyn_client.request_sync("textDocument/semanticTokens/range", {
        textDocument = {
            uri = vim.uri_from_bufnr(vd.buf),
        },
        range = result.ranges[1],
        correlationId = result.correlationId,
    }, nil, vd.buf)

    if not tokens or not tokens.result or not tokens.result.data then
        return nil, { tokens = nil, hostDocumentSyncVersion = result.requiredHostDocumentVersion }
    end
    return { tokens = tokens.result.data, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
end
