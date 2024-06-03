---@class rzls.ProjectedDocuments
---@field virtualHTML rzls.ProjectedDocument
---@field virtualCSharp rzls.ProjectedDocument

---@class rzls.ProjectedDocument
---@field buf number
---@field hostDocumentVersion number

local M = {}

local projectedHTMLSuffix = "__virtual.html"
local projectedCSharpSuffix = "__virtual.cs"

---@type table<string, rzls.ProjectedDocuments>
local projectedDocuments = {}

---Updates the C# buffer with the new content
---@param result any
function M.update_csharp_vbuf(result)
	local wasEmpty = result.previousWasEmpty
	local targetBuf = projectedDocuments[result.hostDocumentFilePath].virtualCSharp.buf
	for _, change in ipairs(result.changes) do
		if wasEmpty then
			local lines = vim.fn.split(change.newText, "\n")
			vim.api.nvim_buf_set_lines(targetBuf, 0, -1, false, lines)
			return
		end
		local currentText = table.concat(vim.api.nvim_buf_get_lines(targetBuf, 0, -1, false), "\n")
		local startChar = change.span.start + 1
		local endChar = startChar + change.span.length
		local before = string.sub(currentText, 1, startChar - 1)
		local after = string.sub(currentText, endChar, -1)
		local newText = change.newText
		local newContent = before .. newText .. after
		local lines = vim.fn.split(newContent, "\n")
		vim.api.nvim_buf_set_lines(targetBuf, 0, -1, false, lines)
		vim.print(
			"Updating C# buffer for "
			.. result.hostDocumentFilePath
			.. " from version "
			.. projectedDocuments[result.hostDocumentFilePath].virtualCSharp.hostDocumentVersion
			.. " to "
			.. result.hostDocumentVersion
		)
		projectedDocuments[result.hostDocumentFilePath].virtualCSharp.hostDocumentVersion = result.hostDocumentVersion
	end
end

---Updates the HTML buffer with the new content
---@param result any
function M.update_html_vbuf(result)
	local wasEmpty = result.previousWasEmpty
	local targetBuf = projectedDocuments[result.hostDocumentFilePath].virtualHTML.buf
	for _, change in ipairs(result.changes) do
		if wasEmpty then
			local lines = vim.fn.split(change.newText, "\n")
			vim.api.nvim_buf_set_lines(targetBuf, 0, -1, false, lines)
			return
		end
		local currentText = table.concat(vim.api.nvim_buf_get_lines(targetBuf, 0, -1, false), "\n")
		local startChar = change.span.start + 1
		local endChar = startChar + change.span.length
		local before = string.sub(currentText, 1, startChar - 1)
		local after = string.sub(currentText, endChar, -1)
		local newText = change.newText
		local newContent = before .. newText .. after
		local lines = vim.fn.split(newContent, "\n")
		vim.api.nvim_buf_set_lines(targetBuf, 0, -1, false, lines)
		vim.print(
			"Updating HTML buffer for "
			.. result.hostDocumentFilePath
			.. " from version "
			.. projectedDocuments[result.hostDocumentFilePath].virtualHTML.hostDocumentVersion
			.. " to "
			.. result.hostDocumentVersion
		)
		projectedDocuments[result.hostDocumentFilePath].virtualHTML.hostDocumentVersion = result.hostDocumentVersion
	end
end

---comment
---@param source_buf integer
function M.create_vbuf(source_buf)

	local currentFile = vim.api.nvim_buf_get_name(source_buf)
	vim.print("Creating virtual buffers for " .. currentFile)
	--open virtual files
	local virtualHTML = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(virtualHTML, currentFile .. projectedHTMLSuffix)
	vim.print("Virtual HTML buffer: " .. virtualHTML)
	local virtualCSharp = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(virtualCSharp, currentFile .. projectedCSharpSuffix)
	vim.print("Virtual C# buffer: " .. virtualCSharp)
	projectedDocuments[currentFile] = {
		virtualHTML = { buf = virtualHTML, hostDocumentVersion = 0 },
		virtualCSharp = { buf = virtualCSharp, hostDocumentVersion = 0 },
	}
end

return M
