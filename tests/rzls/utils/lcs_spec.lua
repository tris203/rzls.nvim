local lcs = require("rzls.utils.lcs")
local kind = lcs.edit_kind

describe("lcs", function()
    it("correctly calculates diff for saturday/sunday", function()
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
        assert.are.same(expected, edits)
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
        assert.are.same(expected, edits)
    end)

    it("should diff new lines correctly", function()
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
        assert.are.same(expected, edits)
    end)
end)
