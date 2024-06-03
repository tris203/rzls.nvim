local documentstore = require("rzls.documentstore")

local not_implemented = function(err, result, ctx, config)
	vim.print("Called" .. ctx.method)
	vim.print(vim.inspect(err))
	vim.print(vim.inspect(result))
	vim.print(vim.inspect(ctx))
	vim.print(vim.inspect(config))
	return { nil, { "0", "Not implemented" } }
end

local not_supported = function()
	return { nil, nil }
end

return {
	["textDocument/documentColor"] = function()
		vim.print("textDocument/documentColor")
		return { nil, nil }
	end,
	["razor/updateCSharpBuffer"] = function(_err, result, _ctx, _config)
		documentstore.update_csharp_vbuf(result)
	end,
	["razor/updateHtmlBuffer"] = function(_err, result, _ctx, _config)
		documentstore.update_html_vbuf(result)
	end,
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
	--NOTE: ["razor/updateCSharpBuffer"] = DONE
	--NOTE: ["razor/updateHtmlBuffer"] = DONE
	["razor/provideCodeActions"] = not_implemented,
	["razor/resolveCodeActions"] = not_implemented,
	["razor/provideHtmlColorPresentation"] = not_supported,
	["razor/provideHtmlDocumentColor"] = function()
		return { {}, nil }
	end,
	["razor/provideSemanticTokensRange"] = not_implemented,
	["razor/foldingRange"] = not_implemented,
	["razor/htmlFormatting"] = not_implemented,
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
}
