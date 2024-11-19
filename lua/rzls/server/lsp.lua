local Log = require("rzls.log")
local M = {}

local requests = {
    ["initialize"] = function(_)
        return {
            capabilities = {
                hoverProvider = true,
                definitionProvider = true,
                referencesProvider = true,
                renameProvider = { prepareProvider = false },
                signatureHelpProvider = {
                    triggerCharacters = { "(", ",", "<" },
                    retriggerCharacters = { ">", ")" },
                },
            },
        }
    end,
    ["shutdown"] = function(_) end,
    ["textDocument/hover"] = require("rzls.server.methods.hover"),
    ["textDocument/definition"] = require("rzls.server.methods.definition"),
    ["textDocument/references"] = require("rzls.server.methods.references"),
    ["textDocument/rename"] = require("rzls.server.methods.rename"),
    ["textDocument/signatureHelp"] = require("rzls.server.methods.signaturehelp"),
}

local noops = {
    ["initialized"] = true,
    ["textDocument/didSave"] = true,
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
