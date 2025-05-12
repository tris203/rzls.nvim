local razor = require("rzls.razor")
local documentstore = require("rzls.documentstore")

---@type razor.razorMapSpansResponse
local empty_response = {
    razorDocument = {
        uri = "",
    },
    ranges = {},
    spans = {},
}

---@param csharp_uri string
---@return string
---@return integer
local function cs_uri_to_razor_uri(csharp_uri)
    return csharp_uri:gsub("__virtual.cs$", "")
end

---@param _err lsp.ResponseError
---@param result razor.razorMapSpansParams
---@param _ctx lsp.HandlerContext
---@param _config? table
---@return razor.razorMapSpansResponse|nil
---@return lsp.ResponseError|nil
return function(_err, result, _ctx, _config)
    if result.csharpDocument == nil then
        return nil, vim.lsp.rpc.rpc_response_error(-32602, "Missing csharpDocument")
    end
    local razor_uri = cs_uri_to_razor_uri(result.csharpDocument.uri)
    local rvd = documentstore.get_virtual_document(razor_uri, razor.language_kinds.razor, "any")
    if not rvd then
        return empty_response, nil
    end

    local ranges, err = rvd:map_to_document_ranges(razor.language_kinds.csharp, result.ranges)
    if not ranges or err then
        return empty_response, nil
    end

    ---@type razor.razorMapSpansResponse
    local resp = {
        razorDocument = {
            uri = rvd.uri,
        },
        spans = ranges.spans,
        ranges = ranges.ranges,
    }

    return resp, nil
end
