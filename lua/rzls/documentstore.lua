local razor = require("rzls.razor")
local utils = require("rzls.utils")
local VirtualDocument = require("rzls.virtual_document")
local Log = require("rzls.log")

---@type razor.DynamicFileUpdatedParams[]
local roslyn_notify_queue = {}

local M = {}

---@type rzls.VirtualDocument<string, table<razor.LanguageKind, rzls.VirtualDocument>>
local virtual_documents = {}

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
        ---@type rzls.VirtualDocument
        local vd = virtual_documents[current_file]
        local success = vd:update_bufnr(buf)
        assert(success, "Failed to update bufnr for " .. current_file)
    end

    local csharp_uri = current_file .. razor.virtual_suffixes["csharp"]
    if not virtual_documents[current_file][razor.language_kinds.csharp] then
        local opened = document_is_open(csharp_uri)
        if not opened and not ensure_open then
            virtual_documents[current_file][razor.language_kinds.csharp] =
                VirtualDocument:new(nil, razor.language_kinds.csharp, csharp_uri)
        else
            local buf = vim.uri_to_bufnr(csharp_uri)
            virtual_documents[current_file][razor.language_kinds.csharp] =
                VirtualDocument:new(buf, razor.language_kinds.csharp)
        end
    end

    if ensure_open then
        local buf = vim.uri_to_bufnr(csharp_uri)
        vim.api.nvim_set_option_value("filetype", "cs", { buf = buf })
        ---@type rzls.VirtualDocument
        local cvd = virtual_documents[current_file][razor.language_kinds.csharp]
        local success = cvd:update_bufnr(buf)
        assert(success, "Failed to update bufnr for " .. csharp_uri)
    end

    local html_uri = current_file .. razor.virtual_suffixes["html"]
    if not virtual_documents[current_file][razor.language_kinds.html] then
        local opened = document_is_open(html_uri)
        if not opened and not ensure_open then
            virtual_documents[current_file][razor.language_kinds.html] =
                VirtualDocument:new(nil, razor.language_kinds.html, html_uri)
        else
            local buf = vim.uri_to_bufnr(html_uri)
            virtual_documents[current_file][razor.language_kinds.html] =
                VirtualDocument:new(buf, razor.language_kinds.html)
        end
    end

    if ensure_open then
        local buf = vim.uri_to_bufnr(html_uri)
        ---@type rzls.VirtualDocument
        local hvd = virtual_documents[current_file][razor.language_kinds.html]
        local success = hvd:update_bufnr(buf)
        assert(success, "Failed to update bufnr for " .. html_uri)
    end
end

---@param result VBufUpdate
---@param language_kind razor.LanguageKind
function M.update_vbuf(result, language_kind)
    M.register_vbufs_by_path(result.hostDocumentFilePath, false)
    local razor_uri = vim.uri_from_fname(result.hostDocumentFilePath)
    ---@type rzls.VirtualDocument
    local virtual_document = virtual_documents[razor_uri][language_kind]

    if result.previousWasEmpty and virtual_document.content ~= "" then
        virtual_document.content = ""
    end

    if virtual_document.buf then
        virtual_document:remove_provisional_dot()
        if not vim.tbl_isempty(virtual_document.updates) then
            virtual_document:update_content()
        end

        table.insert(virtual_document.updates, result)
        virtual_document:update_content()
    else
        --TODO: do we need to fire here?
        virtual_document.change_event:fire()
        table.insert(virtual_document.updates, result)
        local roslyn = virtual_document:get_lsp_client()
        if language_kind == razor.language_kinds.csharp then
            ---@type razor.DynamicFileUpdatedParams
            local params = {
                razorDocument = {
                    uri = virtual_documents[razor_uri].uri,
                },
            }
            table.insert(roslyn_notify_queue, params)

            if not roslyn then
                ---NOTE:there is no roslyn to notify so we will do it later
                return
            end

            for i, notify in ipairs(roslyn_notify_queue) do
                --=TODO: Remove when 0.11 only
                ---@diagnostic disable-next-line: param-type-mismatch
                roslyn.notify(razor.notification.razor_dynamicFileInfoChanged, notify)
                roslyn_notify_queue[i] = nil
            end
        end
    end

    virtual_document.checksum = result.checksum
    virtual_document.checksum_algorithm = result.checksumAlgorithm or 1
    virtual_document.encoding_code_page = result.encodingCodePage
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
            virtual_document.uri,
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

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        local uri = vim.uri_from_bufnr(args.buf)
        if client.name == razor.lsp_names[razor.language_kinds.csharp] then
            if uri:match(razor.virtual_suffixes.csharp .. "$") then
                vim.api.nvim_set_option_value("buftype", "nowrite", { buf = args.buf })
                vim.api.nvim_set_option_value("buflisted", false, { buf = args.buf })
            end
        end

        if client.name == razor.lsp_names[razor.language_kinds.html] then
            if uri:match(razor.virtual_suffixes.html .. "$") then
                vim.api.nvim_set_option_value("buftype", "nowrite", { buf = args.buf })
                vim.api.nvim_set_option_value("buflisted", false, { buf = args.buf })
            end
        end
    end,
})

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
