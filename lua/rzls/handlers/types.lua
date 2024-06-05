local M = {}

---@class ColorInformation
---@field range LocRange
---@field color Color

---@class Color
---@field red number
---@field green number
---@field blue number
---@field alpha number

---@class LocRange
---@field start Loc
---@field ["end"] Loc

---@class Loc
---@field line integer
---@field character integer

return M
