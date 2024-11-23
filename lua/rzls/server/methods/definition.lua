local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.TextDocumentPositionParams
---@return lsp.DefinitionLink[]?
return function(params)
    ---@type lsp.Position
    local position = params.position

    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    if not rvd then
        return
    end

    local language_query_response, err = rvd:language_query(position)

    if not language_query_response or err then
        return nil
    end

    local virtual_document = documentstore.get_virtual_document(
        rvd.path,
        language_query_response.kind,
        language_query_response.hostDocumentVersion
    )
    if not virtual_document then
        return
    end

    ---@type lsp.Definition?
    local definition_result = virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_definition, {
        textDocument = {
            uri = virtual_document.path,
        },
        position = language_query_response.position,
    })

    if not definition_result then
        return
    end

    local response = {}
    for _, v in pairs(definition_result) do
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
            if mapped_loc and mapped_loc.ranges[1] then
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
