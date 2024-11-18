local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local not_implemented = function(err, result, ctx, config)
    vim.print("Called " .. ctx.method)
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
    ["razor/provideHtmlDocumentColor"] = require("rzls.handlers.providehtmldocumentcolor"),
    ["razor/provideSemanticTokensRange"] = require("rzls.handlers.providesemantictokensrange"),
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
    ["razor/csharpPullDiagnostics"] = require("rzls.handlers.csharppulldiagnostics"),
    ["textDocument/colorPresentation"] = not_supported,
    ["razor/completion"] = require("rzls.handlers.completion"),
    ["razor/completionItem/resolve"] = require("rzls.handlers.completionitemresolve"),
    ["window/logMessage"] = function(_, result)
        Log.rzls = result.message
        return vim.lsp.handlers[vim.lsp.protocol.Methods.window_logMessage]
    end,
}
