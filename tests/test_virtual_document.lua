local virtual_document = require("rzls.virtual_document")
local razor = require("rzls.razor")
local eq = MiniTest.expect.equality
local T = MiniTest.new_set()

local vd, path, uri

T["virtual document"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            path = "tests/rzls/fixtures/vdtest.razor__virtual.html"
            uri = "file://" .. vim.loop.cwd() .. "/" .. path
            vd = virtual_document:new(vim.uri_to_bufnr(uri), razor.language_kinds.html)
        end,
    },
})

T["virtual document"]["create virtual document"] = function()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 0,
        content = "",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)
end

T["virtual document"]["update virtual document"] = function()
    vd.updates = {
        {
            previousWasEmpty = true,
            hostDocumentVersion = 1,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = "Hello\n",
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        },
    }
    vd:update_content()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 1,
        content = "Hello\n",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)
    vd.updates = {
        {
            previousWasEmpty = false,
            hostDocumentVersion = 2,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = " World\n",
                    span = {
                        start = 5,
                        length = 1,
                    },
                },
            },
        },
    }
    vd:update_content()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 2,
        content = "Hello World\n",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)

    vd.updates = {
        {
            previousWasEmpty = false,
            hostDocumentVersion = 3,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = "stuff\n",
                    span = {
                        start = 6,
                        length = 6,
                    },
                },
            },
        },
    }
    vd:update_content()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 3,
        content = "Hello stuff\n",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)

    vd.updates = {
        {
            previousWasEmpty = false,
            hostDocumentVersion = 4,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = "in the middle ",
                    span = {
                        start = 6,
                        length = 0,
                    },
                },
            },
        },
    }
    vd:update_content()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 4,
        content = "Hello in the middle stuff\n",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)

    vd.updates = {
        {
            previousWasEmpty = false,
            hostDocumentVersion = 5,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = "i💩\n",
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        },
    }
    vd:update_content()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 5,
        content = "i💩\nHello in the middle stuff\n",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)

    vd.updates = {
        {
            previousWasEmpty = false,
            hostDocumentVersion = 6,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = "",
                    span = {
                        start = 0,
                        length = 3,
                    },
                },
            },
        },
    }
    vd:update_content()
    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 6,
        content = "Hello in the middle stuff\n",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = {},
        },
    }, vd)
end

T["virtual document"]["trigger change event when a document content changes"] = function()
    local update_handler_called = false

    local function update_handler()
        update_handler_called = true
    end

    local dispose_handler = vd.change_event:on(update_handler)

    vd.updates = {
        {
            previousWasEmpty = false,
            hostDocumentVersion = 7,
            hostDocumentFilePath = uri,
            changes = {
                {
                    newText = "",
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        },
    }
    vd:update_content()

    eq({
        buf = vim.uri_to_bufnr(uri),
        host_document_version = 7,
        content = "",
        kind = razor.language_kinds.html,
        uri = uri,
        updates = {},
        change_event = {
            listeners = { update_handler },
        },
    }, vd)

    vim.wait(10000, function()
        return update_handler_called
    end, 250)

    eq(false, update_handler_called)

    dispose_handler()
    eq({}, vd.change_event.listeners)
end

return T
