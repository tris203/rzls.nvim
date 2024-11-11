local M = {}
local razor = require("rzls.razor")
local Log = require("rzls.log")

M.check = function()
    vim.health.start("rzls.nvim report")
    -- make sure setup function parameters are ok

    ---@type rzls.VirtualDocument<string, table<razor.LanguageKind, rzls.VirtualDocument>>
    local document_store = require("rzls.documentstore").get_docstore
    for razor_filename, docs in pairs(document_store) do
        vim.health.info("razor file: " .. razor_filename)
        if docs.buf then
            vim.health.ok("razor virtual document found: " .. docs.buf .. " v: " .. docs.host_document_version)
        else
            vim.health.error("razor virtual document not found")
        end

        for _, lang in pairs({ "csharp", "html" }) do
            local doc = docs[razor.language_kinds[lang]]
            if doc and doc.buf and doc.path then
                vim.health.ok(
                    "  "
                        .. lang
                        .. " virtual document found: [buf:"
                        .. doc.buf
                        .. "] [v:"
                        .. doc.host_document_version
                        .. "]"
                        .. doc.path
                )
            else
                vim.health.error("  " .. lang .. " virtual document not found")
            end
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
