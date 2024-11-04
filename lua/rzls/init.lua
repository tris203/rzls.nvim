local handlers = require("rzls.handlers")
local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

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

---@type table<string, fun(err, result, ctx, config)>
local wrapper_func = {
    ["textDocument/hover"] = require("rzls.clienthandlers.hover"),
}

---@type rzls.Config
local defaultConfg = {
    on_attach = function()
        return nil
    end,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
}

---@type lsp.ClientCapabilities
local extraCapabilities = {
    colorProvider = true,
}

---@param config rzls.Config
function M.setup(config)
    local rzlsconfig = vim.tbl_deep_extend("force", defaultConfg, config)
    rzlsconfig.path = rzlsconfig.path or get_cmd_path(rzlsconfig)
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
                on_init = function(client, _initialize_result)
                    M.load_existing_files(client.root_dir)
                    vim.api.nvim_create_autocmd("User", {
                        pattern = "RoslynInitialized",
                        callback = function()
                            documentstore.initialize(client)
                        end,
                        group = au,
                    })
                    M.watch_new_files(root_dir)
                end,
                root_dir = root_dir,
                on_attach = function(client, bufnr)
                    razor.apply_highlights()
                    documentstore.register_vbufs(bufnr)
                    rzlsconfig.on_attach(client, bufnr)
                    if not client.hacked_semantic then
                        client.server_capabilities = vim.tbl_deep_extend("force", client.server_capabilities, {
                            semanticTokensProvider = {
                                full = true,
                            },
                        })
                        ---@diagnostic disable-next-line: inject-field
                        client.hacked_semantic = true
                    end
                    local req = client.request
                    client.request = function(method, params, handler, tbufnr)
                        if wrapper_func[method] then
                            return req(method, params, wrapper_func[method], tbufnr)
                        end
                        if method == vim.lsp.protocol.Methods.textDocument_semanticTokens_full then
                            return req(vim.lsp.protocol.Methods.textDocument_semanticTokens_range, {
                                textDocument = params.textDocument,
                                range = {
                                    start = {
                                        line = 0,
                                        character = 0,
                                    },
                                    ["end"] = {
                                        line = vim.api.nvim_buf_line_count(tbufnr),
                                        character = (
                                            string.len(vim.api.nvim_buf_get_lines(tbufnr, -2, -1, true)[1]) - 1
                                        )
                                            or 0,
                                    },
                                },
                            }, handler, tbufnr)
                        end
                        return req(method, params, handler, tbufnr)
                    end
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

    vim.treesitter.language.register("html", { "razor" })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = au,
        callback = razor.apply_highlights,
    })
end

function M.load_existing_files(path)
    local files = vim.fn.glob(path .. "/**/*.razor", true, true)
    for _, file in ipairs(files) do
        documentstore.register_vbufs_by_path(file)
    end
end

function M.watch_new_files(path)
    local w = vim.uv.new_fs_event()
    assert(w)

    local fullpath = vim.fn.fnamemodify(path, ":p")

    w:start(fullpath, {
        recursive = true,
    }, function(err, filename, _events)
        assert(not err, err)
        vim.print("file modified:" .. filename)
        if vim.fn.fnamemodify(filename, ":e") == "razor" then
            documentstore.register_vbufs_by_path(filename)
        end
    end)
end

return M
