local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param err lsp.ResponseError
---@param result razor.DelegatedCompletionItemResolveParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(err, result, _ctx, _config)
    assert(not err, err)

    if result.originatingKind == razor.language_kinds.csharp and result.completionItem.data.TextDocument ~= nil then
        local virtual_document = documentstore.get_virtual_document(
            result.identifier.textDocumentIdentifier.uri,
            result.originatingKind,
            result.identifier.version
        )
        assert(virtual_document, "No virtual document found")

        if virtual_document.provisional_dot_position and virtual_document:ensure_resolve_provisional_dot() then
            virtual_document:ensure_content()
        end

        ---@type lsp.CompletionItem
        local response =
            virtual_document:lsp_request(vim.lsp.protocol.Methods.completionItem_resolve, result.completionItem)

        if virtual_document.provisional_dot_position and virtual_document:remove_resolve_provisional_dot() then
            virtual_document:ensure_content()
        end

        if not response then
            return result.completionItem
        end

        return response
    end

    return result.completionItem
end
