local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.SignatureHelpParams
---@return lsp.SignatureHelp?
return function(params)
    ---@type lsp.Position
    local position = params.position

    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    if not rvd then
        return
    end

    local language_query_response, err = rvd:language_query(position)

    if not language_query_response or err then
        return nil
    end

    local vd = documentstore.get_virtual_document(
        rvd.uri,
        language_query_response.kind,
        language_query_response.hostDocumentVersion
    )
    if not vd then
        return nil
    end

    ---@type lsp.SignatureHelp?
    local sig_help = vd:lsp_request(vim.lsp.protocol.Methods.textDocument_signatureHelp, {
        textDocument = {
            uri = vd.uri,
        },
        position = language_query_response.position,
        context = params.context,
    })

    if not sig_help then
        return nil
    end

    return sig_help
end
