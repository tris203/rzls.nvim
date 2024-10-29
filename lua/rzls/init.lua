local handlers = require("rzls.handlers")
local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local debug = require("rzls.utils").debug

local M = {}

---@class rzls.Config
---@field on_attach function
---@field capabilities table
---@field path string

---@type rzls.Config
local defaultConfg = {
    on_attach = function()
        return nil
    end,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    path = "/tmp",
}

---@type lsp.ClientCapabilities
local extraCapabilities = {
    colorProvider = true,
}

function M.setup(config)
    local rzlsconfig = vim.tbl_deep_extend("force", defaultConfg, config)
    vim.filetype.add({
        extension = {
            razor = "razor",
        },
    })

    local au = vim.api.nvim_create_augroup("rzls", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "razor",
        callback = function(ev)
            local root_dir = vim.fn.getcwd()
            local lsp_client_id = vim.lsp.start({
                name = "rzls",
                cmd = {
                    rzlsconfig.path,
                    "--logLevel",
                    "0",
                    "--DelegateToCSharpOnDiagnosticsPublish",
                    "true",
                    "--UpdateBuffersForClosedDocuments",
                    "true",
                },
                on_init = function(client, initialize_result)
                    M.watch_new_files(root_dir)
                    documentstore.initialize(client, root_dir)
                end,
                root_dir = root_dir,
                on_attach = function(client, bufnr)
                    documentstore.initialize(client, root_dir)
                    documentstore.register_vbufs(bufnr)
                    rzlsconfig.on_attach(client, bufnr)
                end,
                capabilities = vim.tbl_deep_extend("force", rzlsconfig.capabilities, extraCapabilities),
                settings = {
                    ["razor.server.trace"] = "Trace",
                    html = vim.empty_dict(),
                    razor = vim.empty_dict(),
                    ["vs.editor.razor"] = vim.empty_dict(),
                },
                handlers = handlers,
            })

            if lsp_client_id == nil then
                vim.notify("Could not start Razor LSP", vim.log.levels.ERROR, { title = "rzls.nvim" })
                return
            end

            vim.lsp.buf_attach_client(ev.buf, lsp_client_id)
        end,
        group = au,
    })
end

function M.watch_new_files(path)
    local w = vim.uv.new_fs_event()
    assert(w)

    local fullpath = vim.fn.fnamemodify(path, ":p")

    w:start(fullpath, {
        recursive = true,
    }, function(err, filename, events)
        assert(not err, err)
        vim.print("file modified:" .. filename)
        if vim.fn.fnamemodify(filename, ":e") == "razor" then
            documentstore.register_vbufs_by_path(filename)
        end
    end)
end
return M
