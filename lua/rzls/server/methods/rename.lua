local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---Removes the virtual suffix from a virtual path returning the .razor filename
---@param virtual_path string
---@param suffix razor.VirtualSuffix
---@return string
local function remove_virtual_suffix(virtual_path, suffix)
    local base_path = virtual_path:gsub(razor.virtual_suffixes[suffix] .. "$", "")
    return base_path
end

---@param params lsp.RenameParams
---@return {}?
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

    if language_query_response.result.kind ~= razor.language_kinds.csharp then
        --- vscode only supports c# renames
        vim.notify("Rename is only supported for C#.", vim.log.levels.ERROR, { title = "rzls.nvim" })
        return nil
    end

    local csvd = documentstore.get_virtual_document(
        params.textDocument.uri,
        razor.language_kinds.csharp,
        language_query_response.result.hostDocumentVersion
    )
    assert(csvd, "Could not find virtual document")

    local roslyn_client = csvd:get_lsp_client()
    assert(roslyn_client, "Could not find Roslyn Client")

    local edits = roslyn_client.request_sync("textDocument/rename", {
        textDocument = {
            uri = csvd.path,
        },
        position = language_query_response.result.position,
        newName = params.newName,
    }, nil, rvd.buf)

    assert(edits and not edits.err and edits.result, "Rename request failed")
    ---@type lsp.WorkspaceEdit
    local result = edits.result

    local razor_client = rvd:get_lsp_client()
    assert(razor_client, "Could not find Razor Client")

    ---@type lsp.WorkspaceEdit
    local mapped_workspaceedits = {}
    for _, changes in ipairs(result.documentChanges) do
        local csharp_uri = changes.textDocument.uri
        ---@type lsp.TextEdit[]
        local remapped_edits = {}
        for _, edit in ipairs(changes.edits) do
            local remapped_response = razor_client.request_sync("razor/mapToDocumentRanges", {
                razorDocumentUri = rvd.path,
                kind = razor.language_kinds.csharp,
                projectedRanges = { edit.range },
            }, nil, rvd.buf)

            if remapped_response and remapped_response.result ~= nil and remapped_response.result.ranges ~= nil then
                for _, range in ipairs(remapped_response.result.ranges) do
                    if range.start.line > 0 then
                        table.insert(
                            remapped_edits,
                            { newText = edit.newText, range = remapped_response.result.ranges[1] }
                        )
                    end
                end
            end
        end
        if not vim.tbl_isempty(remapped_edits) then
            mapped_workspaceedits = {
                documentChanges = {
                    {
                        edits = remapped_edits,
                        textDocument = {
                            uri = remove_virtual_suffix(csharp_uri, "csharp"),
                        },
                    },
                },
            }
        end
    end

    return mapped_workspaceedits
end
