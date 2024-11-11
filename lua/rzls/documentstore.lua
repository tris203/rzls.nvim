local razor = require("rzls.razor")
local utils = require("rzls.utils")
local VirtualDocument = require("rzls.virtual_document")
local Log = require("rzls.log")

---@class rzls.ProjectedDocuments
---@field virtual_html rzls.ProjectedDocument
---@field virtual_csharp rzls.ProjectedDocument

---@class rzls.ProjectedDocument
---@field buf number
---@field hostDocumentVersion number
---@field content string

local M = {}

---@type rzls.VirtualDocument<string, table<razor.LanguageKind, rzls.VirtualDocument>>
local virtual_documents = {}

---comment
---@param uri string
---@param suffix razor.VirtualSuffix?
---@return number
local function get_or_create_vbuffer_for_uri(uri, suffix)
    local name = uri .. razor.virtual_suffixes[suffix]
    local buf = vim.uri_to_bufnr(name)
    return buf
end

---Registers virtual buffers for the given file path
---@param current_file string
function M.register_vbufs_by_path(current_file)
    -- open virtual files
    --
    current_file = vim.uri_from_fname(current_file)

    if not virtual_documents[current_file] then
        local buf = vim.uri_to_bufnr(current_file)
        virtual_documents[current_file] = VirtualDocument:new(buf, razor.language_kinds.razor)
    end

    if virtual_documents[current_file][razor.language_kinds.csharp] == nil then
        local buf = get_or_create_vbuffer_for_uri(current_file, "csharp")
        vim.defer_fn(function()
            -- Defer setting buftype to nowrite to let LSP attach
            vim.api.nvim_set_option_value("buftype", "nowrite", { buf = buf })
        end, 250)

        virtual_documents[current_file][razor.language_kinds.csharp] =
            VirtualDocument:new(buf, razor.language_kinds.csharp)
    end

    if virtual_documents[current_file][razor.language_kinds.html] == nil then
        local buf = get_or_create_vbuffer_for_uri(current_file, "html")
        vim.defer_fn(function()
            -- Defer setting buftype to nowrite to let LSP attach
            vim.api.nvim_set_option_value("buftype", "nowrite", { buf = buf })
        end, 250)

        virtual_documents[current_file][razor.language_kinds.html] = VirtualDocument:new(buf, razor.language_kinds.html)
    end
end

---@param result VBufUpdate
---@param language_kind razor.LanguageKind
function M.update_vbuf(result, language_kind)
    M.register_vbufs_by_path(result.hostDocumentFilePath)
    local uri = vim.uri_from_fname(result.hostDocumentFilePath)
    local virtual_document = virtual_documents[uri][language_kind]

    virtual_document:update_content(result)

    local buf_eol = utils.buffer_eol(virtual_document.buf)
    local lines = vim.fn.split(virtual_document.content, buf_eol, true)
    vim.api.nvim_buf_set_lines(virtual_document.buf, 0, -1, false, lines)
end

---Creates virtual buffers for the given source buffer
---@param source_buf integer
function M.register_vbufs(source_buf)
    -- local currentFile = vim.api.nvim_buf_get_name(source_buf)
    local currentFile = vim.uri_from_bufnr(source_buf)
    currentFile = vim.uri_to_fname(currentFile)
    return M.register_vbufs_by_path(currentFile)
end

---@async
---@param uri string
---@param type razor.LanguageKind
---@param version integer | "any"?
---@return rzls.VirtualDocument | nil
function M.get_virtual_document(uri, type, version)
    local doc = virtual_documents[uri]
    if type == razor.language_kinds.razor then
        return doc
    end
    assert(version, "version is required for virtual documents")

    ---@type rzls.VirtualDocument
    local virtual_document = doc and doc[type]

    if virtual_document == nil then
        return nil
    end

    if version == "any" or virtual_document.host_document_version == version then
        return virtual_document
    end

    local current_coroutine = coroutine.running()
    local dispose_handler = virtual_document.change_event:on(function()
        coroutine.resume(current_coroutine)
    end)

    while virtual_document.host_document_version < version do
        coroutine.yield()
    end

    dispose_handler()

    -- The client might be ahead of requested version due to other document
    -- changes while we were synchronizing
    if virtual_document.host_document_version ~= version then
        Log.rzlsnvim = string.format(
            'Mismatch between virtual document version. Uri: "%s". Server: %d. Client: %d',
            virtual_document.path,
            version,
            virtual_document.host_document_version
        )
    end

    return virtual_document
end

local pipe_name
---@param client vim.lsp.Client
function M.initialize(client)
    pipe_name = utils.uuid()

    local function initialize_roslyn()
        local roslyn_client = vim.lsp.get_clients({ name = "roslyn" })[1]
        roslyn_client.notify("razor/initialize", {
            pipeName = pipe_name,
        })

        client.notify("razor/namedPipeConnect", {
            pipeName = pipe_name,
        })
    end

    vim.notify("Connected to roslyn via pipe:" .. pipe_name, vim.log.levels.INFO, { title = "rzls.nvim" })

    initialize_roslyn()
end

local state = {
    get_docstore = function()
        return virtual_documents
    end,
    get_roslyn_pipe = function()
        return pipe_name
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
