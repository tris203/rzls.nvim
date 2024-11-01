local documentstore = require("rzls.documentstore")
local format = require("rzls.utils.format")
local razor = require("rzls.razor")

local not_implemented = function(err, result, ctx, config)
    vim.print("Called" .. ctx.method)
    vim.print(vim.inspect(err))
    vim.print(vim.inspect(result))
    vim.print(vim.inspect(ctx))
    vim.print(vim.inspect(config))
    return { "error" }
end

local not_supported = function()
    return {}, nil
end

return {
    -- VS Windows only
    ["razor/inlineCompletion"] = not_implemented,
    ["razor/validateBreakpointRange"] = not_implemented,
    ["razor/onAutoInsert"] = not_implemented,
    ["razor/semanticTokensRefresh"] = not_implemented,
    ["razor/textPresentation"] = not_implemented,
    ["razor/uriPresentation"] = not_implemented,
    ["razor/spellCheck"] = not_implemented,
    ["razor/projectContexts"] = not_implemented,
    ["razor/pullDiagnostics"] = not_implemented,
    ["razor/mapCode"] = not_implemented,

    -- VS Windows and VS Code
    ---@param err lsp.ResponseError
    ---@param result VBufUpdate
    ["razor/updateCSharpBuffer"] = function(err, result)
        assert(not err, vim.inspect(err))
        documentstore.update_vbuf(result, razor.language_kinds.csharp)
    end,
    ---@param err lsp.ResponseError
    ---@param result VBufUpdate
    ["razor/updateHtmlBuffer"] = function(err, result)
        assert(not err, vim.inspect(err))
        documentstore.update_vbuf(result, razor.language_kinds.html)
    end,
    ["razor/provideCodeActions"] = not_implemented,
    ["razor/resolveCodeActions"] = not_implemented,
    ["razor/provideHtmlColorPresentation"] = not_supported,
    ["razor/provideHtmlDocumentColor"] = not_implemented,
    ["razor/provideSemanticTokensRange"] = require("rzls.handlers.providesemantictokensrange"),
    ["razor/foldingRange"] = not_implemented,

    ["razor/htmlFormatting"] = function(err, result, _ctx, _config)
        if err then
            vim.notify("Error in razor/htmlFormatting", vim.log.levels.ERROR)
            return {}, nil
        end

        local virtual_document = documentstore.get_virtual_document(
            result.textDocument.uri,
            result._razor_hostDocumentVersion,
            razor.language_kinds.html
        )
        assert(virtual_document, "Could not find html virtual document")

        local client = virtual_document:get_lsp_client()
        if not client then
            return {}, nil
        end

        local line_count = vim.api.nvim_buf_line_count(virtual_document.buf)
        local last_line = vim.api.nvim_buf_get_lines(virtual_document.buf, -2, -1, false)[1] or ""
        local range_formatting_response = client.request_sync("textDocument/rangeFormatting", {
            textDocument = vim.lsp.util.make_text_document_params(virtual_document.buf),
            range = {
                start = {
                    line = 0,
                    character = 0,
                },
                ["end"] = {
                    line = line_count - 1,
                    character = last_line:len(),
                },
            },
            options = result.options,
        }, nil, virtual_document.buf)
        assert(range_formatting_response, "textDocument/rangeFormatting from virtual LSP return no error or result")

        if range_formatting_response.err ~= nil then
            return nil, err
        end

        local edits = {}
        for _, html_edit in ipairs(range_formatting_response.result) do
            vim.list_extend(edits, format.compute_minimal_edits(virtual_document.buf, html_edit))
        end

        return { edits = edits }
    end,
    ["razor/htmlOnTypeFormatting"] = not_implemented,
    ["razor/simplifyMethod"] = not_implemented,
    ["razor/formatNewFile"] = not_implemented,
    ["razor/inlayHint"] = not_implemented,
    ["razor/inlayHintResolve"] = not_implemented,

    -- VS Windows only at the moment, but could/should be migrated
    ["razor/documentSymbol"] = not_implemented,
    ["razor/rename"] = not_implemented,
    ["razor/hover"] = not_implemented,
    ["razor/definition"] = not_implemented,
    ["razor/documentHighlight"] = not_implemented,
    ["razor/signatureHelp"] = not_implemented,
    ["razor/implementation"] = not_implemented,
    ["razor/references"] = not_implemented,

    -- Called to get C# diagnostics from Roslyn when publishing diagnostics for VS Code
    ["razor/csharpPullDiagnostics"] = not_implemented,
    ["textDocument/colorPresentation"] = not_supported,
    ["razor/completion"] = require("rzls.handlers.completion"),
}
