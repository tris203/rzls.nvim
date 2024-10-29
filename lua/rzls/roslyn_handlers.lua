local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param err lsp.ResponseError
---@param result razor.ProvideDynamicFileParams
---@param ctx lsp.HandlerContext
---@param config? table
---@return razor.ProvideDynamicFileResponse|nil
---@return lsp.ResponseError|nil
local function roslyn_razor_provideDynamicFileHandler(err, result, ctx, config)
    local bufnr = documentstore.get_virtual_bufnr(result.razorDocument.uri, 0, razor.language_kinds.csharp)

    if bufnr == nil then
        vim.print(vim.inspect(result))
        return nil, vim.lsp.rpc.rpc_response_error(-32600, "Could not find requested document")
    end

    -- TODO: ideally we could get the client by the razor document, but the client might no have been attached yet
    local razor_client = vim.lsp.get_clients({ name = "rzls" })[1]
    assert(razor_client, "Could not find razor client")
    documentstore.rosyln_is_ready(razor_client)

    return {
        csharpDocument = {
            uri = vim.uri_from_bufnr(
                documentstore.get_virtual_bufnr(result.razorDocument.uri, 0, razor.language_kinds.csharp)
            ),
        },
    }
end

return {
    ["razor/provideDynamicFileInfo"] = roslyn_razor_provideDynamicFileHandler,
}
