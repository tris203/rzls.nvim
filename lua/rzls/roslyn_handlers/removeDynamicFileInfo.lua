local helpers = require("rzls.roslyn_handlers.helpers")
local documentstore = require("rzls.documentstore")

---@param _err lsp.ResponseError
---@param result razor.RemoveDynamicFileParams
---@param _ctx lsp.HandlerContext
---@param _config? table
---@return razor.ProvideDynamicFileResponse|nil
---@return lsp.ResponseError|nil
return function(_err, result, _ctx, _config)
    local razor_uri = helpers.cs_uri_to_razor_uri(result.csharpDocument.uri)
    documentstore.remove_virtual_document(razor_uri)
end
