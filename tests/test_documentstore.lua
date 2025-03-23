local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set()

T["documentstore"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.lua([[M = require('rzls')]])
        end,
        post_once = child.stop,
    },
})

T["documentstore"]["create and retreive docs"] = function()
    child.lua([[
    local documentstore = require("rzls.documentstore")
    local path = "tests/rzls/fixtures/test2.razor"
    local path_prefix = vim.loop.cwd() .. "/"
    local full_path = "file://" .. path_prefix .. path
    documentstore.register_vbufs_by_path(path_prefix .. path, true)
    ]])
    local bufs = child.api.nvim_list_bufs()
    local names = {}
    eq(#bufs, 4)
    for _, buf in ipairs(bufs) do
        names[buf] = child.api.nvim_buf_get_name(buf)
    end
    local path_prefix = vim.loop.cwd() .. "/"
    eq({
        "",
        path_prefix .. "tests/rzls/fixtures/test2.razor",
        path_prefix .. "tests/rzls/fixtures/test2.razor__virtual.cs",
        path_prefix .. "tests/rzls/fixtures/test2.razor__virtual.html",
    }, names)
end

return T
