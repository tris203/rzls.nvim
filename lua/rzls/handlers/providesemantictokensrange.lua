local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@type number[]
local empty_response = {}

---@param _err lsp.ResponseError
---@param result razor.ProvideSemanticTokensParams
---@param _ctx lsp.HandlerContext
---@param _config table
---@return razor.ProvideSemanticTokensResponse
---@return lsp.ResponseError?
return function(_err, result, _ctx, _config)
    local vd = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.csharp,
        result.requiredHostDocumentVersion
    )
    if not vd then
        return { tokens = empty_response, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
    end

    ---@type lsp.SemanticTokens?
    local tokens, err = vd:lsp_request(vim.lsp.protocol.Methods.textDocument_semanticTokens_range, {
        textDocument = {
            uri = vd.uri,
        },
        range = result.ranges[1],
        correlationId = result.correlationId,
    })

    if not tokens or err then
        return { tokens = empty_response, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
    end
    return { tokens = tokens.data, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
end
