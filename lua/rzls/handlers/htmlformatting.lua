local documentstore = require("rzls.documentstore")
local format = require("rzls.utils.format")
local razor = require("rzls.razor")

---@class rzls.htmlFormattingParams
---@field textDocument lsp.TextDocumentIdentifier
---@field _razor_hostDocumentVersion integer
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
    assert(virtual_document, "Could not find html virtual document")

    local client = virtual_document:get_lsp_client()
    if not client then
        return {}, nil
    end

    local lines = virtual_document:lines()
    local line_count = #lines
    local last_line = lines[line_count]
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
        vim.list_extend(edits, format.compute_minimal_edits(virtual_document:lines(), html_edit))
    end

    return { edits = edits }
end
