# rzls.nvim

## Description

`rzls.nvim` is a Neovim plugin for Razor Language Server (rzls). It provides
language server protocol (LSP) support for Razor/Blazor/CSHTMl files. This aims
to bring this support to Neovim.

## Installing the LSP

The LSP can be cloned and compiled from source from the `dotnet/razor` repo.

## Dependencies

You must install the following plugins:

* [seblj/roslyn.nvim](https://github.com/seblj/roslyn.nvim)

The `html-lsp` is also required to provide completions. You can install it with
Mason and configure it via `nvim-lspconfig`.

## Integration

You can pass a configuration table to the `setup` function. The configuration options are:

* `on_attach`: A function that is called when the LSP client attaches to a buffer.
* `capabilities`: A table that defines the capabilities of the LSP client.
* `path`: The path to the rzls executable.

You also must configure the [`roslyn.nvim`](https://github.com/seblj/roslyn.nvim) plugin
to communicate with the razor LSP. To do so, you must pass the handlers defined in the
`rzls.roslyn_handlers` module:

```lua
require('roslyn').setup {
    config = {
        handlers = require('rzls.roslyn_handlers')
    }
}
```

## Under Construction

This plugin is still under construction. The Razor Language Server (rzls) uses a
variety of custom methods that need to be understood and implemented. We are
actively working on this and appreciate your patience.

We welcome contributions from the community. If you have experience with LSP or
Razor and would like to contribute, please open a Pull Request. If
you encounter any issues or have suggestions for improvements, please open an
Issue. Your input is valuable in making this plugin more robust and efficient.

## Helping Out

If you want to help out, then please see the discussion here, and leave a
comment matches your details in this [discussion](https://github.com/tris203/rzls.nvim/discussions/1).
