local razor = require("rzls.razor")
local utils = require("rzls.utils")
local VirtualDocument = require("rzls.virtual_document")

---@class rzls.ProjectedDocuments
---@field virtual_html rzls.ProjectedDocument
---@field virtual_csharp rzls.ProjectedDocument

---@class rzls.ProjectedDocument
---@field buf number
---@field hostDocumentVersion number
---@field content string

local M = {}

local virtual_suffixes = {
    html = "__virtual.html",
    csharp = "__virtual.cs",
}

---@type rzls.VirtualDocument<string, table<razor.LanguageKind, rzls.VirtualDocument>>
local virtual_documents = {}

local roslyn_ready = false

---@param name string
---@return number | nil
local function buffer_with_name(name)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name == name then
            return buf
        end
    end
end

local function get_or_create_buffer_for_filepath(filepath, filetype)
    local buf = buffer_with_name(filepath)
    if not buf then
        vim.print(filepath)
        buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, filepath)
        vim.api.nvim_set_option_value("ft", filetype, { buf = buf })
    end

    return buf
end

---Registers virtual buffers for the given file path
---@param current_file string
function M.register_vbufs_by_path(current_file)
    -- open virtual files
    --
    virtual_documents[current_file] = virtual_documents[current_file] or {}

    if vim.tbl_isempty(virtual_documents[current_file]) then
        virtual_documents[current_file] = VirtualDocument:new(current_file, razor.language_kinds.razor)
    end

    if virtual_documents[current_file][razor.language_kinds.csharp] == nil then
        local buf = get_or_create_buffer_for_filepath(current_file .. virtual_suffixes.csharp, "cs")

        virtual_documents[current_file][razor.language_kinds.csharp] =
            VirtualDocument:new(buf, razor.language_kinds.csharp)
    end

    if virtual_documents[current_file][razor.language_kinds.html] == nil then
        local buf = get_or_create_buffer_for_filepath(current_file .. virtual_suffixes.html, "html")

        virtual_documents[current_file][razor.language_kinds.html] = VirtualDocument:new(buf, razor.language_kinds.html)
    end
end

---@param result VBufUpdate
---@param language_kind razor.LanguageKind
function M.update_vbuf(result, language_kind)
    M.register_vbufs_by_path(result.hostDocumentFilePath)
    local virtual_document = virtual_documents[result.hostDocumentFilePath][language_kind]

    virtual_document:update_content(result)

    local buf_eol = utils.buffer_eol(virtual_document.buf)
    local lines = vim.fn.split(virtual_document.content, buf_eol, true)
    vim.api.nvim_buf_set_lines(virtual_document.buf, 0, -1, false, lines)
end

---Creates virtual buffers for the given source buffer
---@param source_buf integer
function M.register_vbufs(source_buf)
    local currentFile = vim.api.nvim_buf_get_name(source_buf)
    return M.register_vbufs_by_path(currentFile)
end

---Converts a RPC return URI to a file path
---@param uri string
---@return string
local function uri_to_path(uri)
    local path = uri:gsub("file://", "")
    return path
end

---@param uri string
---@param _version integer
---@param type razor.LanguageKind
---@return rzls.VirtualDocument
function M.get_virtual_document(uri, _version, type)
    return virtual_documents[uri_to_path(uri)][type]
end

local document_generation_initialized = false

---@param client vim.lsp.Client
function M.initialize(client, root_dir)
    if not roslyn_ready or document_generation_initialized then
        return
    end

    document_generation_initialized = true

    local razor_files = vim.fs.find(function(name)
        return name:match(".*%.razor$")
    end, {
        type = "file",
        limit = math.huge,
        path = root_dir,
    })

    local opened_documents = vim.tbl_keys(virtual_documents)
    for _, razor_file in ipairs(razor_files) do
        if not vim.tbl_contains(opened_documents, razor_file) then
            local razor_buf = get_or_create_buffer_for_filepath(razor_file, "razor")
            vim.api.nvim_buf_call(razor_buf, vim.cmd.edit)
        end
    end

    local pipe_name = utils.uuid()

    ---@type rzls.ProjectedDocument
    local virtual_document = vim.tbl_values(virtual_documents)[1]

    local function initialize_roslyn()
        local initialized = vim.lsp.buf_notify(virtual_document.buf, "razor/initialize", {
            pipeName = pipe_name,
        })

        -- Roslyn might not have been initialized yet. Repeat every seconds until
        -- we can send the notification
        if not initialized then
            local timer = vim.uv.new_timer()
            timer:start(1000, 0, initialize_roslyn)
            return
        end

        client.notify("razor/namedPipeConnect", {
            pipeName = pipe_name,
        })
    end

    initialize_roslyn()
end

local state = {
    get_docstore = function()
        return virtual_documents
    end,
}

setmetatable(M, {
    __index = function(_, k)
        if state[k] then
            return state[k]()
        end
    end,
})
return M
