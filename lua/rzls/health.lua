local M = {}
local razor = require("rzls.razor")
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
            if doc and doc.buf then
                vim.health.ok(
                    "  " .. lang .. " virtual document found: " .. doc.buf .. " v: " .. doc.host_document_version
                )
            else
                vim.health.error("  " .. lang .. " virtual document not found")
            end
        end
    end
    -- make sure setup function parameters are ok
    vim.health.ok("rzls.nvim report")
end
return M
