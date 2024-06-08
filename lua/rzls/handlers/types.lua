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

---@class VBufUpdate
---@field previousWasEmpty boolean
---@field hostDocumentFilePath string
---@field hostDocumentVersion number
---@field changes table<string, Change>A

---@class Change
---@field span Span
---@field newText string

---@class Span
---@field start integer
---@field length integer

return M
