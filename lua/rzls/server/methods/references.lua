local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.ReferenceParams
---@return lsp.Definition[]?
return function(params)
    ---@type lsp.Position
    local position = params.position
    ---@type integer

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

    local references_result = virtual_buf_client.request_sync("textDocument/references", {
        textDocument = {
            uri = virtual_document.path,
        },
        position = language_query_response.result.position,
        context = {
            includeDeclaration = true,
        },
    }, nil, virtual_document.buf)

    if not references_result or references_result.result == nil then
        return
    end

    local response = {}
    for _, v in pairs(references_result.result) do
        if
            language_query_response.result.kind == razor.language_kinds.html
            and v.uri:match(razor.virtual_suffixes.html .. "$")
        then
            ---@type lsp.Definition
            local data = {
                uri = params.textDocument.uri,
                range = v.range,
            }
            table.insert(response, data)
        elseif v.uri:match(razor.virtual_suffixes.csharp .. "$") then
            local mapped_loc = client.request_sync("razor/mapToDocumentRanges", {
                razorDocumentUri = rvd.path,
                kind = language_query_response.result.kind,
                projectedRanges = { v.range },
            }, nil, rvd.buf)
            if mapped_loc and mapped_loc.result and mapped_loc.result.ranges[1] then
                ---@type lsp.Definition
                local data = {
                    uri = params.textDocument.uri,
                    range = mapped_loc.result.ranges[1],
                }
                table.insert(response, data)
            end
        else
            table.insert(response, v)
        end
    end

    if not vim.tbl_isempty(response) then
        return response
    end
end
