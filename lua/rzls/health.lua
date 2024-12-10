local M = {}
local razor = require("rzls.razor")
local Log = require("rzls.log")

M.check = function()
    vim.health.start("rzls.nvim report")
    -- make sure setup function parameters are ok

    vim.health.start("document store")
    ---@type rzls.VirtualDocument<string, table<razor.LanguageKind, rzls.VirtualDocument>>
    local document_store = require("rzls.documentstore").get_docstore
    for razor_filename, docs in pairs(document_store) do
        vim.health.info("razor file: " .. razor_filename)
        if docs.buf then
            vim.health.ok(
                "razor virtual document open: [buf:" .. docs.buf .. "] [v:" .. docs.host_document_version .. "]"
            )
        else
            vim.health.ok("razor virtual document not open")
        end

        for _, lang in pairs({ "csharp", "html" }) do
            local doc = docs[razor.language_kinds[lang]]
            if doc and doc.buf and doc.uri then
                vim.health.ok(
                    "  "
                        .. lang
                        .. " virtual document found: [buf:"
                        .. doc.buf
                        .. "] [v:"
                        .. doc.host_document_version
                        .. "]"
                        .. doc.uri
                )
            else
                vim.health.ok("  " .. lang .. " virtual document not open")
            end
        end
    end

    vim.health.start("lsp info")

    local lsps = {
        roslyn = vim.lsp.get_clients({ name = razor.lsp_names[razor.language_kinds.csharp] })[1],
        rzls = vim.lsp.get_clients({ name = razor.lsp_names[razor.language_kinds.razor] })[1],
        html = vim.lsp.get_clients({ name = razor.lsp_names[razor.language_kinds.html] })[1],
    }
    for name, client in pairs(lsps) do
        if not client then
            vim.health.error("lsp client " .. name .. " not found")
        else
            vim.health.ok("lsp client " .. name .. " found")
        end
    end

    local roslyn_pipe_id = require("rzls.documentstore").get_roslyn_pipe

    if roslyn_pipe_id then
        vim.health.ok("roslyn lsp connected via pipe: " .. roslyn_pipe_id)
    else
        vim.health.error("roslyn pipe not connected")
    end

    vim.health.start("rzls.nvim logs")

    for log, messages in Log() do
        vim.health.start(log .. " logs:")
        for _, message in ipairs(messages) do
            vim.health.info("[" .. log .. "]" .. message)
        end
    end
end
return M
