local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

describe("uuid", function()
    it("generates unique uuids", function()
        local utils = require("rzls.utils")
        local uuid1 = utils.uuid()
        local uuid2 = utils.uuid()
        neq(uuid1, uuid2)
    end)
    it("generates valid uuids", function()
        -- 5f72f119-e7b2-433b-b919-df8a74866e45
        local utils = require("rzls.utils")
        local uuid = utils.uuid()
        eq(36, #uuid)
    end)
end)
