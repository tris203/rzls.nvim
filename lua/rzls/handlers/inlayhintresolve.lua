local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local empty_response = {}

---@param _err lsp.ResponseError
---@param result razor.DelegatedInlayHintResolveParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    if
        not result
        or not result.identifier
        or not result.identifier.textDocumentIdentifier
        or not result.identifier.version
    then
        Log.rzlsnvim = "razor/inlayHintResolve: Unexpected result shape. "
        return empty_response
    end

    if result.projectedKind ~= razor.language_kinds.csharp then
        --- inlay hints only supported in csharp for now
        return empty_response
    end

    local virtual_document = documentstore.get_virtual_document(
        result.identifier.textDocumentIdentifier.uri,
        razor.language_kinds.csharp,
        result.identifier.version
    )
    if not virtual_document then
        return empty_response
    end
    local inlay_hint_resolve_params = result.inlayHint
    local inlay_hint_resolve_response =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.inlayHint_resolve, inlay_hint_resolve_params)
    if not inlay_hint_resolve_response then
        return empty_response
    end
    return inlay_hint_resolve_response
end
