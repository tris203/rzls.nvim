local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param params lsp.SignatureHelpParams
---@return lsp.SignatureHelp?
return function(params)
    ---@type lsp.Position
    local position = params.position
    ---@type integer
    local razor_bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local razor_docname = vim.api.nvim_buf_get_name(razor_bufnr)

    local rvd = documentstore.get_virtual_document(razor_docname, 0, razor.language_kinds.razor)
    assert(rvd, "Could not find virtual document")
    local client = rvd:get_lsp_client()
    assert(client, "Could not find Razor Client")

    local language_query_response = client.request_sync("razor/languageQuery", {
        position = position,
        uri = vim.uri_from_bufnr(razor_bufnr),
    }, nil, razor_bufnr)

    assert(language_query_response)

    local lsp_client = vim.lsp.get_clients({ name = razor.lsp_names[language_query_response.result.kind] })[1]
    assert(lsp_client, "Could not find LSP Client for response type: " .. language_query_response.result.kind)

    local vd = documentstore.get_virtual_document(razor_docname, 0, language_query_response.result.kind)
    assert(vd, "Could not find virtual document from projection result")

    ---@type lsp.SignatureHelpParams
    local sigHelpReq = {
        textDocument = {
            uri = vim.uri_from_bufnr(vd.buf),
        },
        position = language_query_response.result.position,
        context = params.context,
    }

    local sig_help = lsp_client.request_sync("textDocument/signatureHelp", sigHelpReq, nil, razor_bufnr)

    if not sig_help or sig_help.err then
        return nil
    end

    return sig_help.result
end
