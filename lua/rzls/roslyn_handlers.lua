local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param _err lsp.ResponseError
---@param result razor.ProvideDynamicFileParams
---@param _ctx lsp.HandlerContext
---@param _config? table
---@return razor.ProvideDynamicFileResponse|nil
---@return lsp.ResponseError|nil
local function roslyn_razor_provideDynamicFileHandler(_err, result, _ctx, _config)
    if result.razorDocument == nil then
        return nil, vim.lsp.rpc.rpc_response_error(-32602, "Missing razorDocument")
    end
    local vd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.csharp, "any")
    if not vd then
        return nil, vim.lsp.rpc.rpc_response_error(-32600, "Could not find requested document")
    end
    local bufnr = vd.buf

    if bufnr == nil then
        return nil, vim.lsp.rpc.rpc_response_error(-32600, "Could not find requested document")
    end

    -- TODO: ideally we could get the client by the razor document, but the client might no have been attached yet
    local razor_client = vim.lsp.get_clients({ name = "rzls" })[1]
    assert(razor_client, "Could not find razor client")

    return {
        csharpDocument = {
            uri = vim.uri_from_bufnr(bufnr),
        },
    }
end

return {
    ["razor/provideDynamicFileInfo"] = roslyn_razor_provideDynamicFileHandler,
}
