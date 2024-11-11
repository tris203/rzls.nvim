local virtual_document = require("rzls.virtual_document")
local razor = require("rzls.razor")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("virtual document", function()
    local vd
    local path = "tests/rzls/fixtures/vdtest.razor__virtual.html"
    local full_path = "file://" .. vim.loop.cwd() .. "/" .. path
    vim.cmd.edit({ args = { path } })
    local ls = vim.fn.getbufinfo({ buflisted = 1 })
    local bufnr = ls[1].bufnr

    it("create virtual document", function()
        vd = virtual_document:new(bufnr, razor.language_kinds.html)
        eq({
            buf = bufnr,
            host_document_version = 0,
            content = "",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = {},
            },
        }, vd)
    end)

    it("update virtual document", function()
        vd:update_content({
            previousWasEmpty = true,
            hostDocumentVersion = 1,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = "Hello\n",
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        })
        eq({
            buf = bufnr,
            host_document_version = 1,
            content = "Hello\n",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = {},
            },
        }, vd)
        vd:update_content({
            previousWasEmpty = false,
            hostDocumentVersion = 2,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = " World\n",
                    span = {
                        start = 5,
                        length = 1,
                    },
                },
            },
        })
        eq({
            buf = bufnr,
            host_document_version = 2,
            content = "Hello World\n",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = {},
            },
        }, vd)
        vd:update_content({
            previousWasEmpty = false,
            hostDocumentVersion = 3,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = "stuff\n",
                    span = {
                        start = 6,
                        length = 6,
                    },
                },
            },
        })
        eq({
            buf = bufnr,
            host_document_version = 3,
            content = "Hello stuff\n",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = {},
            },
        }, vd)
        vd:update_content({
            previousWasEmpty = false,
            hostDocumentVersion = 4,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = "in the middle ",
                    span = {
                        start = 6,
                        length = 0,
                    },
                },
            },
        })
        eq({
            buf = bufnr,
            host_document_version = 4,
            content = "Hello in the middle stuff\n",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = {},
            },
        }, vd)
        vd:update_content({
            previousWasEmpty = false,
            hostDocumentVersion = 5,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = "i💩\n",
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        })
        eq({
            buf = bufnr,
            host_document_version = 5,
            content = "i💩\nHello in the middle stuff\n",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = {},
            },
        }, vd)
        vd:update_content({
            previousWasEmpty = false,
            hostDocumentVersion = 6,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = "",
                    span = {
                        start = 0,
                        length = 3,
                    },
                },
            },
        })
        eq({
            buf = bufnr,
            host_document_version = 6,
            content = "Hello in the middle stuff\n",
            kind = razor.language_kinds.html,
            path = full_path,
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

        vd:update_content({
            previousWasEmpty = false,
            hostDocumentVersion = 7,
            hostDocumentFilePath = full_path,
            changes = {
                {
                    newText = "",
                    span = {
                        start = 0,
                        length = 0,
                    },
                },
            },
        })

        eq({
            buf = bufnr,
            host_document_version = 7,
            content = "Hello in the middle stuff\n",
            kind = razor.language_kinds.html,
            path = full_path,
            change_event = {
                listeners = { update_handler },
            },
        }, vd)

        -- Schedule resuming to give a change to the `update_handler` to be called
        local co = coroutine.running()
        vim.schedule(function()
            coroutine.resume(co)
        end)
        coroutine.yield()

        eq(true, update_handler_called)

        dispose_handler()
        eq({}, vd.change_event.listeners)
    end)
end)
