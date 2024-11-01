local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local nio = require("nio")

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
    ["razor/provideSemanticTokensRanges"] = not_implemented,
    ["razor/mapCode"] = not_implemented,

    -- VS Windows and VS Code
    ---@param err lsp.ResponseError
    ---@param result VBufUpdate
    ---@param _ctx lsp.HandlerContext
    ---@param _config? table
    ---@return razor.ProvideSemanticTokensResponse|nil
    ---@return lsp.ResponseError|nil
    ["razor/updateCSharpBuffer"] = function(err, result, _ctx, _config)
        assert(not err, vim.inspect(err))
        documentstore.update_vbuf(result, razor.language_kinds.csharp)
    end,
    ---@param err lsp.ResponseError
    ---@param result VBufUpdate
    ---@param _ctx lsp.HandlerContext
    ---@param _config? table
    ---@return razor.ProvideSemanticTokensResponse|nil
    ---@return lsp.ResponseError|nil
    ["razor/updateHtmlBuffer"] = function(err, result, _ctx, _config)
        assert(not err, vim.inspect(err))
        documentstore.update_vbuf(result, razor.language_kinds.html)
    end,
    ["razor/provideCodeActions"] = not_implemented,
    ["razor/resolveCodeActions"] = not_implemented,
    ["razor/provideHtmlColorPresentation"] = not_supported,
    ["razor/provideHtmlDocumentColor"] = function(err, _result, _ctx, _config)
        if err then
            vim.print("Error in razor/provideHtmlDocumentColor")
            return {}, nil
        end
        -- local _targetDoc = result.textDocument.uri
        -- local _targetVersion = result._razor_hostDocumentVersion
        --TODO: Function that will look through the virtual HTML buffer and return color locations
        return {}, nil
    end,
    ---@param err lsp.ResponseError
    ---@param result razor.ProvideSemanticTokensParams
    ---@param _ctx lsp.HandlerContext
    ---@param _config? table
    ---@return razor.ProvideSemanticTokensResponse|nil
    ---@return lsp.ResponseError|nil
    ["razor/provideSemanticTokensRange"] = function(err, result, _ctx, _config)
        nio.run(function()
            assert(not err, err)

            local virtual_document = documentstore.get_virtual_document(
                result.textDocument.uri,
                result.requiredHostDocumentVersion,
                razor.language_kinds.csharp
            )
            assert(virtual_document, "Could not find virtual document")

            -- local virtual_buf_client = nio.lsp.get_clients({ bufnr = virtual_document.buf })[1]
        end)
    end,
    ["razor/foldingRange"] = not_implemented,

    ["razor/htmlFormatting"] = require("rzls.handlers.htmlformatting"),
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
    [vim.lsp.protocol.Methods.textDocument_hover] = require("rzls.handlers.hover"),
}
