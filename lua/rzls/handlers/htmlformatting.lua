local documentstore = require("rzls.documentstore")
local format = require("rzls.utils.format")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local empty_response = {}

---@class rzls.htmlFormattingParams
---@field textDocument lsp.TextDocumentIdentifier
---@field hostDocumentVersion integer
---@field options lsp.FormattingOptions

---@param err lsp.ResponseError
---@param result rzls.htmlFormattingParams
---@param _ctx lsp.HandlerContext
---@param _config table
return function(err, result, _ctx, _config)
    local start = vim.uv.hrtime()
    if err then
        vim.notify("Error in razor/htmlFormatting", vim.log.levels.ERROR, { title = "rzls.nvim" })
        return {}, nil
    end

    local virtual_document = documentstore.get_virtual_document(
        result.textDocument.uri,
        razor.language_kinds.html,
        result.hostDocumentVersion
    )
    if not virtual_document then
        return empty_response, nil
    end

    local lines = virtual_document:lines()
    local line_count = #lines
    local last_line = lines[line_count]

    while last_line == "" do
        -- Blankline at the end of the file causes the whole file to need to diffed which is slow
        -- https://github.com/tris203/rzls.nvim/issues/41
        Log.rzlsnvim = string.format("Removing blank line at %d", line_count)
        line_count = line_count - 1
        last_line = lines[line_count]
        table.remove(lines)
    end

    ---@type lsp.TextEdit[]?
    local range_formatting_response =
        virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_rangeFormatting, {
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
        })

    if not range_formatting_response then
        return empty_response
    end

    local edits = {}
    for _, html_edit in ipairs(range_formatting_response) do
        vim.list_extend(edits, format.compute_minimal_edits(lines, html_edit))
    end
    local stop = vim.uv.hrtime()

    Log.rzlsnvim = string.format("Formatting took %dms", (stop - start) / 1e6)

    return { edits = edits }
end
