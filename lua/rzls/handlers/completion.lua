local documentstore = require("rzls.documentstore")
local lsp_util = require("rzls.utils.lsp")
local dsu = require("rzls.utils.documentstore")
local razor = require("rzls.razor")
local nio = require("nio")
local debug = require("rzls.utils").debug
local cmp = require("cmp")

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
    local params = {
        context = {
            triggerKind = trigger_kind,
            triggerCharacter = trigger_character,
        },
        position = result.projectedProsition,
        textDocument = result.identifier.textDocumentIdentifier,
    }

    local response =
        virtual_client.request_sync(vim.lsp.protocol.Methods.textDocument_completion, params, nil, virtual_bufnr)

    return response.result, response.err
end
