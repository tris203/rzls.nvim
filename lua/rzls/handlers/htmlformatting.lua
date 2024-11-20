local documentstore = require("rzls.documentstore")
local format = require("rzls.utils.format")
local razor = require("rzls.razor")

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
        vim.list_extend(edits, format.compute_minimal_edits(virtual_document:lines(), html_edit))
    end

    return { edits = edits }
end
