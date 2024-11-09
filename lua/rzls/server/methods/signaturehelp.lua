local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.SignatureHelpParams
---@return lsp.SignatureHelp?
return function(params)
    ---@type lsp.Position
    local position = params.position

    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    assert(rvd, "Could not find virtual document")

    local language_query_response = rvd:language_query(position)

    assert(language_query_response, "Could not find language query response")

    local vd = documentstore.get_virtual_document(
        rvd.path,
        language_query_response.kind,
        language_query_response.hostDocumentVersion
    )
    assert(vd, "Could not find virtual document from projection result")

    ---@type lsp.SignatureHelp?
    local sig_help = vd:lsp_request(vim.lsp.protocol.Methods.textDocument_signatureHelp, {
        textDocument = {
            uri = vd.path,
        },
        position = language_query_response.position,
        context = params.context,
    })

    if not sig_help then
        return nil
    end

    return sig_help
end
