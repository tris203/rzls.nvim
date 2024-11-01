local format = require("rzls.utils.format")

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

local function fixture_path(fixture_name)
    return vim.fs.joinpath(vim.uv.cwd(), "tests", "rzls", "fixtures", fixture_name)
end

local function load_file(path)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_call(buf, function()
        vim.cmd.edit({ args = { path } })
    end)

    return buf
end

describe("format", function()
    it("computes minimal text edits for a buffer", function()
        local source_path = fixture_path("format_spec_unformatted.txt")
        local source_buf = load_file(source_path)
        local source_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, true)

        local target_path = fixture_path("format_spec_formatted.txt")
        local target_buf = load_file(target_path)
        local target_lines = vim.api.nvim_buf_get_lines(target_buf, 0, -1, true)

        -- This edit replaces the full document
        local full_replacement_edit =
            lsp_edit(table.concat(target_lines, "\n"), 0, 0, #source_lines - 1, source_lines[#source_lines]:len())

        local minimal_edits = format.compute_minimal_edits(source_buf, full_replacement_edit)

        -- Only contain edits that remove spaces in from of source document to match target
        local expected = {
            lsp_edit("", 1, 0, 1, 4),
            lsp_edit("", 2, 0, 2, 8),
        }

        assert.are.same(expected, minimal_edits)
    end)
end)
