local lcs = require("rzls.utils.lcs")
local utils = require("rzls.utils")
local M = {}

---@param source string
---@param target string
---@param line_start? integer
---@param character_start? integer
local function compute_minimal_diff(source, target, line_start, character_start)
    local edits = lcs.diff(source, target)
    local collapsed_edits = lcs.collapse(edits)

    return lcs.convert_to_text_edits(collapsed_edits, line_start, character_start)
end

---@param source_buf integer
---@param target_edit lsp.TextEdit
---@return lsp.TextEdit[]
function M.compute_minimal_edits(source_buf, target_edit)
    local source_start_row = target_edit.range.start.line
    local source_start_col = target_edit.range.start.character
    local source_end_row = target_edit.range["end"].line
    local source_end_col = target_edit.range["end"].character

    local source_lines =
        vim.api.nvim_buf_get_text(source_buf, source_start_row, source_start_col, source_end_row, source_end_col, {})
    source_lines = vim.tbl_map(function(line)
        -- strip CR characters when neovim fails to identify the correct file format
        if vim.endswith(line, "\r") then
            return line:sub(1, -2)
        end
        return line
    end, source_lines)
    local target_lines = vim.split(target_edit.newText, "\r?\n")

    local source_text = table.concat(source_lines, "\n")
    local target_text = table.concat(target_lines, "\n")

    local indices = vim.diff(source_text, target_text, {
        algorithm = "histogram",
        result_type = "indices",
    })
    assert(type(indices) == "table")

    ---@type lsp.TextEdit[]
    local edits = {}
    for _, idx in ipairs(indices) do
        local source_line_start, source_line_count, target_line_start, target_line_count = unpack(idx)
        local source_line_end = source_line_start + source_line_count - 1
        local target_line_end = target_line_start + target_line_count - 1

        local source = table.concat(source_lines, "\n", source_line_start, source_line_end)
        local target = table.concat(target_lines, "\n", target_line_start, target_line_end)
        local text_edits =
            compute_minimal_diff(source, target, source_start_row + source_line_start - 1, source_start_col)

        vim.list_extend(edits, text_edits)
    end

    return edits
end

return M
