---@class nio.lsp.RequestClient
local LSPRequestClient = {}

--- Query to find which language kind an specified position in a razor file represents
---@async
---@param args razor.LanguageQueryParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return razor.LanguageQueryResponse|nil result The result of the request
function LSPRequestClient.razor_languageQuery(args, bufnr, opts) end

--- Map ranges from the projected document to the razor document
---@async
---@param args razor.MapToDocumentRangesParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return razor.MapToDocumentRangesResponse|nil result The result of the request
function LSPRequestClient.razor_mapToDocumentRanges(args, bufnr, opts) end
