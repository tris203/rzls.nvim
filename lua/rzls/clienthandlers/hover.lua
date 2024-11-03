local documentstore = require("rzls.documentstore")

---@param err lsp.ResponseError
---@param result lsp.TextDocumentPositionParams
---@param ctx lsp.HandlerContext
---@param config table
return function(err, result, ctx, config)
    if result then
        vim.lsp.handlers.hover(err, result, ctx, config)
        return
    end

    ---@type lsp.Position
    local position = ctx.params.position
    ---@type integer
    local razor_bufnr = ctx.bufnr

    local client = vim.lsp.get_client_by_id(ctx.client_id)
    assert(client, "Could not find Razor Client")

    local language_query_response = client.request_sync("razor/languageQuery", {
        position = position,
        uri = vim.uri_from_bufnr(razor_bufnr),
    }, nil, razor_bufnr)

    assert(language_query_response)

    local virtual_document = documentstore.get_virtual_document(
        vim.uri_from_bufnr(razor_bufnr),
        language_query_response.result.hostDocumentVersion,
        language_query_response.result.kind
    )
    assert(virtual_document)

    local virtual_buf_client = virtual_document:get_lsp_client()

    if virtual_buf_client == nil then
        vim.lsp.handlers.hover(err, {}, ctx, config)
        return
    end

    local hover_result = virtual_buf_client.request_sync("textDocument/hover", {
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
            "textHover from virtual buffer uri",
        },
        position = language_query_response.result.position,
    }, nil, virtual_document.buf)

    if not hover_result or hover_result.result == nil then
        vim.lsp.handlers.hover(err, {}, ctx, config)
        return
    end

    local response = client.request_sync("razor/mapToDocumentRanges", {
        razorDocumentUri = vim.uri_from_bufnr(razor_bufnr),
        kind = language_query_response.result.kind,
        projectedRanges = { hover_result.result.range },
    }, nil, razor_bufnr)

    if response and response.result ~= nil and response.result.ranges[1] ~= nil then
        vim.lsp.handlers.hover(err, {
            contents = hover_result.result.contents,
            range = response.result.ranges[1],
        }, ctx, config)
    end
end
