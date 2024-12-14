local virtual_document = require("rzls.virtual_document")
local razor = require("rzls.razor")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("virtual document", function()
    local vd
    local path = "tests/rzls/fixtures/vdtest.razor__virtual.html"
    local uri = "file://" .. vim.loop.cwd() .. "/" .. path
    local bufnr = vim.uri_to_bufnr(uri)

    it("create virtual document", function()
        vd = virtual_document:new(bufnr, razor.language_kinds.html)
        eq({
            buf = bufnr,
            host_document_version = 0,
            content = "",
            kind = razor.language_kinds.html,
            uri = uri,
            updates = {},
            change_event = {
                listeners = {},
            },
        }, vd)
    end)

    it("update virtual document", function()
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
            buf = bufnr,
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
            buf = bufnr,
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
            buf = bufnr,
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
            buf = bufnr,
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
            buf = bufnr,
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
            buf = bufnr,
            host_document_version = 6,
            content = "Hello in the middle stuff\n",
            kind = razor.language_kinds.html,
            uri = uri,
            updates = {},
            change_event = {
                listeners = {},
            },
        }, vd)
    end)

    it("trigger change event when a document content changes", function()
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
            buf = bufnr,
            host_document_version = 7,
            content = "Hello in the middle stuff\n",
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

        eq(true, update_handler_called)

        dispose_handler()
        eq({}, vd.change_event.listeners)
    end)
end)
