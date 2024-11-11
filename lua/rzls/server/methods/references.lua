local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.ReferenceParams
---@return lsp.Definition[]?
return function(params)
    ---@type lsp.Position
    local position = params.position
    ---@type integer
    local razor_bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local razor_docname = vim.api.nvim_buf_get_name(razor_bufnr)

    local rvd = documentstore.get_virtual_document(razor_docname, razor.language_kinds.razor)
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
            uri = vim.uri_from_bufnr(virtual_document.buf),
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
                razorDocumentUri = vim.uri_from_bufnr(razor_bufnr),
                kind = language_query_response.result.kind,
                projectedRanges = { v.range },
            }, nil, razor_bufnr)
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
