local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param _err lsp.ResponseError
---@param result razor.ProvideDynamicFileParams
---@param _ctx lsp.HandlerContext
---@param _config? table
---@return razor.ProvideDynamicFileResponse|nil
---@return lsp.ResponseError|nil
local function roslyn_razor_provideDynamicFileHandler(_err, result, _ctx, _config)
    local razor_client = vim.lsp.get_clients({ name = razor.lsp_names[razor.language_kinds.razor] })[1]
    local roslyn_client = vim.lsp.get_clients({ name = razor.lsp_names[razor.language_kinds.csharp] })[1]

    local root_dir = (razor_client and razor_client.root_dir) or (roslyn_client and roslyn_client.root_dir)
    assert(root_dir, "Could not find root directory")

    documentstore.load_existing_files(root_dir)

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

    return {
        csharpDocument = {
            uri = vim.uri_from_bufnr(bufnr),
        },
    }
end

return {
    ["razor/provideDynamicFileInfo"] = roslyn_razor_provideDynamicFileHandler,
}
