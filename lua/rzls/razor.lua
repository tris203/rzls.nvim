local lsp_utils = require("rzls.utils.lsp")
local nio = require("nio")

local M = {}

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

vim.api.nvim_create_user_command("RQ", function()
    local client = nio.lsp.get_clients({ name = "rzls" })[1]

    assert(client, "Could not find LSP client")

    local buf = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local position = lsp_utils.cursor_to_lsp_position(cursor_pos)

    nio.run(function()
        local err, response = client.request.razor_languageQuery({
            uri = vim.uri_from_bufnr(buf),
            position = position --[[@as nio.lsp.types.Position]],
        })
        assert(not err, err)
        assert(response)

        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            "QuickFixLine",
            response.position.line,
            response.position.character,
            response.position.character + 3
        )
    end)
end, {})

return M
