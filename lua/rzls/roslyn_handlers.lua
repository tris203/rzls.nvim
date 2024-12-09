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

    if result.fullText then
        --TODO: This shouldnt happen at the moment
        --But we will support it when we dont open all the documents on a vbuf update
        vim.print("requested full")
        vim.print(vim.inspect(result))
        return {
            csharpDocument = {
                uri = vim.uri_from_bufnr(vd.buf),
            },
            checksum = vd.checksum,
            checksumAlgorithm = vd.checksum_algorithm,
            enodingCodePage = vd.encoding_code_page,
            edits = {
                {
                    newText = vd.content,
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        }
    end

    return {
        csharpDocument = {
            uri = vim.uri_from_bufnr(vd.buf),
        },
        checksum = vd.checksum,
        checksumAlgorithm = vd.checksum_algorithm,
        enodingCodePage = vd.encoding_code_page,
        edits = not vd.buf and vd.edits or vim.NIL,
    }
end

return {
    [razor.notification.razor_provideDynamicFileInfo] = roslyn_razor_provideDynamicFileHandler,
}
