local documentstore = require("rzls.documentstore")

---@param err lsp.ResponseError
---@param result razor.DelegatedCompletionParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(err, result, _ctx, _config)
    assert(not err, err)

    local virtual_document = documentstore.get_virtual_document(
        result.identifier.textDocumentIdentifier.uri,
        result.identifier.version,
        result.projectedKind
    )
    assert(virtual_document, "No virtual document found")

    local virtual_client = virtual_document:get_lsp_client()
    assert(virtual_client, "No virtual client found")

    --- "@" is not a valid trigger character for C# and HTML
    local trigger_character = result.context.triggerCharacter == "@" and result.context.triggerCharacter or nil
    local trigger_kind = result.context.triggerCharacter == "@" and result.context.triggerKind or 1 -- Invoked

    ---@type lsp.CompletionParams
    local params = {
        context = {
            triggerKind = trigger_kind,
            triggerCharacter = trigger_character,
        },
        position = result.projectedPosition,
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_document.buf),
        },
    }

    local response =
        virtual_client.request_sync(vim.lsp.protocol.Methods.textDocument_completion, params, nil, virtual_document.buf)

    if response == nil then
        return nil,
            vim.lsp.rpc_response_error(
                vim.lsp.client_errors["INVALID_SERVER_MESSAGE"],
                "Virtual LSP client returned no response"
            )
    end

    if response.err ~= nil then
        return nil, err
    end

    return response.result or {
        items = {},
    }
end
