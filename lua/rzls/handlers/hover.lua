---@diagnostic disable: redefined-local
local nio = require("nio")
local lsp_util = require("rzls.utils.lsp")
local documentstore = require("rzls.documentstore")
local debug = require("rzls.utils").debug

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

        local err, language_query_response = client.request.razor_languageQuery({
            position = position,
            uri = lsp_util.buf_to_uri(bufnr),
        })
        assert(not err, err)
        assert(language_query_response)

        debug(language_query_response, "language_query_response")

        local virtual_bufnr = documentstore.get_virtual_bufnr(
            vim.uri_from_bufnr(bufnr),
            language_query_response.hostDocumentVersion,
            language_query_response.kind
        )
        assert(virtual_bufnr)

        local virtual_buf_client = nio.lsp.get_clients({ bufnr = virtual_bufnr })[1]

        if virtual_buf_client == nil then
            vim.lsp.handlers.hover(err, result, ctx, config)
            return
        end

        local err, hover_result = virtual_buf_client.request.textDocument_hover({
            textDocument = {
                uri = debug(lsp_util.buf_to_uri(virtual_bufnr), "textHover from virtual buffer uri"),
            },
            position = language_query_response.position,
        })
        assert(not err, err)
        debug(hover_result, "text hover from virtual buffer")

        if hover_result == nil then
            vim.lsp.handlers.hover(err, hover_result, ctx, config)
            return
        end

        local err, response = client.request.razor_mapToDocumentRanges({
            razorDocumentUri = lsp_util.buf_to_uri(bufnr),
            kind = language_query_response.kind,
            projectedRanges = { hover_result.range },
        })
        assert(not err, err)

        debug(response, "range map")
        if response ~= nil and response.ranges[1] ~= nil then
            vim.lsp.handlers.hover(err, {
                contents = hover_result.contents,
                range = response.ranges[1],
            }, ctx, config)
        end
    end)
end