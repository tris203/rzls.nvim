local M = {}
---@module "nio"

---@class razor.LanguageQueryParams
---@field position nio.lsp.types.Position
---@field uri string

---@class razor.LanguageQueryResponse
---@field hostDocumentVersion integer
---@field kind razor.LanguageKind
---@field position nio.lsp.types.Position
---@field positionIndex integer

---@class razor.MapToDocumentRangesParams
---@field razorDocumentUri string
---@field kind razor.LanguageKind
---@field projectedRanges nio.lsp.types.Range[]

---@class razor.MapToDocumentRangesResponse
---@field hostDocumentVersion integer
---@field ranges nio.lsp.types.Range[]

---@class razor.ProvideSemanticTokensParams
---@field correlationId string
---@field textDocument nio.lsp.types.TextDocumentIdentifier
---@field ranges nio.lsp.types.Range[]
---@field requiredHostDocumentVersion integer

---@class razor.ProvideSemanticTokensResponse
---@field tokens integer[]
---@field hostDocumentSyncVersion integer

---@class razor.DelegatedCompletionRange
---@field tokens integer[]
---@field hostDocumentSyncVersion integer

---@class razor.DelegatedCompletionParams
---@field identifier { textDocumentIdentifier: nio.lsp.types.TextDocumentIdentifier, version: integer }
---@field projectedPosition nio.lsp.types.Position
---@field projectedKind razor.LanguageKind
---@field context nio.lsp.types.CompletionContext
---@field provisionalTextEdit nio.lsp.types.TextEdit
---@field shouldIncludeSnippets boolean

---@class razor.ProvideDynamicFileParams
---@field razorDocument nio.lsp.types.TextDocumentIdentifier

---@class razor.ProvideDynamicFileResponse
---@field csharpDocument nio.lsp.types.TextDocumentIdentifier|nil

---@enum razor.LanguageKind
M.language_kinds = {
    csharp = 1,
    html = 2,
    razor = 3,
}

---@enum razor.LSPClientName
M.lsp_names = {
    [M.language_kinds.html] = "html",
    [M.language_kinds.csharp] = "roslyn",
    [M.language_kinds.razor] = "rzls",
}

---@param lsp vim.lsp.Client
---@param bufnr integer
---@param position lsp.Position
---@return { err: lsp.ResponseError|nil, result: razor.LanguageQueryResponse }|nil, string|nil
function M.language_query_sync(lsp, bufnr, position)
    return lsp.request_sync("razor/languageQuery", {
        position = position,
        uri = vim.uri_from_bufnr(bufnr),
    }, nil, bufnr)
end

---@param lsp vim.lsp.Client
---@param bufnr integer
---@param language_kind razor.LanguageKind
---@param ranges lsp.Range[]
---@param cb fun(err: lsp.ResponseError, response: razor.MapToDocumentRangesResponse)
function M.map_to_document_ranges(lsp, bufnr, language_kind, ranges, cb)
    lsp.request("razor/mapToDocumentRanges", {
        razorDocumentUri = vim.uri_from_bufnr(bufnr),
        kind = language_kind,
        projectedRanges = ranges,
    }, cb)
end

return M
