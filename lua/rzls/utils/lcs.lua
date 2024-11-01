local M = {}

---@class rzls.lcs.Edit
---@field kind rzls.lcs.EditKind
---@field text string
---
---@class rzls.lcs.CollapsedEdit
---@field kind rzls.lcs.EditKind
---@field text string
---@field line integer

---@enum rzls.lcs.EditKind
M.edit_kind = {
    addition = "addition",
    removal = "removal",
    unchanged = "unchanged",
}

--- Computes the Long Common Subequence table.
--- Reference: [https://en.wikipedia.org/wiki/Longest_common_subsequence#Computing_the_length_of_the_LCS]
---@param source string
---@param target string
function M.generate_table(source, target)
    local n = source:len() + 1
    local m = target:len() + 1

    ---@type integer[][]
    local lcs = {}
    for i = 1, n do
        lcs[i] = {}
        for j = 1, m do
            lcs[i][j] = 0
        end
    end

    for i = 1, n do
        for j = 1, m do
            if i == 1 or j == 1 then
                lcs[i][j] = 0
            elseif source:sub(i - 1, i - 1) == target:sub(j - 1, j - 1) then
                lcs[i][j] = 1 + lcs[i - 1][j - 1]
            else
                lcs[i][j] = math.max(lcs[i - 1][j], lcs[i][j - 1])
            end
        end
    end

    return lcs
end

---@generic T
---@param tbl T[]
---@return T[]
local function reverse_table(tbl)
    local ret = {}
    for i = #tbl, 1, -1 do
        table.insert(ret, tbl[i])
    end
    return ret
end

--- Calculates a diff between two strings using LCS
---@param source string
---@param target string
---@return rzls.lcs.Edit[]
function M.diff(source, target)
    local lcs = M.generate_table(source, target)

    local src_idx = source:len() + 1
    local trt_idx = target:len() + 1

    ---@type rzls.lcs.Edit[]
    local edits = {}

    while src_idx ~= 1 or trt_idx ~= 1 do
        if src_idx == 1 then
            table.insert(edits, {
                kind = M.edit_kind.addition,
                text = target:sub(trt_idx - 1, trt_idx - 1),
            })
            trt_idx = trt_idx - 1
        elseif trt_idx == 1 then
            table.insert(edits, {
                kind = M.edit_kind.removal,
                text = source:sub(src_idx - 1, src_idx - 1),
            })
            src_idx = src_idx - 1
        elseif source:sub(src_idx - 1, src_idx - 1) == target:sub(trt_idx - 1, trt_idx - 1) then
            table.insert(edits, {
                kind = M.edit_kind.unchanged,
                text = source:sub(src_idx - 1, src_idx - 1),
            })
            src_idx = src_idx - 1
            trt_idx = trt_idx - 1
        elseif lcs[src_idx - 1][trt_idx] <= lcs[src_idx][trt_idx - 1] then
            table.insert(edits, {
                kind = M.edit_kind.addition,
                text = target:sub(trt_idx - 1, trt_idx - 1),
            })
            trt_idx = trt_idx - 1
        else
            table.insert(edits, {
                kind = M.edit_kind.removal,
                text = source:sub(src_idx - 1, src_idx - 1),
            })
            src_idx = src_idx - 1
        end
    end

    return reverse_table(edits)
end

--- Collapses a sequence of edits of the same kind that are on the same line
---@param edits rzls.lcs.Edit[]
---@return rzls.lcs.CollapsedEdit[]
function M.collapse(edits)
    ---@type rzls.lcs.Edit[]
    local results = {}

    local i = 1
    local line = 1
    while i < #edits do
        local current_text = ""
        local current_kind = edits[i].kind
        local current_line = line

        for j = i, #edits do
            if edits[j].kind ~= current_kind then
                break
            end
            i = i + 1

            if edits[j].text ~= "\n" then
                current_text = current_text .. edits[j].text
            end

            -- Keep the new line in this edit but don't accept anymore edits
            if edits[j].text == "\n" then
                line = line + 1
                break
            end
        end

        table.insert(results, {
            text = current_text,
            kind = current_kind,
            line = current_line,
        })
    end

    return results
end

--- Group edits that belong to the same line
---@param edits rzls.lcs.CollapsedEdit[]
---@return rzls.lcs.CollapsedEdit[][]
function M.group_edits_by_line(edits)
    ---@type rzls.lcs.CollapsedEdit[][]
    local line_edits = {}
    local line = 1
    local i = 1
    while i < #edits do
        line_edits[line] = {
            edits[i],
        }

        for j = i + 1, #edits do
            if edits[j].line ~= edits[i].line then
                break
            end
            table.insert(line_edits[line], edits[j])
            i = i + 1
        end
        line = line + 1
        i = i + 1
    end

    return line_edits
end

---@param edits rzls.lcs.CollapsedEdit[]
---@param line_start? integer
---@param character_start? integer
---@return lsp.TextEdit[]
function M.convert_to_text_edits(edits, line_start, character_start)
    local line_edits = M.group_edits_by_line(edits)
    line_start = line_start or 0
    character_start = character_start or 0

    local character = character_start

    ---@type lsp.TextEdit[]
    local text_edits = {}
    for line, line_edit in ipairs(line_edits) do
        -- LSP lines are 0 based
        line = line + line_start - 1
        for edit_index, edit in ipairs(line_edit) do
            local next_edit = line_edit[edit_index + 1]

            -- if next_edit is nil, it means we are at the last line
            local is_eol = next_edit == nil or edit.line ~= next_edit.line
            -- if we are the last edit on a line, we must place an edit that ends
            -- on the begging of the next line
            local ending_line = is_eol and line + 1 or line
            local ending_character = is_eol and 0 or character

            ---@type lsp.TextEdit
            local text_edit
            if edit.kind == "removal" then
                text_edit = {
                    newText = "",
                    range = {
                        start = {
                            line = line,
                            character = character,
                        },
                        ["end"] = {
                            line = ending_line,
                            character = ending_character + edit.text:len(),
                        },
                    },
                }
            elseif edit.kind == "addition" then
                text_edit = {
                    newText = edit.text,
                    range = {
                        start = {
                            line = line,
                            character = character,
                        },
                        ["end"] = {
                            line = ending_line,
                            character = ending_character,
                        },
                    },
                }
            end
            -- NOTE: unchanged edits should only skip characters

            character = character + edit.text:len()
            if text_edit ~= nil then
                table.insert(text_edits, text_edit)
            end
        end
        character = 0
    end

    return text_edits
end

return M
