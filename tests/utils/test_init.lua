local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality
local T = MiniTest.new_set()

T["UUID"] = MiniTest.new_set()
T["UUID"]["generates unique uuids"] = function()
    local utils = require("rzls.utils")
    local uuid1 = utils.uuid()
    local uuid2 = utils.uuid()
    neq(uuid1, uuid2)
end

T["UUID"]["generates valid uuids"] = function()
    local utils = require("rzls.utils")
    local uuid = utils.uuid()
    eq(36, #uuid)
end

return T
