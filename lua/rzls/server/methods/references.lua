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

    ---@type lsp.Location[]?
    local references_result = virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_references, {
        textDocument = {
            uri = virtual_document.path,
        },
        position = language_query_response.position,
        context = {
            includeDeclaration = true,
        },
    })

    if not references_result then
        return
    end

    local response = {}
    for _, v in pairs(references_result) do
        if
            language_query_response.kind == razor.language_kinds.html
            and v.uri:match(razor.virtual_suffixes.html .. "$")
        then
            ---@type lsp.Definition
            local data = {
                uri = params.textDocument.uri,
                range = v.range,
            }
            table.insert(response, data)
        elseif v.uri:match(razor.virtual_suffixes.csharp .. "$") then
            local mapped_loc = rvd:map_to_document_ranges(language_query_response.kind, { v.range })
            if mapped_loc and mapped_loc.ranges[1] and mapped_loc.ranges[1].start.line > 0 then
                ---@type lsp.Definition
                local data = {
                    uri = params.textDocument.uri,
                    range = mapped_loc.ranges[1],
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
