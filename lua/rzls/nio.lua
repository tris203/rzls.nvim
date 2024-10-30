---@module "nio"
---@class nio.lsp.RequestClient
local LSPRequestClient = {}

--- Query to find which language kind an specified position in a razor file represents
---@async
---@param _args razor.LanguageQueryParams Arguments to the request
---@param _bufnr integer? Buffer number (0 for current buffer)
---@param _opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return razor.LanguageQueryResponse|nil result The result of the request
function LSPRequestClient.razor_languageQuery(_args, _bufnr, _opts) end

--- Map ranges from the projected document to the razor document
---@async
---@param _args razor.MapToDocumentRangesParams Arguments to the request
---@param _bufnr integer? Buffer number (0 for current buffer)
---@param _opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return razor.MapToDocumentRangesResponse|nil result The result of the request
function LSPRequestClient.razor_mapToDocumentRanges(_args, _bufnr, _opts) end

return LSPRequestClient
