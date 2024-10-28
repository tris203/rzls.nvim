local utils = require("rzls.utils")
local razor = require("rzls.razor")
local nio = require("nio")

---@class rzls.VirtualDocument
---@field buf number
---@field path string
---@field host_document_version number
---@field content string
---@field kind razor.LanguageKind
---@field pre_provisional_content string|nil
---@field pre_resolve_provisional_content string|nil
---@field provisional_edit_at number|nil
---@field resolve_provisional_edit_at number|nil
---@field provisional_dot_position string | nil
local VirtualDocument = {}

VirtualDocument.__index = VirtualDocument

---@param bufnr integer
---@param kind razor.LanguageKind
---@return rzls.VirtualDocument
function VirtualDocument:new(bufnr, kind)
    local virtual_document = setmetatable({
        buf = bufnr,
        host_document_version = 0,
        path = vim.api.nvim_buf_get_name(bufnr),
        kind = kind,
    }, self)

    return virtual_document
end

---@param content string
---@param change Change
local function get_edited_content(content, change)
    local before = vim.fn.strpart(content, 0, change.span.start)
    local after = vim.fn.strpart(content, change.span.start + change.span.length)

    return before .. change.newText .. after
end

---@param result VBufUpdate
function VirtualDocument:update_content(result)
    for _, change in ipairs(vim.fn.reverse(result.changes)) do
        self.content = get_edited_content(self.content, change)
    end

    self.host_document_version = result.hostDocumentVersion
end

---@return vim.lsp.Client|nil
function VirtualDocument:get_lsp_client()
    local lsp_names = {
        [razor.language_kinds.html] = "html",
        [razor.language_kinds.csharp] = "roslyn",
    }

    return vim.lsp.get_clients({ bufnr = self.buf, name = lsp_names[self.kind] })[1]
end

---@return nio.lsp.Client|nil
function VirtualDocument:get_nio_lsp_client()
    local lsp_names = {
        [razor.language_kinds.html] = "html",
        [razor.language_kinds.csharp] = "roslyn",
    }

    return nio.lsp.get_clients({ bufnr = self.buf, name = lsp_names[self.kind] })[1]
end

---@param index number
function VirtualDocument:add_provisional_dot_at(index)
    if self.provisional_edit_at == index then
        return
    end

    -- reset provisional edits
    self:remove_provisional_dot()
    self.resolve_provisional_edit_at = nil
    self.provisional_dot_position = nil

    local new_content = get_edited_content(self.content, {
        newText = ".",
        span = {
            start = index,
            ["end"] = index,
            length = ("."):len(),
        },
    })

    self.pre_provisional_content = self.content
    self.provisional_edit_at = index
    self.content = new_content
end

function VirtualDocument:remove_provisional_dot()
    if self.provisional_edit_at and self.pre_provisional_content then
        self.content = self.pre_provisional_content
        self.resolve_provisional_edit_at = self.provisional_edit_at
        self.provisional_edit_at = nil
        self.pre_provisional_content = nil

        return true
    end

    return false
end

---@param position lsp.Position
function VirtualDocument:index_of_position(position)
    local eol = utils.buffer_eol(self.buf)

    local content = self.content
    local line_number = 0
    local index = 0

    for line in vim.gsplit(content, eol, { plain = true }) do
        if line_number == position.line then
            return index + position.character
        end
        index = index + line:len() + eol:len()
        line_number = line_number + 1
    end

    return -1
end

return VirtualDocument
