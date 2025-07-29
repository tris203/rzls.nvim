local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@type { [integer] : any }
local _cache = {}

---@param _err lsp.ResponseError
---@param result razor.CSharpPullDiagnosticParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(_err, result, _ctx, _config)
    local virtual_document = documentstore.get_virtual_document(
        result.identifier.textDocumentIdentifier.uri,
        razor.language_kinds.csharp,
        result.identifier.version
    )
    if not virtual_document then
        return vim.NIL
    end

    ---@type lsp.DocumentDiagnosticParams
    local diagnostic_params = {
        textDocument = {
            uri = virtual_document.uri,
        },
    }

    ---@type lsp.Diagnostic[]
    local diagnostic_response, err =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_diagnostic, diagnostic_params)
    if not diagnostic_response or err then
        --NOTE:
        -- Return VIM.NIL here rather than empty response
        -- (https://github.com/tris203/rzls.nvim/pull/60)

        if not vim.deep_equal(_cache[virtual_document.buf], diagnostic_response) then
            require("rzls.refresh").diagnostics.add(virtual_document.buf)
        end
        _cache[virtual_document.buf] = nil

        return vim.NIL, nil
    end

    if not vim.deep_equal(_cache[virtual_document.buf], diagnostic_response) then
        require("rzls.refresh").diagnostics.add(virtual_document.buf)
    end
    _cache[virtual_document.buf] = diagnostic_response

    return diagnostic_response
end
