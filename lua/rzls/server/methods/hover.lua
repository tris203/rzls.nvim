local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.TextDocumentPositionParams
---@return lsp.Hover?
return function(params)
    ---@type lsp.Position
    local position = params.position
    ---@type integer
    local razor_bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local razor_docname = vim.api.nvim_buf_get_name(razor_bufnr)

    local rvd = documentstore.get_virtual_document(razor_docname, 0, razor.language_kinds.razor)
    assert(rvd, "Could not find virtual document")
    local client = rvd:get_lsp_client()
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
        return
    end

    local hover_result = virtual_buf_client.request_sync("textDocument/hover", {
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
        },
        position = language_query_response.result.position,
    }, nil, virtual_document.buf)

    if not hover_result or hover_result.result == nil then
        return
    end

    local response = client.request_sync("razor/mapToDocumentRanges", {
        razorDocumentUri = vim.uri_from_bufnr(razor_bufnr),
        kind = language_query_response.result.kind,
        projectedRanges = { hover_result.result.range },
    }, nil, razor_bufnr)

    if response and response.result ~= nil and response.result.ranges[1] ~= nil then
        ---@type lsp.Hover
        return {
            contents = hover_result.result.contents,
            range = response.result.ranges[1],
        }
    end
end
