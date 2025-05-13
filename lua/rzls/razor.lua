local M = {}

---@class razor.VBufUpdate
---@field checksum string
---@field checksumAlgorithm number
---@field encodingCodePage? number
---@field previousWasEmpty boolean
---@field hostDocumentFilePath string
---@field hostDocumentVersion number
---@field changes razor.razorTextChange[]

---@class razor.LanguageQueryParams
---@field position lsp.Position
---@field uri string

---@class razor.LanguageQueryResponse
---@field hostDocumentVersion integer
---@field kind razor.LanguageKind
---@field position lsp.Position
---@field positionIndex integer

---@class razor.MapToDocumentRangesParams
---@field razorDocumentUri string
---@field kind razor.LanguageKind
---@field projectedRanges lsp.Range[]

---@class razor.TextSpan
---@field start integer
---@field length integer

---@class razor.MapToDocumentRangesResponse
---@field hostDocumentVersion integer
---@field ranges lsp.Range[]
---@field spans razor.TextSpan[]

---@class razor.razorMapSpansParams
---@field csharpDocument lsp.TextDocumentIdentifier
---@field ranges lsp.Range[]

---@class razor.razorMapSpansResponse
---@field ranges lsp.Range[]
---@field spans razor.TextSpan[]
---@field razorDocument lsp.TextDocumentIdentifier

---@class razor.razorMapTextChangesParams
---@field csharpDocument lsp.TextDocumentIdentifier
---@field textChanges razor.razorTextChange[]

---@class razor.razorMapTextChangesResponse
---@field razorDocument lsp.TextDocumentIdentifier
---@field textChanges razor.razorTextChange[]

---@class razor.ProvideSemanticTokensParams
---@field correlationId string
---@field textDocument lsp.TextDocumentIdentifier
---@field ranges lsp.Range[]
---@field requiredHostDocumentVersion integer

---@class razor.ProvideSemanticTokensResponse
---@field tokens integer[]
---@field hostDocumentSyncVersion integer

---@class razor.DelegatedCompletionRange
---@field tokens integer[]
---@field hostDocumentSyncVersion integer

---@class razor.TextDocumentIdentifierAndVersion
---@field textDocumentIdentifier lsp.TextDocumentIdentifier
---@field version integer

---@class razor.DelegatedCompletionParams
---@field identifier razor.TextDocumentIdentifierAndVersion
---@field projectedPosition lsp.Position
---@field projectedKind razor.LanguageKind
---@field context lsp.CompletionContext
---@field provisionalTextEdit lsp.TextEdit
---@field shouldIncludeSnippets boolean

---@class razor.DelegatedCompletionItemResolveParams
---@field identifier razor.TextDocumentIdentifierAndVersion
---@field completionItem lsp.CompletionItem
---@field originatingKind razor.LanguageKind

---@class razor.ProvideDynamicFileParams
---@field razorDocument lsp.TextDocumentIdentifier
---@field fullText boolean

---@class razor.ProvideDynamicFileResponse
---@field csharpDocument? lsp.TextDocumentIdentifier
---@field edits razor.razorTextChange[]
---@field checksum string
---@field checksumAlgorithm number
---@field encodingCodePage number | vim.NIL

---@class razor.RemoveDynamicFileParams
---@field csharpDocument lsp.TextDocumentIdentifier

---@class razor.razorTextChange
---@field newText string
---@field span razor.TextSpan

---@class razor.DynamicFileUpdatedParams
---@field razorDocument lsp.TextDocumentIdentifier

---@class razor.DelegatedInlayHintParams
---@field identifier razor.TextDocumentIdentifierAndVersion
---@field projectedKind razor.LanguageKind
---@field projectedRange lsp.Range

---@class razor.DelegatedInlayHintResolveParams
---@field identifier razor.TextDocumentIdentifierAndVersion
---@field inlayHint lsp.InlayHint
---@field projectedKind razor.LanguageKind

---@class razor.CSharpPullDiagnosticParams
---@field correlationId string
---@field identifier razor.TextDocumentIdentifierAndVersion

---@enum razor.LanguageKind
M.language_kinds = {
    csharp = 1,
    html = 2,
    razor = 3,
}

---@enum (key) razor.VirtualSuffix
M.virtual_suffixes = {
    html = "__virtual.html",
    csharp = "__virtual.cs",
}

---@enum razor.LSPClientName
M.lsp_names = {
    [M.language_kinds.html] = "html",
    [M.language_kinds.csharp] = "roslyn",
    [M.language_kinds.razor] = "rzls",
}

M.notification = {
    razor_dynamicFileInfoChanged = "razor/dynamicFileInfoChanged",
    razor_namedPipeConnect = "razor/namedPipeConnect",
    razor_initialize = "razor/initialize",
}

---@type table<string, vim.api.keyset.highlight>
--TODO: Extend this to cover all razor highlights
-- https://github.com/dotnet/vscode-csharp/blob/802be7399e947ab82f2a69780d43a57c1d5be6aa/package.json#L4761
local razor_highlights = {
    ["@lsp.type.razorComment"] = { link = "Comment" },
    ["@lsp.type.razorCommentStar"] = { link = "Comment" },
    ["@lsp.type.razorCommentTransition"] = { link = "Comment" },
    ["@lsp.type.controlKeyword"] = { link = "Statement" },
    ["@lsp.type.punctuation"] = { link = "@punctuation.bracket" },
    ["@lsp.type.razorTransition"] = { link = "Keyword" },
    ["@lsp.type.razorDirective"] = { link = "Keyword" },
    ["@lsp.type.razorDirectiveAttribute"] = { link = "Keyword" },
    ["@lsp.type.field"] = { link = "@variable" },
    ["@lsp.type.variable.razor"] = { link = "@variable" },
    ["@lsp.type.razorComponentElement.razor"] = { link = "@type" },
    ["@lsp.type.razorTagHelperElement.razor"] = { link = "@type" },
    ["@lsp.type.stringVerbatim.razor"] = { link = "@string" },
    ["@lsp.type.delegate.razor"] = { link = "@variable" },
    ["@lsp.type.constant.razor"] = { link = "@variable" },
    ["@lsp.type.razorComponentAttribute.razor"] = { link = "@property" },

    --Regex in string being passed to something like the Regex.Match()
    ["@lsp.type.regexComment.razor"] = { link = "@comment" },
    ["@lsp.type.regexCharacterClass.razor"] = { link = "@string.escape" },
    ["@lsp.type.regexAnchor.razor"] = { link = "@punctuation.delimiter" },
    ["@lsp.type.regexQuantifier.razor"] = { link = "@punctuation.operator" },
    ["@lsp.type.regexGrouping.razor"] = { link = "@punctuation.bracket" },
    ["@lsp.type.regexAlternation.razor"] = { link = "@operator" },
    ["@lsp.type.regexText.razor"] = { link = "@string" },
    ["@lsp.type.regexSelfEscapedCharacter.razor"] = { link = "@string.regexp" },
    ["@lsp.type.regexOtherEscape.razor"] = { link = "@string.regexp" },

    --json in strings highlighting
    ["@lsp.type.jsonComment.razor"] = { link = "@comment" },
    ["@lsp.type.jsonNumber.razor"] = { link = "@number" },
    ["@lsp.type.jsonString.razor"] = { link = "@string" },
    ["@lsp.type.jsonKeyword.razor"] = { link = "@keyword" },
    ["@lsp.type.jsonText.razor"] = { link = "@string" },
    ["@lsp.type.jsonOperator.razor"] = { link = "@punctuation.operator" },
    ["@lsp.type.jsonPunctuation.razor"] = { link = "@punctuation.delimiter" },
    ["@lsp.type.jsonArray.razor"] = { link = "@punctuation.bracket" },
    ["@lsp.type.jsonObject.razor"] = { link = "@punctuation.bracket" },
    ["@lsp.type.jsonPropertyName.razor"] = { link = "@property" },
}

M.apply_highlights = function()
    for hl_group, hl in pairs(razor_highlights) do
        vim.api.nvim_set_hl(0, hl_group, hl)
    end
end

return M
