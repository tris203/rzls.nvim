local lcs = require("rzls.utils.lcs")
local kind = lcs.edit_kind
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("lcs", function()
    it("calculates diff for saturday -> sunday", function()
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
    end)

    it("collapses sequences of edits of the same kind", function()
        local edits = lcs.diff("sunday", "saturday")
        edits = lcs.collapse(edits)

        ---@type rzls.lcs.CollapsedEdit[]
        local expected = {
            { text = "s", kind = kind.unchanged, line = 1 },
            { text = "at", kind = kind.addition, line = 1 },
            { text = "u", kind = kind.unchanged, line = 1 },
            { text = "n", kind = kind.removal, line = 1 },
            { text = "r", kind = kind.addition, line = 1 },
            { text = "day", kind = kind.unchanged, line = 1 },
        }
        eq(expected, edits)
    end)

    it("diffs new lines", function()
        local source = '<div\n\nclass="container d-flex flex-column gap-3 py-3">'
        local target = '<div class="container d-flex flex-column gap-3 py-3">'

        local edits = lcs.diff(source, target)
        edits = lcs.collapse(edits)

        ---@type rzls.lcs.CollapsedEdit[]
        local expected = {
            { text = "<div", kind = kind.unchanged, line = 1 },
            -- new lines should not be included in the colapsed changes
            { text = "", kind = kind.removal, line = 1 },
            { text = "", kind = kind.removal, line = 2 },
            { text = " ", kind = kind.addition, line = 3 },
            { text = 'class="container d-flex flex-column gap-3 py-3">', kind = kind.unchanged, line = 3 },
        }
        eq(expected, edits)
    end)

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

    it("converts edits to lsp.TextEdit's", function()
        local source = '<div\n\nclass="foo">'
        local target = '<div class="bar">'

        local edits = lcs.diff(source, target)
        edits = lcs.collapse(edits)

        local text_edits = lcs.convert_to_text_edits(edits)

        ---@type lsp.TextEdit[]
        local expected = {
            -- Delete first \n
            lsp_edit("", 0, 4, 1, 0),
            -- Delete second \n
            lsp_edit("", 1, 0, 2, 0),
            -- Add space between div and class
            lsp_edit(" ", 2, 0, 2, 0),
            -- Delete foo
            lsp_edit("", 2, 8, 2, 11),
            -- Add bar
            lsp_edit("bar", 2, 11, 2, 11),
        }

        eq(expected, text_edits)
    end)
end)
