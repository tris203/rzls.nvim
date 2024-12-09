local razor = require("rzls.razor")
local utils = require("rzls.utils")
local VirtualDocument = require("rzls.virtual_document")
local Log = require("rzls.log")

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

---Discover if doc is already open
---@param uri string
---@return integer?
local function document_is_open(uri)
    local opened_buffers = vim.api.nvim_list_bufs()
    for i = 1, #opened_buffers do
        local buf = opened_buffers[i]
        local buf_uri = vim.uri_from_bufnr(buf)
        if buf_uri == uri then
            return opened_buffers[i]
        end
    end
end

---Registers virtual buffers for the given file path
---@param current_file string
---@param ensure_open boolean
function M.register_vbufs_by_path(current_file, ensure_open)
    -- open virtual files
    --
    current_file = vim.uri_from_fname(current_file)

    if not virtual_documents[current_file] then
        local opened = document_is_open(current_file)
        if not opened and not ensure_open then
            virtual_documents[current_file] = VirtualDocument:new(nil, razor.language_kinds.razor, current_file)
        else
            local buf = vim.uri_to_bufnr(current_file)
            virtual_documents[current_file] = VirtualDocument:new(buf, razor.language_kinds.razor)
        end
    end

    if ensure_open then
        local buf = vim.uri_to_bufnr(current_file)
        vim.notify(buf .. "updating buf for " .. current_file)
        ---@type rzls.VirtualDocument
        local vd = virtual_documents[current_file]
        local success = vd:update_bufnr(buf)
        assert(success, "Failed to update bufnr for " .. current_file)
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
    M.register_vbufs_by_path(result.hostDocumentFilePath, false)
    local uri = vim.uri_from_fname(result.hostDocumentFilePath)
    ---@type rzls.VirtualDocument
    local virtual_document = virtual_documents[uri][language_kind]

    virtual_document:update_content(result)
    virtual_document.checksum = result.checksum
    virtual_document.checksum_algorithm = result.checksumAlgorithm or 1
    virtual_document.encoding_code_page = result.encodingCodePage
    virtual_document.edits = result.changes

    local buf_eol = utils.buffer_eol(virtual_document.buf)
    local lines = vim.fn.split(virtual_document.content, buf_eol, true)
    vim.api.nvim_buf_set_lines(virtual_document.buf, 0, -1, false, lines)

    local roslyn = virtual_document:get_lsp_client()
    ---@type razor.DynamicFileUpdatedParams
    local params = {
        razorDocument = {
            uri = virtual_documents[uri].uri,
        },
    }

    if not roslyn then
        ---TODO: is this right? there is no roslyn to notify
        return
    end

    --=TODO: Remove when 0.11 only
    ---@diagnostic disable-next-line: param-type-mismatch
    roslyn.notify(razor.notification.razor_dynamicFileInfoChanged, params)
end

---Refreshes parent views of the given virtual document
---@param result VBufUpdate
function M.refresh_parent_views(result)
    local uri = vim.uri_from_fname(result.hostDocumentFilePath)
    ---@type rzls.VirtualDocument?
    local rvd = virtual_documents[uri]
    if not rvd or rvd.kind ~= razor.language_kinds.razor then
        assert(false, "Not a razor document")
        return
    end
    if vim.lsp.inlay_hint.is_enabled({ bufnr = rvd.buf }) then
        vim.lsp.inlay_hint.enable(true, { bufnr = rvd.buf })
    end
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
        Log.rzlsnvim = string.format('Virtual document not found. Uri: "%s". LanguageKind: %d', uri, type)
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

        --=TODO: Remove when 0.11 only
        ---@diagnostic disable-next-line: param-type-mismatch
        roslyn_client.notify(razor.notification.razor_initialize, {
            pipeName = pipe_name,
        })

        --=TODO: Remove when 0.11 only
        ---@diagnostic disable-next-line: param-type-mismatch
        client.notify(razor.notification.razor_namedPipeConnect, {
            pipeName = pipe_name,
        })
    end

    vim.notify("Connected to roslyn via pipe:" .. pipe_name, vim.log.levels.INFO, { title = "rzls.nvim" })

    initialize_roslyn()
    vim.lsp.semantic_tokens.force_refresh(0)
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
