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
        ---@type razor.ProvideDynamicFileResponse
        local resp = {
            csharpDocument = {
                uri = vd.path,
            },
            checksum = vd.checksum,
            checksumAlgorithm = vd.checksum_algorithm,
            enodingCodePage = vd.encoding_code_page,
            updates = {
                {
                    edits = {
                        {
                            newText = vd.content,
                            span = {
                                start = 0,
                                length = 0,
                            },
                        },
                    },
                },
            },
        }
        return resp
    end

    ---@type razor.DynamicFileUpdate[]
    local edits = vim.iter(vd.updates)
        :map(function(v)
            return { edits = v.changes }
        end)
        :totable()
    ---@type razor.ProvideDynamicFileResponse
    local resp = {
        csharpDocument = {
            uri = vd.path,
        },
        checksum = vd.checksum,
        checksumAlgorithm = vd.checksum_algorithm,
        enodingCodePage = vd.encoding_code_page,
        updates = not vd.buf and edits or nil,
    }
    return resp
end

return {
    [razor.notification.razor_provideDynamicFileInfo] = roslyn_razor_provideDynamicFileHandler,
}
