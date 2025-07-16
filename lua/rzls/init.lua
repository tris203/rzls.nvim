local handlers = require("rzls.handlers")
local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")
local Log = require("rzls.log")

local M = {}

---@class rzls.Config
---@field on_attach function
---@field capabilities table
---@field path string?

--- return the path to the rzls executable
---@param config rzls.Config
---@return string
local function get_cmd_path(config)
    ---@return string
    local function get_mason_installation()
        local mason_installation = vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "mason", "bin", "rzls")
        return vim.uv.os_uname().sysname == "Windows_NT" and string.format("%s.cmd", mason_installation)
            or mason_installation
    end

    if config.path then
        return config.path
    end
    return get_mason_installation()
end

---@type rzls.Config
local defaultConfig = {
    on_attach = function()
        return nil
    end,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
}

Log.rzlsnvim = "Loaded"
vim.filetype.add({
    extension = {
        razor = "razor",
        cshtml = "razor",
    },
})
Log.rzlsnvim = "Added razor filetype"

---@param config rzls.Config
function M.setup(config)
    Log.rzlsnvim = "Ran Setup"
    local rzlsconfig = vim.tbl_deep_extend("force", defaultConfig, config)
    rzlsconfig.path = rzlsconfig.path or get_cmd_path(rzlsconfig)

    local au = vim.api.nvim_create_augroup("rzls", { clear = true })

    local root_dir = vim.fn.getcwd()
    M.rzls_client_id = nil
    M.aftershave_client_id = nil

    ---@return number?
    function M.start_rzls()
        if M.rzls_client_id then
            return M.rzls_client_id
        end

        M.rzls_client_id = vim.lsp.start({
            name = "rzls",
            cmd = {
                rzlsconfig.path,
                "--logLevel",
                "0",
                "--DelegateToCSharpOnDiagnosticPublish",
                "true",
                "--UpdateBuffersForClosedDocuments",
                "true",
                "--SingleServerCompletionSupport",
                "true",
                "--useNewFormattingEngine",
                "true",
            },
            on_init = function(client, _initialize_result)
                ---@diagnostic disable-next-line: undefined-field
                if _G.roslyn_initialized == true then
                    documentstore.initialize(client.id)
                else
                    vim.api.nvim_create_autocmd("User", {
                        pattern = "RoslynInitialized",
                        callback = function()
                            documentstore.initialize(client.id)
                        end,
                        group = au,
                    })
                end
            end,
            root_dir = root_dir,
            on_attach = function(client, bufnr)
                razor.apply_highlights()
                documentstore.register_vbufs_by_path(vim.uri_to_fname(vim.uri_from_bufnr(bufnr)), true)
                rzlsconfig.on_attach(client, bufnr)
            end,
            capabilities = rzlsconfig.capabilities,
            settings = {
                html = vim.empty_dict(),
                razor = vim.empty_dict(),
            },
            handlers = handlers,
        }, { attach = false })

        if M.rzls_client_id == nil then
            vim.notify("Could not start Razor LSP", vim.log.levels.ERROR, { title = "rzls.nvim" })
            return
        end
        return M.rzls_client_id
    end

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "razor",
        callback = function(ev)
            M.start_rzls()
            assert(M.rzls_client_id, "Razor LSP client not started")
            vim.lsp.buf_attach_client(ev.buf, M.rzls_client_id)

            if not M.aftershave_client_id then
                M.aftershave_client_id = vim.lsp.start({
                    name = "aftershave",
                    root_dir = root_dir,
                    cmd = require("rzls.server.lsp").server,
                })
            end
            assert(M.aftershave_client_id, "Aftershave LSP client not started")

            vim.lsp.buf_attach_client(ev.buf, M.aftershave_client_id)
        end,
        group = au,
    })

    function M.load_existing_files(path)
        local files = vim.fn.glob(path .. "/**/*.{razor,cshtml}", true, true)
        for _, file in ipairs(files) do
            Log.rzlsnvim = "Preloading " .. file .. " into documentstore"
            documentstore.register_vbufs_by_path(file, false)
        end
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = au,
        callback = razor.apply_highlights,
    })
end

return M
