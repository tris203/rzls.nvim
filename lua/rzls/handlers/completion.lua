local documentstore = require("rzls.documentstore")
local debug = require("rzls.utils").debug

---@param err lsp.ResponseError
---@param result razor.DelegatedCompletionParams
---@param ctx lsp.HandlerContext
---@param config table
return function(err, result, ctx, config)
    assert(not err, err)
    debug({
        err = err,
        result = result,
        ctx = ctx,
        config = config,
    })

    local virtual_bufnr = documentstore.get_virtual_bufnr(
        result.identifier.textDocumentIdentifier.uri,
        result.identifier.version,
        result.projectedKind
    )
    assert(virtual_bufnr)

    local virtual_client = vim.lsp.get_clients({ bufnr = virtual_bufnr })[1]

    --- "@" is not a valid trigger character for C# and HTML
    local trigger_character = result.context.triggerCharacter == "@" and result.context.triggerCharacter or nil
    local trigger_kind = result.context.triggerCharacter == "@" and result.context.triggerKind or 1 -- Invoked

    ---@type lsp.CompletionParams
    local params = debug({
        context = {
            triggerKind = trigger_kind,
            triggerCharacter = trigger_character,
        },
        position = result.projectedPosition,
        textDocument = {
            uri = vim.uri_from_bufnr(virtual_bufnr),
        },
    })

    local response =
        virtual_client.request_sync(vim.lsp.protocol.Methods.textDocument_completion, params, nil, virtual_bufnr)

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
