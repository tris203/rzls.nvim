local documentstore = require("rzls.documentstore")

local eq = MiniTest.expect.equality

describe("documentstore", function()
    it("create and retreive docs", function()
        local path = "tests/rzls/fixtures/test2.razor"
        local path_prefix = vim.loop.cwd() .. "/"
        local full_path = "file://" .. path_prefix .. path
        documentstore.register_vbufs_by_path(path_prefix .. path, true)
        for _, lang in pairs({ 1, 2 }) do
            local doc = documentstore.get_virtual_document(full_path, lang, "any")
            assert(doc, "Could not find virtual document")
            eq(doc.kind, lang)
        end
        local bufs = vim.api.nvim_list_bufs()
        local names = {}
        MiniTest.skip("Need to use child neovim process to test this")
        eq(#bufs, 5)
        for _, buf in ipairs(bufs) do
            names[buf] = vim.api.nvim_buf_get_name(buf)
        end
        eq({
            "",
            path_prefix .. "tests/rzls/fixtures/test2.razor",
            path_prefix .. "tests/rzls/fixtures/test2.razor__virtual.cs",
            path_prefix .. "tests/rzls/fixtures/test2.razor__virtual.html",
        }, names)
    end)
end)
