local M = {}

---@param csharp_uri string
---@return string
---@return integer
function M.cs_uri_to_razor_uri(csharp_uri)
    return csharp_uri:gsub("__virtual.cs$", "")
end

return M
