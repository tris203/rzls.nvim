local documentstore = require("rzls.documentstore")
local razor = require("rzls.razor")

---@param virtual_document rzls.VirtualDocument
---@param projected_position lsp.Position
---@param trigger_kind integer
---@param trigger_character string|nil
---@return lsp.CompletionList
---@return lsp.ResponseError|nil
local function provide_lsp_completions(virtual_document, projected_position, trigger_kind, trigger_character)
    ---@type lsp.CompletionParams
    local params = {
        context = {
            triggerKind = trigger_kind,
            triggerCharacter = trigger_character,
        },
        position = projected_position,
        textDocument = {
            uri = virtual_document.uri,
        },
    }
    local response = virtual_document:lsp_request(vim.lsp.protocol.Methods.textDocument_completion, params)

    if not response then
        ---@type lsp.CompletionList
        local empty_response = {
            isIncomplete = true,
            items = {},
        }
        return empty_response
    end

    ---@type lsp.CompletionList | lsp.CompletionItem[] | nil
    local completion_items = response

    if vim.islist(completion_items) then
        return {
            items = completion_items --[[@as lsp.CompletionItem[] ]],
            isIncomplete = false,
        },
            nil
    elseif completion_items ~= nil then
        return completion_items --[[@as lsp.CompletionList]]
    else
        return {
            isIncomplete = true,
            items = {},
        }
    end
end

---@param virtual_document rzls.VirtualDocument
---@param projected_position lsp.Position
---@param provisional_text_edit lsp.TextEdit|nil
---@param trigger_kind integer
---@param trigger_character string|nil
---@return lsp.CompletionList|nil
---@return lsp.ResponseError|nil
local function provide_csharp_completions(
    virtual_document,
    projected_position,
    provisional_text_edit,
    trigger_kind,
    trigger_character
)
    local absolute_index = virtual_document:index_of_position(projected_position)

    virtual_document:clear_resolve_completion_request_variables()

    if provisional_text_edit ~= nil then
        if absolute_index == -1 then
            return {
                items = {},
                isIncomplete = false,
            }
        end
        virtual_document:add_provisional_dot_at(absolute_index)
        virtual_document.provisional_dot_position = projected_position
        virtual_document:ensure_content()
    end

    local lsp_response, err =
        provide_lsp_completions(virtual_document, projected_position, trigger_kind, trigger_character)

    if provisional_text_edit ~= nil and virtual_document:remove_provisional_dot() then
        virtual_document:ensure_content()
    end

    return lsp_response, err
end

---@param _err lsp.ResponseError
---@param result razor.DelegatedCompletionParams
---@param _ctx lsp.HandlerContext
---@param _config table
---@return lsp.CompletionList|nil
---@return lsp.ResponseError|nil
return function(_err, result, _ctx, _config)
    local virtual_document = documentstore.get_virtual_document(
        result.identifier.textDocumentIdentifier.uri,
        result.projectedKind,
        result.identifier.version
    )
    if not virtual_document then
        return {
            items = {},
            isIncomplete = false,
        }
    end

    if result.identifier.version ~= virtual_document.host_document_version then
        return {
            items = {},
            isIncomplete = false,
        }
    end

    --- "@" is not a valid trigger character for C# and HTML
    local trigger_character = result.context.triggerCharacter == "@" and nil or result.context.triggerCharacter
    local trigger_kind = result.context.triggerCharacter == "@" and 1 or result.context.triggerKind -- Invoked

    if result.projectedKind == razor.language_kinds.csharp then
        return provide_csharp_completions(
            virtual_document,
            result.projectedPosition,
            result.provisionalTextEdit,
            trigger_kind,
            trigger_character
        )
    else
        return provide_lsp_completions(virtual_document, result.projectedPosition, trigger_kind, trigger_character)
    end
end
