local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@type number[]
local empty_response = {}

---@param ranges lsp.Range[]
---@return lsp.Range
local function reduce_ranges(ranges)
    local min_start = ranges[1].start
    local max_end = ranges[1]["end"]

    for _, range in ipairs(ranges) do
        if
            range.start.line < min_start.line
            or (range.start.line == min_start.line and range.start.character < min_start.character)
        then
            min_start = range.start
        end

        if
            range["end"].line > max_end.line
            or (range["end"].line == max_end.line and range["end"].character > max_end.character)
        then
            max_end = range["end"]
        end
    end

    return { start = min_start, ["end"] = max_end }
end

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

    if not vd or result.ranges == nil or #result.ranges == 0 then
        return { tokens = empty_response, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
    end

    ---@type lsp.SemanticTokens?
    local tokens, err = vd:lsp_request(vim.lsp.protocol.Methods.textDocument_semanticTokens_range, {
        textDocument = {
            uri = vd.uri,
        },
        range = reduce_ranges(result.ranges),
        correlationId = result.correlationId,
    })

    if not tokens or err then
        return { tokens = empty_response, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
    end
    return { tokens = tokens.data, hostDocumentSyncVersion = result.requiredHostDocumentVersion }, nil
end
