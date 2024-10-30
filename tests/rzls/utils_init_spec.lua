---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same
---@diagnostic disable-next-line: undefined-field
local neq = assert.are_not.same

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
