local razor = require("rzls.razor")
local utils = require("rzls.utils")
local EventEmitter = require("rzls.eventemitter")
local Log = require("rzls.log")

---@class rzls.VirtualDocument
---@field buf number
---@field path string
---@field host_document_version number
---@field content string
---@field kind razor.LanguageKind
---@field change_event rzls.EventEmitter
---@field pre_provisional_content string|nil
---@field pre_resolve_provisional_content string|nil
---@field provisional_edit_at number|nil
---@field resolve_provisional_edit_at number|nil
---@field provisional_dot_position lsp.Position | nil
local VirtualDocument = {}

VirtualDocument.__index = VirtualDocument

---@param bufnr integer
---@param kind razor.LanguageKind
---@return rzls.VirtualDocument
function VirtualDocument:new(bufnr, kind)
    return setmetatable({
        buf = bufnr,
        host_document_version = 0,
        content = "",
        path = vim.uri_from_bufnr(bufnr),
        kind = kind,
        change_event = EventEmitter:new(),
    }, self)
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

    self.change_event:fire()
end

function VirtualDocument:ensure_content()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, self:lines())
end

---@return vim.lsp.Client|nil
function VirtualDocument:get_lsp_client()
    return vim.lsp.get_clients({ bufnr = self.buf, name = razor.lsp_names[self.kind] })[1]
end

function VirtualDocument:line_count()
    local lines = vim.split(self.content, "\r?\n", { trimempty = false })
    return #lines
end

function VirtualDocument:lines()
    return vim.split(self.content, "\r?\n", { trimempty = false })
end

function VirtualDocument:line_at(line)
    local lines = vim.split(self.content, "\r?\n", { trimempty = false })
    return lines[line]
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

    local new_content = apply_change(self.content, {
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

function VirtualDocument:ensure_resolve_provisional_dot()
    self.remove_provisional_dot(self)

    if self.resolve_provisional_edit_at then
        local new_content = apply_change(self.content, {
            newText = ".",
            span = {
                start = self.resolve_provisional_edit_at,
                ["end"] = self.resolve_provisional_edit_at,
                length = ("."):len(),
            },
        })
        self.pre_resolve_provisional_content = self.content
        self.content = new_content

        return true
    end

    return false
end

function VirtualDocument:remove_resolve_provisional_dot()
    if self.resolve_provisional_edit_at and self.pre_resolve_provisional_content then
        self.content = self.pre_resolve_provisional_content
        self.provisional_edit_at = nil
        self.pre_resolve_provisional_content = nil

        return true
    end

    return false
end

function VirtualDocument:clear_resolve_completion_request_variables()
    self.resolve_provisional_edit_at = nil
    self.provisional_dot_position = nil
end

---@param position lsp.Position
function VirtualDocument:index_of_position(position)
    local eol = utils.buffer_eol(self.buf)

    local content = self.content
    local line_number = 0
    local index = 0

    for line in vim.gsplit(content, eol, { plain = true }) do
        if line_number == position.line then
            return index + position.character - 1
        end
        index = index + line:len() + eol:len()
        line_number = line_number + 1
    end

    return -1
end

---@param position lsp.Position
---@return razor.LanguageQueryResponse|nil    # result on success, nil on failure.
---@return nil|lsp.ResponseError # nil on success, error message on failure.
function VirtualDocument:language_query(position)
    assert(self.kind == razor.language_kinds.razor, "Can only map to document ranges for razor documents")
    local lsp = self:get_lsp_client()
    if not lsp then
        Log.rzlsnvim = "[Language Query]LSP client not found for " .. self.path
        return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InvalidRequest, "LSP client not found")
    end
    local response = lsp.request_sync("razor/languageQuery", {
        position = position,
        uri = vim.uri_from_bufnr(self.buf),
    }, nil, self.buf)
    if not response or response.err then
        Log.rzlsnvim = "Language Query Request failed: " .. vim.inspect(response and response.err)
        return nil,
            response and response.err or vim.lsp.rpc_response_error(
                vim.lsp.protocol.ErrorCodes.InvalidRequest,
                "Language Query request failed"
            )
    end
    return response.result
end

---@param language_kind razor.LanguageKind
---@param ranges lsp.Range[]
---@return razor.MapToDocumentRangesResponse|nil    # result on success, nil on failure.
---@return nil|lsp.ResponseError # nil on success, error message on failure.
function VirtualDocument:map_to_document_ranges(language_kind, ranges)
    assert(self.kind == razor.language_kinds.razor, "Can only map to document ranges for razor documents")
    local lsp = self:get_lsp_client()
    if not lsp then
        Log.rzlsnvim = "[MapRange]LSP client not found for " .. self.path
        return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InvalidRequest, "LSP client not found")
    end
    local response = lsp.request_sync("razor/mapToDocumentRanges", {
        razorDocumentUri = vim.uri_from_bufnr(self.buf),
        kind = language_kind,
        projectedRanges = ranges,
    }, nil, self.buf)
    if not response or response.err then
        Log.rzlsnvim = "Map Document Range Request failed for "
            .. self.path
            .. ": "
            .. vim.inspect(response and response.err)
        return nil,
            response and response.err or vim.lsp.rpc_response_error(
                vim.lsp.protocol.ErrorCodes.InvalidRequest,
                "Map Document Range request failed"
            )
    end
    return response.result
end

--- issues an LSP request to the virtual document.
--- Please use by passing a method from `vim.lsp.protocl.Methods`
--- and type the expected return value as optional.
---@param method string
---@param params table
---@param buf number?
---@return any|nil    # result on success, nil on failure.
---@return nil|lsp.ResponseError # nil on success, error message on failure.
function VirtualDocument:lsp_request(method, params, buf)
    local lsp = self:get_lsp_client()
    if not lsp then
        Log.rzlsnvim = "[" .. method .. "]LSP client not found for " .. self.path
        return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InvalidRequest, "LSP client not found")
    end
    local result = lsp.request_sync(method, params, nil, buf or self.buf)
    if not result or result.err then
        Log.rzlsnvim = "LSP request failed for " .. self.path .. ": " .. vim.inspect(result and result.err)
        return nil,
            result and result.err or vim.lsp.rpc_response_error(
                vim.lsp.protocol.ErrorCodes.InvalidRequest,
                "LSP request failed"
            )
    end
    return result.result, nil
end

return VirtualDocument
