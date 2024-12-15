local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

local au = vim.api.nvim_create_augroup("rzls_semantic_tokens", {})
vim.api.nvim_create_autocmd("WinScrolled", {
    group = au,
    callback = function(ev)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = ev.buf })
        if ft == "razor" then
            vim.lsp.semantic_tokens.force_refresh(ev.buf)
        end
    end,
})

---@type lsp.SemanticTokens
local empty_response = {
    data = {},
}

---@param params lsp.SemanticTokensParams
---@return lsp.SemanticTokens
return function(params)
    local rvd = documentstore.get_virtual_document(params.textDocument.uri, razor.language_kinds.razor)
    if not rvd then
        return empty_response
    end

    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())

    ---@type lsp.SemanticTokens?
    local tokens, err = rvd:lsp_request(vim.lsp.protocol.Methods.textDocument_semanticTokens_range, {
        textDocument = params.textDocument,
        range = {
            start = {
                line = wininfo[1].topline - 1,
                character = 0,
            },
            ["end"] = {
                line = wininfo[1].botline - 1,
                character = (
                    string.len(
                        vim.api.nvim_buf_get_lines(rvd.buf, wininfo[1].botline - 1, wininfo[1].botline, false)[1]
                    )
                ),
            },
        },
    })

    if err or not tokens then
        return empty_response
    end

    return tokens
end
