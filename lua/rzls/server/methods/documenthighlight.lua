local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.DocumentHighlightParams
---@return lsp.DocumentHighlight[] | nil
return function(params)
    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)

    if not rvd then
        return
    end

    local language_query_response = rvd:language_query(params.position)

    if not language_query_response then
        return
    end

    local virtual_document = documentstore.get_virtual_document(
        params.textDocument.uri,
        language_query_response.kind,
        language_query_response.hostDocumentVersion
    )

    if not virtual_document then
        return
    end

    ---@type lsp.DocumentHighlightParams
    local highlight_params = vim.tbl_extend("force", params, {
        textDocument = vim.lsp.util.make_text_document_params(virtual_document.buf),
        position = language_query_response.position,
    })

    ---@type lsp.DocumentHighlight[] | nil
    local highlight_response, highlight_err =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_documentHighlight, highlight_params)

    if not highlight_response or highlight_err then
        return
    end

    ---@type lsp.DocumentHighlight[]
    local highlights = {}
    for _, highlight in ipairs(highlight_response) do
        local mapped_ranges, mapped_ranges_err =
            rvd:map_to_document_ranges(language_query_response.kind, { highlight.range })

        if
            not mapped_ranges_err
            and mapped_ranges
            and mapped_ranges.ranges[1]
            and mapped_ranges.hostDocumentVersion == virtual_document.host_document_version
        then
            table.insert(
                highlights,
                vim.tbl_extend("force", highlight, {
                    range = mapped_ranges.ranges[1],
                })
            )
        end
    end

    return highlights
end
