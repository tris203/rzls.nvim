local razor = require("rzls.razor")
local nio = require("nio")

---@class rzls.VirtualDocument
---@field buf number
---@field path string
---@field host_document_version number
---@field content string
---@field kind razor.LanguageKind
local VirtualDocument = {}

VirtualDocument.__index = VirtualDocument

---@param bufnr integer|string
---@param kind razor.LanguageKind
---@return rzls.VirtualDocument
function VirtualDocument:new(bufnr, kind)
    if type(bufnr) == "string" then
        local virtual_document = setmetatable({
            buf = vim.uri_to_bufnr("file://" .. bufnr),
            host_document_version = 0,
            content = "",
            path = bufnr,
            kind = kind,
        }, self)
        return virtual_document
    elseif type(bufnr) == "number" then
        local virtual_document = setmetatable({
            buf = bufnr,
            host_document_version = 0,
            content = "",
            path = vim.api.nvim_buf_get_name(bufnr),
            kind = kind,
        }, self)
        return virtual_document
    end
    error("Invalid buffer number")
end

---@param content string
---@param change Change
local function apply_change(content, change)
    local before = vim.fn.strcharpart(content, 0, change.span.start)
    local after = vim.fn.strcharpart(content, change.span.start + change.span.length)

    return before .. change.newText .. after
end

---@param result VBufUpdate
function VirtualDocument:update_content(result)
    for _, change in ipairs(vim.fn.reverse(result.changes)) do
        self.content = apply_change(self.content, change)
    end

    self.host_document_version = result.hostDocumentVersion
end

---@return vim.lsp.Client|nil
function VirtualDocument:get_lsp_client()
    return vim.lsp.get_clients({ bufnr = self.buf, name = razor.lsp_names[self.kind] })[1]
end

---@return nio.lsp.Client|nil
function VirtualDocument:get_nio_lsp_client()
    return nio.lsp.get_clients({ bufnr = self.buf, name = razor.lsp_names[self.kind] })[1]
end

return VirtualDocument
