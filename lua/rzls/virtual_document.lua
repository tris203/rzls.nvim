local razor = require("rzls.razor")
local utils = require("rzls.utils")
local EventEmitter = require("rzls.eventemitter")
local Log = require("rzls.log")

---@class rzls.VirtualDocument
---@field buf? number
---@field uri string
---@field host_document_version number
---@field content string
---@field kind razor.LanguageKind
---@field change_event rzls.EventEmitter
---@field pre_provisional_content string|nil
---@field pre_resolve_provisional_content string|nil
---@field provisional_edit_at number|nil
---@field resolve_provisional_edit_at number|nil
---@field provisional_dot_position lsp.Position | nil
---@field checksum string
---@field checksum_algorithm number
---@field encoding_code_page number
---@field updates VBufUpdate[]
local VirtualDocument = {}

VirtualDocument.__index = VirtualDocument

---@param bufnr? integer
---@param kind razor.LanguageKind
---@param uri? string
---@return rzls.VirtualDocument
function VirtualDocument:new(bufnr, kind, uri)
    assert(kind, "kind is required")
    if bufnr then
        return setmetatable({
            buf = bufnr,
            host_document_version = 0,
            content = "",
            uri = vim.uri_from_bufnr(bufnr),
            kind = kind,
            updates = {},
            change_event = EventEmitter:new(),
        }, self)
    end
    assert(uri, "uri is required if bufnr is not provided")
    return setmetatable({
        buf = nil,
        host_document_version = 0,
        content = "",
        uri = uri,
        kind = kind,
        updates = {},
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

function VirtualDocument:update_content()
    for i, details in ipairs(self.updates) do
        for _, change in ipairs(vim.fn.reverse(details.changes)) do
            self.content = apply_change(self.content, change)
        end
        self.host_document_version = details.hostDocumentVersion
        self.updates[i] = nil
    end

    if self.buf then
        local buf_eol = utils.buffer_eol(self.buf)
        local lines = vim.fn.split(self.content, buf_eol, true)
        vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    end

    self.change_event:fire()
end

---@return VBufUpdate[] edits
---@return string original_checksum
---@return number original_checksum_algorithm
---@return number|vim.NIL original_encoding_code_page
function VirtualDocument:apply_edits()
    local original_checksum = self.checksum or ""
    local original_checksum_algorithm = self.checksum_algorithm or 1
    local original_encoding_code_page = self.encoding_code_page or vim.NIL

    local edits = vim.deepcopy(self.updates)
    if not vim.tbl_isempty(edits) then
        self:update_content()
    end

    return edits, original_checksum, original_checksum_algorithm, original_encoding_code_page
end

---update the bufnr of the virtual document
---@param bufnr number
---@return boolean
function VirtualDocument:update_bufnr(bufnr)
    self.buf = bufnr
    assert(self.buf, "bufnr is nil")
    return true
end

function VirtualDocument:ensure_content()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, self:lines())
end

---@return vim.lsp.Client|nil
function VirtualDocument:get_lsp_client()
    ---TODO: virtual docs might not be real, so may not have a buf
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
        Log.rzlsnvim = "[Language Query]LSP client not found for " .. self.uri
        return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InvalidRequest, "LSP client not found")
    end
    --=TODO: Remove when 0.11 only
    ---@diagnostic disable-next-line: param-type-mismatch
    local response = lsp.request_sync("razor/languageQuery", {
        position = position,
        uri = self.uri,
        --=TODO: Remove when 0.11 only
        ---@diagnostic disable-next-line: param-type-mismatch
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
        Log.rzlsnvim = "[MapRange]LSP client not found for " .. self.uri
        return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InvalidRequest, "LSP client not found")
    end

    --=TODO: Remove when 0.11 only
    ---@diagnostic disable-next-line: param-type-mismatch
    local response = lsp.request_sync("razor/mapToDocumentRanges", {
        razorDocumentUri = self.uri,
        kind = language_kind,
        projectedRanges = ranges,
        --=TODO: Remove when 0.11 only
        ---@diagnostic disable-next-line: param-type-mismatch
    }, nil, self.buf)
    if not response or response.err then
        Log.rzlsnvim = "Map Document Range Request failed for "
            .. self.uri
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
        Log.rzlsnvim = "[" .. method .. "]LSP client not found for " .. self.uri
        return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InvalidRequest, "LSP client not found")
    end
    --=TODO: Remove when 0.11 only
    ---@diagnostic disable-next-line: param-type-mismatch
    local result = lsp.request_sync(method, params, nil, buf or self.buf)
    if not result or result.err then
        Log.rzlsnvim = "LSP request failed for " .. self.uri .. ": " .. vim.inspect(result and result.err)
        Log.rzlsnvim = vim.inspect({ method = method, params = params })
        return nil,
            result and result.err or vim.lsp.rpc_response_error(
                vim.lsp.protocol.ErrorCodes.InvalidRequest,
                "LSP request failed"
            )
    end
    return result.result, nil
end

return VirtualDocument
