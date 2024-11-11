local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.TextDocumentPositionParams
---@return lsp.Hover?
return function(params)
    ---@type lsp.Position
    local position = params.position

    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    assert(rvd, "Could not find virtual document")
    local client = rvd:get_lsp_client()
    assert(client, "Could not find Razor Client")

    local language_query_response = client.request_sync("razor/languageQuery", {
        position = position,
        uri = rvd.path,
    }, nil, rvd.buf)

    assert(language_query_response)

    local virtual_document = documentstore.get_virtual_document(
        rvd.path,
        language_query_response.result.kind,
        language_query_response.result.hostDocumentVersion
    )
    assert(virtual_document)

    local virtual_buf_client = virtual_document:get_lsp_client()

    if virtual_buf_client == nil then
        return
    end

    local hover_result = virtual_buf_client.request_sync("textDocument/hover", {
        textDocument = {
            uri = virtual_document.path,
        },
        position = language_query_response.result.position,
    }, nil, virtual_document.buf)

    if not hover_result or hover_result.result == nil then
        return
    end

    local response = client.request_sync("razor/mapToDocumentRanges", {
        razorDocumentUri = rvd.path,
        kind = language_query_response.result.kind,
        projectedRanges = { hover_result.result.range },
    }, nil, rvd.buf)

    if response and response.result ~= nil and response.result.ranges[1] ~= nil then
        ---@type lsp.Hover
        return {
            contents = hover_result.result.contents,
            range = response.result.ranges[1],
        }
    end
end
