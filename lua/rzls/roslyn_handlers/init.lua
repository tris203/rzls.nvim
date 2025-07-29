local not_implemented = function(err, result, ctx, config)
    vim.print("Called " .. ctx.method)
    vim.print(vim.inspect(err))
    vim.print(vim.inspect(result))
    vim.print(vim.inspect(ctx))
    vim.print(vim.inspect(config))
end

return {
    ["razor/provideDynamicFileInfo"] = require("rzls.roslyn_handlers.provideDynamicFileInfo"),
    ["razor/removeDynamicFileInfo"] = require("rzls.roslyn_handlers.removeDynamicFileInfo"),
    ["razor/mapSpans"] = require("rzls.roslyn_handlers.mapSpans"),
    ["razor/mapTextChanges"] = not_implemented,
}
