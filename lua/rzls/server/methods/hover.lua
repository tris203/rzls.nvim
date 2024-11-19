local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.TextDocumentPositionParams
---@return lsp.Hover?
return function(params)
    ---@type lsp.Position
    local position = params.position

    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    assert(rvd, "Could not find virtual document")

    local language_query_response, err = rvd:language_query(position)

    if not language_query_response or err then
        return
    end

    local virtual_document = documentstore.get_virtual_document(
        rvd.path,
        language_query_response.kind,
        language_query_response.hostDocumentVersion
    )
    assert(virtual_document)

    ---@type lsp.Hover?
    local hover_result = virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_hover, {
        textDocument = {
            uri = virtual_document.path,
        },
        position = language_query_response.position,
    })

    if not hover_result then
        return
    end

    local response = rvd:map_to_document_ranges(language_query_response.kind, { hover_result.range })

    if response and response.ranges[1] ~= nil then
        ---@type lsp.Hover
        return {
            contents = hover_result.contents,
            range = response.ranges[1],
        }
    end
end
