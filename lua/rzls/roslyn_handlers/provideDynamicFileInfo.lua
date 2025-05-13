local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local function refresh_roslyn_diagnostics(client_id)
    -- we need time for the lsp to process the changes
    local buffers = vim.lsp.get_buffers_by_client_id(client_id)
    for _, buf in ipairs(buffers) do
        local uri = vim.uri_from_bufnr(buf)
        if not uri:match(razor.virtual_suffixes.csharp .. "$") then
            require("rzls.refresh").diagnostics.add(buf)
        end
    end
end

local function ensure_rzls_started()
    if not require("rzls").rzls_client_id then
        local rzls_client_id = (function()
            vim.notify("starting razor from roslyn request", vim.log.levels.INFO, { title = "rzls.nvim" })
            return require("rzls").start_rzls()
        end)()
        assert(rzls_client_id, "Could not start Razor LSP")
        local rzls_client = vim.lsp.get_client_by_id(rzls_client_id)
        assert(rzls_client, "Could not find Razor LSP client")
        Log.rzlsnvim = string.format("Razor LSP started with client id: %s from a roslyn handler", rzls_client_id)
        local started = vim.wait(10000, function()
            return rzls_client.initialized
        end, 100)
        assert(started, "Razor LSP did not start in time")
        Log.rzlsnvim = string.format("Razor LSP initialized: %s", rzls_client.initialized)
    end
end

---@param _err lsp.ResponseError
---@param result razor.ProvideDynamicFileParams
---@param ctx lsp.HandlerContext
---@param _config? table
---@return razor.ProvideDynamicFileResponse|nil
---@return lsp.ResponseError|nil
return function(_err, result, ctx, _config)
    ensure_rzls_started()
    if result.razorDocument == nil then
        Log.rzlsnvim = "Razor document was missing from roslyn request"
        return nil, vim.lsp.rpc.rpc_response_error(-32602, "Missing razorDocument")
    end
    local vd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.csharp, "any")
    local rvd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.razor, "any")

    if not vd or not rvd then
        documentstore.register_vbufs_by_path(vim.uri_to_fname(result.razorDocument.uri), false)
        vd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.csharp, "any")
        rvd = documentstore.get_virtual_document(result.razorDocument.uri, razor.language_kinds.razor, "any")
        if not vd or not rvd then
            Log.rzlsnvim = string.format("Could not find/create requested document: %s", result.razorDocument.uri)
            return nil, vim.lsp.rpc.rpc_response_error(-32600, "Could not find requested document")
        end
    end

    refresh_roslyn_diagnostics(ctx.client_id)

    if result.fullText then
        ---@type razor.ProvideDynamicFileResponse
        local resp = {
            csharpDocument = {
                uri = rvd.uri,
            },
            checksum = vd.checksum or "",
            checksumAlgorithm = vd.checksum_algorithm or 1,
            encodingCodePage = vd.encoding_code_page or vim.NIL,
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
        Log.rzlsnvim = string.format("FullText request for %s", result.razorDocument.uri)
        return resp
    end

    ---@type razor.razorTextChange[]
    local edits = {}
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
            edits = {},
        }
        Log.rzlsnvim = string.format("Open request for %s", result.razorDocument.uri)
        return resp
    else
        local updates, original_checksum, original_checksum_algorithm, original_encoding_code_page = vd:apply_edits()
        if vim.tbl_isempty(updates) then
            edits = {}
        else
            for _, u in ipairs(updates) do
                vim.list_extend(edits, u.changes)
            end
        end
        ---@type razor.ProvideDynamicFileResponse
        local resp = {
            csharpDocument = {
                uri = vd.uri,
            },
            checksum = original_checksum,
            checksumAlgorithm = original_checksum_algorithm,
            encodingCodePage = original_encoding_code_page,
            edits = edits,
        }
        Log.rzlsnvim = string.format("Closed request for %s", result.razorDocument.uri)
        return resp
    end
end
