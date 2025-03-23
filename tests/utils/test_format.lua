local format = require("rzls.utils.format")
local eq = MiniTest.expect.equality

---@return lsp.TextEdit
local function lsp_edit(new_text, start_line, start_char, end_line, end_char)
    return {
        newText = new_text,
        range = {
            start = {
                line = start_line,
                character = start_char,
            },
            ["end"] = {
                line = end_line,
                character = end_char,
            },
        },
    }
end

describe("format", function()
    it("computes minimal text edits for a buffer", function()
        local source_text = [[
foo
    bar
        baz
]]
        local source_lines = vim.split(source_text, "\n")

        local targe_text = [[
foo
bar
baz
]]
        local target_lines = vim.split(targe_text, "\n")

        -- This edit replaces the full document
        local full_replacement_edit =
            lsp_edit(table.concat(target_lines, "\n"), 0, 0, #source_lines - 1, source_lines[#source_lines]:len())

        local minimal_edits = format.compute_minimal_edits(source_lines, full_replacement_edit)

        -- Only contain edits that remove spaces of the source document to match the target
        local expected = {
            lsp_edit("", 1, 0, 1, 4),
            lsp_edit("", 2, 0, 2, 8),
        }

        eq(expected, minimal_edits)
    end)
end)
