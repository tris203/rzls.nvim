local documentstore = require("rzls.documentstore")
local lsp = require("rzls.utils.lsp")
local dsu = require("rzls.utils.documentstore")

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
	["razor/updateCSharpBuffer"] = function(_err, result, _ctx, _config)
		documentstore.update_csharp_vbuf(result)
		--NOTE: ["razor/updateCSharpBuffer"] = DONE
	end,
	["razor/updateHtmlBuffer"] = function(_err, result, _ctx, _config)
		documentstore.update_html_vbuf(result)
		--NOTE: ["razor/updateHtmlBuffer"] = DONE
	end,
	["razor/provideCodeActions"] = not_implemented,
	["razor/resolveCodeActions"] = not_implemented,
	["razor/provideHtmlColorPresentation"] = not_supported,
	["razor/provideHtmlDocumentColor"] = function(err, result, _ctx, _config)
		if err then
			vim.print("Error in razor/provideHtmlDocumentColor")
			return {}, nil
		end
		local _targetDoc = result.textDocument.uri
		local _targetVersion = result._razor_hostDocumentVersion
		--TODO: Function that will look through the virtual HTML buffer and return color locations
		return {}, nil
	end,
	["razor/provideSemanticTokensRange"] = not_implemented,
	["razor/foldingRange"] = not_implemented,

	["razor/htmlFormatting"] = function(err, result, _ctx, _config)
		if err then
			vim.print("Error in razor/htmlFormatting")
			return {}, nil
		end
		local bufnr =
			documentstore.get_virtual_bufnr(result.textDocument.uri, result._razor_hostDocumentVersion, "html")
		if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
			vim.print("No virtual buffer found")
			return {}, nil
		end
		local client = lsp.get_client("html")
		if not client then
			return {}, nil
		end
		local response
		local filename = vim.api.nvim_buf_get_name(bufnr)
		local linecount = dsu.get_virtual_lines_count(bufnr)
		local virtual_htmluri = "file://" .. filename
		vim.print("Formatting virtual HTML buffer: " .. virtual_htmluri)
		vim.print("Range to line " .. linecount)
		vim.print(vim.inspect(result.options))
		client.request("textDocument/rangeFormatting", {
			textDocument = { uri = virtual_htmluri },
			range = {
				start = {
					line = 0,
					character = 0,
				},
				["end"] = {
					line = linecount - 1,
					character = 0,
				},
			},
			options = result.options,
		}, function(suberr, subresult, _subctx, _subconfig)
			vim.print("Formatting virtual HTML buffer: " .. virtual_htmluri .. " DONE")
			if suberr then
				vim.print("Error in subformatting request")
				vim.print(vim.inspect(suberr))
				return {}, nil
			end
			response = subresult
			return {}, nil
		end, bufnr)
		local i = 0
		while not response do
			-- HACK: Make this not ugly and properly wait
			vim.print("Waiting for response")
			vim.wait(100)
			i = i + 1
			if i > 100 then
				vim.print("Timeout")
				break
			end
		end
		--TODO: This works byt the rzr lsp complains that
		-- [WARN][2024-06-05 21:54:34] ...lsp/handlers.lua:626	"[LSP][LanguageServer.Formatting.FormattingContentValidationPass] A format operation is being abandoned because it would add or delete non-whitespace content."
		-- [WARN][2024-06-05 21:54:34] ...lsp/handlers.lua:626	"[LSP][LanguageServer.Formatting.FormattingContentValidationPass] Edit at (0, 0)-(16, 0) adds the non-whitespace content 'REDACTED'."
		-- Need to make the returned edits valid
		vim.print(vim.inspect(response))
		return { edits = response }, nil
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

	["razor/initialize"] = not_implemented,
}
