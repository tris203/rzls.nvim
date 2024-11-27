local Log = require("rzls.log")
local M = {}

local requests = {
    [vim.lsp.protocol.Methods.initialize] = function(_)
        return {
            --- @type lsp.ServerCapabilities
            capabilities = {
                hoverProvider = true,
                definitionProvider = true,
                referencesProvider = true,
                renameProvider = { prepareProvider = false },
                documentHighlightProvider = true,
                signatureHelpProvider = {
                    triggerCharacters = { "(", ",", "<" },
                    retriggerCharacters = { ">", ")" },
                },
            },
        }
    end,
    [vim.lsp.protocol.Methods.shutdown] = function(_) end,
    [vim.lsp.protocol.Methods.textDocument_hover] = require("rzls.server.methods.hover"),
    [vim.lsp.protocol.Methods.textDocument_definition] = require("rzls.server.methods.definition"),
    [vim.lsp.protocol.Methods.textDocument_references] = require("rzls.server.methods.references"),
    [vim.lsp.protocol.Methods.textDocument_rename] = require("rzls.server.methods.rename"),
    [vim.lsp.protocol.Methods.textDocument_signatureHelp] = require("rzls.server.methods.signaturehelp"),
    [vim.lsp.protocol.Methods.textDocument_documentHighlight] = require("rzls.server.methods.documenthighlight"),
}

local noops = {
    [vim.lsp.protocol.Methods.initialized] = true,
    [vim.lsp.protocol.Methods.textDocument_didSave] = true,
}

function M.server()
    local srv = {}
    local closing = false
    Log.aftershave = "Started aftershave server"

    function srv.request(method, params, handler)
        coroutine.wrap(function()
            if requests[method] then
                Log.aftershave = "Handled " .. method
                local response = requests[method](params)
                handler(nil, response)
            elseif method == "exit" then
                Log.aftershave = "Closing aftershave server"
                closing = true
            else
                Log.aftershave = "Unhandled request " .. method
            end
        end)()
    end

    function srv.notify(method, _params)
        coroutine.wrap(function()
            if method == "exit" then
                closing = true
            elseif not noops[method] then
                Log.aftershave = "Unhandled notification " .. method
            end
        end)()
    end

    function srv.is_closing()
        return closing
    end

    function srv.terminate()
        closing = true
    end

    return srv
end

return M
