local lcs = require("rzls.utils.lcs")
local kind = lcs.edit_kind
local eq = MiniTest.expect.equality
local T = MiniTest.new_set()

T["LCS"] = MiniTest.new_set()
T["LCS"]["calculates diff for saturday -> sunday"] = function()
    local edits = lcs.diff("sunday", "saturday")

    ---@type rzls.lcs.Edit[]
    local expected = {
        { text = "s", kind = kind.unchanged },
        { text = "a", kind = kind.addition },
        { text = "t", kind = kind.addition },
        { text = "u", kind = kind.unchanged },
        { text = "n", kind = kind.removal },
        { text = "r", kind = kind.addition },
        { text = "d", kind = kind.unchanged },
        { text = "a", kind = kind.unchanged },
        { text = "y", kind = kind.unchanged },
    }
    eq(expected, edits)
end

T["LCS"]["converts edits to lsp.TextEdit's"] = function()
    local source = '<div\n\nclass="foo">'
    local target = '<div class="foo">'

    local edits = lcs.diff(source, target)
    local text_edits = lcs.to_lsp_edits(edits, 0, 0)

    ---@type lsp.TextEdit[]
    local expected = {
        -- Replaces "\n\n" with " "
        {
            newText = " ",
            range = {
                start = {
                    line = 0,
                    character = 4,
                },
                ["end"] = {
                    line = 2,
                    character = 0,
                },
            },
        },
    }

    eq(expected, text_edits)
end

T["LCS"]["applies converted lsp.TextEdit's to buffer"] = function()
    local source = '<div class="bar">'
    local target = '<div\n\nclass="bar">'

    local edits = lcs.diff(source, target)
    local text_edits = lcs.to_lsp_edits(edits, 0, 0)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(source, "\n"))
    vim.lsp.util.apply_text_edits(text_edits, buf, "utf-8")

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    eq(target, table.concat(lines, "\n"))
end

T["LCS"]["applies converted lsp.TextEdit's to buffer with CRLF line endings"] = function()
    local source = '<div class="bar">'
    local target = '<div\r\n\r\nclass="bar">'

    local edits = lcs.diff(source, target)
    local text_edits = lcs.to_lsp_edits(edits, 0, 0)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(source, "\r\n"))
    vim.lsp.util.apply_text_edits(text_edits, buf, "utf-8")

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    eq(target, table.concat(lines, "\r\n"))
end

T["LCS"]["applies converted edits to buffer with multiple errors"] = function()
    local source = [[
<div
            class = "bar">
            <h1> Intentional Leading Space</h1>


                </div>
]]
    local target = [[
<div class="bar">
    <h1> Intentional Leading Space</h1>
</div>
]]

    local edits = lcs.diff(source, target)
    local text_edits = lcs.to_lsp_edits(edits, 0, 0)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(source, "\n"))
    vim.lsp.util.apply_text_edits(text_edits, buf, "utf-8")

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    eq(target, table.concat(lines, "\n"))
end

T["LCS"]["applies edits to unicode characters"] = function()
    local source = "        <h1>💩</h1>"
    local target = "<h1>💩</h1>"

    local edits = lcs.diff(source, target)
    local text_edits = lcs.to_lsp_edits(edits, 0, 0)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(source, "\n"))
    vim.lsp.util.apply_text_edits(text_edits, buf, "utf-16")

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    eq(target, table.concat(lines, "\n"))
end

return T
