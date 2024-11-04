local M = {}

local requests = {
    ["initialize"] = function(_)
        return {
            capabilities = {
                hoverProvider = true,
            },
        }
    end,
    ["shutdown"] = function(_) end,
    ["textDocument/hover"] = require("rzls.server.methods.hover"),
}

function M.server()
    local srv = {}
    local closing = false

    function srv.request(method, params, handler)
        if requests[method] then
            local response = requests[method](params)
            handler(nil, response)
        elseif method == "exit" then
            closing = true
        else
            assert(false, "Unhandled method: " .. method)
        end
    end

    function srv.notify(method, _params)
        if method == "exit" then
            closing = true
        end
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
