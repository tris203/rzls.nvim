local M = {}
local handlers = require("rzls.handlers")

---@class rzls.Config
---@field on_attach function
---@field capabilities table
---@field path string

local rzlsconfig = {}
---@type rzls.Config
local defaultConfg = {
    on_attach = function()
        return nil
    end,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    path = "/tmp",
}

local extraCapabilities = {
    colorProvider = true,
}

function M.setup(config)
    rzlsconfig = vim.tbl_deep_extend("force", defaultConfg, config)
end

local au = vim.api.nvim_create_augroup("rzls", { clear = true })

vim.api.nvim_create_autocmd("BufRead", {
    pattern = "*.razor",
    callback = function()
        local lspClientID = nil
        if not lspClientID then
            lspClientID = vim.lsp.start({
                name = "rzls",
                cmd = {
                    rzlsconfig.path .. "/rzls",
                    "--logLevel",
                    "0",
                    "--DelegateToCSharpOnDiagnosticsPublish",
                    "true",
                    "--UpdateBuffersForClosedDocuments",
                    "true",
                },
                root_dir = vim.fn.getcwd(),
                on_attach = rzlsconfig.on_attach,
                capabilities = vim.tbl_deep_extend("force", rzlsconfig.capabilities, extraCapabilities),
                settings = { razor = vim.empty_dict(), html = vim.empty_dict() },
                handlers = handlers,
            })
        end
        require("rzls.documentstore").create_vbufs(vim.api.nvim_get_current_buf())
        if lspClientID then
            vim.lsp.buf_attach_client(0, lspClientID)

            vim.notify("Razor LSP attached", vim.log.levels.INFO, { title = "rzls.nvim" })
        end
    end,
    group = au,
})
return M
