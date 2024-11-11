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
            result.identifier.version,
            result.originatingKind
        )
        assert(virtual_document, "No virtual document found")

        local virtual_client = virtual_document:get_lsp_client()
        assert(virtual_client, "No virtual client found")

        if virtual_document.provisional_dot_position and virtual_document:ensure_resolve_provisional_dot() then
            virtual_document:ensure_content()
        end

        local response = virtual_client.request_sync(
            vim.lsp.protocol.Methods.completionItem_resolve,
            result.completionItem,
            nil,
            virtual_document.buf
        )

        if virtual_document.provisional_dot_position and virtual_document:remove_resolve_provisional_dot() then
            virtual_document:ensure_content()
        end

        assert(response, "Virtual LSP didn't return any results for completionItem/resolve call")

        if response.err ~= nil then
            return nil, response.err
        end

        if response.result == nil then
            return result.completionItem
        end

        return response.result
    end

    return result.completionItem
end
