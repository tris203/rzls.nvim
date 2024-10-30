---@diagnostic disable: redefined-local
local nio = require("nio")
local documentstore = require("rzls.documentstore")

---@param err lsp.ResponseError
---@param result nio.lsp.types.Hover
---@param ctx lsp.HandlerContext
---@param config table
return function(err, result, ctx, config)
    nio.run(function()
        assert(not err)

        if result then
            vim.lsp.handlers.hover(err, result, ctx, config)
            return
        end

        ---@type nio.lsp.types.Position
        local position = ctx.params.position
        ---@type integer
        local bufnr = ctx.bufnr

        local client = nio.lsp.get_client_by_id(ctx.client_id)
        assert(client, "Could not find Razor Client")

        local ierr, language_query_response = client.request.razor_languageQuery({
            position = position,
            uri = vim.uri_from_bufnr(bufnr),
        })
        assert(not ierr, vim.inspect(ierr))
        assert(language_query_response)

        local virtual_document = documentstore.get_virtual_document(
            vim.uri_from_bufnr(bufnr),
            language_query_response.hostDocumentVersion,
            language_query_response.kind
        )
        assert(virtual_document)

        local virtual_buf_client = virtual_document:get_nio_lsp_client()

        if virtual_buf_client == nil then
            vim.lsp.handlers.hover(err, result, ctx, config)
            return
        end

        local errh, hover_result = virtual_buf_client.request.textDocument_hover({
            textDocument = {
                uri = vim.uri_from_bufnr(virtual_document.buf),
                "textHover from virtual buffer uri",
            },
            position = language_query_response.position,
        })
        assert(not errh, vim.inspect(errh))

        if hover_result == nil then
            vim.lsp.handlers.hover(err, hover_result, ctx, config)
            return
        end

        local errm, response = client.request.razor_mapToDocumentRanges({
            razorDocumentUri = vim.uri_from_bufnr(bufnr),
            kind = language_query_response.kind,
            projectedRanges = { hover_result.range },
        })
        assert(not errm, vim.inspect(errm))

        if response ~= nil and response.ranges[1] ~= nil then
            vim.lsp.handlers.hover(err, {
                contents = hover_result.contents,
                range = response.ranges[1],
            }, ctx, config)
        end
    end)
end
