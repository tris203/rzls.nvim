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

    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    if not rvd then
        return nil
    end

    local language_query_response, err = rvd:language_query(position)

    if not language_query_response or err then
        return nil
    end

    if language_query_response.kind ~= razor.language_kinds.csharp then
        --- vscode only supports c# renames
        vim.notify("Rename is only supported for C#.", vim.log.levels.ERROR, { title = "rzls.nvim" })
        return nil
    end

    local csvd = documentstore.get_virtual_document(
        params.textDocument.uri,
        razor.language_kinds.csharp,
        language_query_response.hostDocumentVersion
    )
    if not csvd then
        return nil
    end

    ---@type lsp.WorkspaceEdit?
    local edits, editerr = csvd:lsp_request(vim.lsp.protocol.Methods.textDocument_rename, {
        textDocument = {
            uri = csvd.path,
        },
        position = language_query_response.position,
        newName = params.newName,
    })

    if not edits or editerr then
        return nil
    end

    ---@type lsp.WorkspaceEdit
    local mapped_workspaceedits = {}
    for _, changes in ipairs(edits.documentChanges) do
        local csharp_uri = changes.textDocument.uri
        ---@type lsp.TextEdit[]
        local remapped_edits = {}
        for _, edit in ipairs(changes.edits) do
            local remapped_response = rvd:map_to_document_ranges(razor.language_kinds.csharp, { edit.range })
            if remapped_response ~= nil and remapped_response.ranges ~= nil then
                for _, range in ipairs(remapped_response.ranges) do
                    if range.start.line > 0 then
                        table.insert(remapped_edits, { newText = edit.newText, range = remapped_response.ranges[1] })
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
