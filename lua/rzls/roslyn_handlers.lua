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
    local rvd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.razor, "any")

    if not vd or not rvd then
        documentstore.register_vbufs_by_path(vim.uri_to_fname(result.razorDocument.uri), false)
        vd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.csharp, "any")
        rvd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.razor, "any")
        if not vd or not rvd then
            return nil, vim.lsp.rpc.rpc_response_error(-32600, "Could not find requested document")
        end
    end

    if result.fullText then
        ---@type razor.ProvideDynamicFileResponse
        local resp = {
            csharpDocument = {
                uri = rvd.uri,
            },
            checksum = vd.checksum or "",
            checksumAlgorithm = vd.checksum_algorithm or 1,
            encodingCodePage = vd.encoding_code_page or vim.NIL,
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

    if rvd.buf then
        -- Open documents have didOpen/didChange to update the csharp buffer. Razor
        --does not send edits and instead lets vscode handle them.
        ---@type razor.ProvideDynamicFileResponse
        local resp = {
            csharpDocument = {
                uri = vd.uri,
            },
            checksum = vd.checksum or "",
            checksumAlgorithm = vd.checksum_algorithm or 1,
            encodingCodePage = vd.encoding_code_page or vim.NIL,
            updates = vim.NIL,
        }
        return resp
    else
        local updates, original_checksum, original_checksum_algorithm, original_encoding_code_page = vd:apply_edits()
        local edits
        if vim.tbl_isempty(updates) then
            edits = nil
        else
            ---@type razor.DynamicFileUpdate[]
            edits = vim.iter(updates)
                :map(function(v)
                    return { edits = v.changes }
                end)
                :totable()
        end
        ---@type razor.ProvideDynamicFileResponse
        local resp = {
            csharpDocument = {
                uri = vd.uri,
            },
            checksum = original_checksum,
            checksumAlgorithm = original_checksum_algorithm,
            encodingCodePage = original_encoding_code_page,
            updates = edits or vim.NIL,
        }
        return resp
    end
end

return {
    [razor.notification.razor_provideDynamicFileInfo] = roslyn_razor_provideDynamicFileHandler,
}
