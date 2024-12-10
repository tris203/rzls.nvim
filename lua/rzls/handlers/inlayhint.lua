local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local empty_response = {}

--- [rzls:textDocument/inlayHint] rzls language client sends textDocument/inlayHint req to rzls
--- -> [rzlsnvim:razor/inlayHint] rzls sends razor/inlayHint req rzls language client handled by rzls.nvim
---   -> [roslyn:textDocument/inlayHint] rlzs.nvim sends textDocument/inlayHint req to roslyn language client attached to c# virtual doc
--- <- [rzlsnvim:razor/inlayHint] rzls.nvim passes roslyn res back from handler and rzls language client responds to rzls
--- [rzls:textDocument/inlayHint] rzls responds to rzls language client

---@param _err lsp.ResponseError
---@param result razor.DelegatedInlayHintParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    if
        not result
        or not result.identifier
        or not result.identifier.textDocumentIdentifier
        or not result.identifier.version
    then
        Log.rzlsnvim = "razor/inlayHint: Unexpected result shape. "
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
    local inlay_hint_params = vim.tbl_deep_extend("force", result, {
        textDocument = {
            uri = virtual_document.uri,
        },
        range = result.projectedRange,
    })
    local inlay_hint_response =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_inlayHint, inlay_hint_params)
    if not inlay_hint_response then
        return empty_response
    end
    return inlay_hint_response
end
