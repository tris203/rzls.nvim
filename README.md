# rzls.nvim 🚀

## Description 📄

`rzls.nvim` is a Neovim plugin for the Razor Language Server (rzls). It provides
language server protocol (LSP) support for Razor/Blazor/CSHTML files, bringing
powerful development features to Neovim. ✨

With `rzls.nvim`, you can enjoy a seamless coding experience with features like
auto-completion, go-to-definition, and more all from within neovim 💻🔧

### Features

| Feature               | Support     |
| --------------------- | ----------- |
| Hover                 | ✅          |
| Diagnositcs           | ✅          |
| Go To Definition      | ✅          |
| Go To References      | ✅          |
| Semantic Highlighting | ✅          |
| Formatting            | ✅          |
| Rename Symbol         | ✅          |
| Signature Help        | ✅          |
| Completions           | ✅          |
| Inlay Hints           | ✅          |
| Code Actions          | ❌          |
| Folding               | ✅          |
| CodeLens              | ❌          |
| Format New Files      | ❌          |

> [!NOTE]
> Semantic highlight groups need more configuration If you find a
> property that isn't highlighted properly and is identified with `:Inspect`
> please raise an issue or a PR to link it to a HL group.

## Installing the LSP

The LSP can be cloned and compiled from source from the `dotnet/razor` repo.

> [!TIP]
> Alternatively, if you use `mason` to manage your LSP installs. A registry
> containing both roslyln and rzls is
> configured [here](https://github.com/Crashdummyy/mason-registry)
>
> It can be included in your config:

```lua
require('mason').setup {
  registries = {
    'github:mason-org/mason-registry',
    'github:crashdummyy/mason-registry',
  },
}
```

## Dependencies

You must install the following plugins:

- [seblj/roslyn.nvim](https://github.com/seblj/roslyn.nvim)

> [!CAUTION]
> Please see Integration section for extra arguments that must be passed to
> roslyn.nvim setup.

The `html-lsp` is also required to provide completions and formatting. You can
install and configure it via `mason` and `nvim-lspconfig`.

## Integration

You can pass a configuration table to the `setup` function. The configuration options are:

- `on_attach`: A function that is called when the LSP client attaches to a buffer.
- `capabilities`: A table that defines the capabilities of the LSP client.
- `path`: The path to the rzls executable if not installed via mason. If you
  have installed via mason you can omit this option.

You also must configure the [`roslyn.nvim`](https://github.com/seblj/roslyn.nvim) plugin
to communicate with the razor LSP. To do so, you must pass the handlers defined in the
`rzls.roslyn_handlers` module:

```lua
require('roslyn').setup {
  args = {
    '--logLevel=Information',
    '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
    '--razorSourceGenerator=' .. vim.fs.joinpath(
      vim.fn.stdpath 'data' --[[@as string]],
      'mason',
      'packages',
      'roslyn',
      'libexec',
      'Microsoft.CodeAnalysis.Razor.Compiler.dll'
    ),
    '--razorDesignTimePath=' .. vim.fs.joinpath(
      vim.fn.stdpath 'data' --[[@as string]],
      'mason',
      'packages',
      'rzls',
      'libexec',
      'Targets',
      'Microsoft.NET.Sdk.Razor.DesignTime.targets'
    ),
  },
  config = {
    on_attach = require 'lspattach',
    capabilities = capabilities,
    handlers = require 'rzls.roslyn_handlers',
  },
}
```

### Inlay Hints

Inlay hints are provided in razor documents via the roslyn lsp.

To enable, you must enable inlay hinting in nvim config `:h vim.lsp.inlay_hint.enable()`
and also configure `csharp|inlay_hint_*` options in [roslyn.nvim](https://github.com/seblj/roslyn.nvim)

## Additional Configuration

### Telescope

If you use telescope for definitions and references then you may want to add
additional filtering exclude references in the generated virtual files

```lua
require('telescope').setup {
  defaults = {
    file_ignore_patterns = { '%__virtual.cs$' },
  },
}
```

### Trouble

If you use trouble for diagnostics, then you want to excludion the virtual
buffers from diagnostics

```lua
require('trouble').setup {
      modes = {
        diagnostics = {
          filter = function(items)
            return vim.tbl_filter(function(item)
              return not string.match(item.basename, [[%__virtual.cs$]])
            end, items)
          end,
        },
      },
}
```


## Known Issues

- Native windows support doesn't work currently due to path normalization.
- Opening a CS file first means that roslyn and rzls don't connect properly.

## Contributing

This plugin is still under construction. The Razor Language Server (rzls) uses a
variety of custom methods that need to be understood and implemented. We are
actively working on this and appreciate your patience.

We welcome contributions from the community for support of new features, fixing
bugs, issues or things on the TODO list (Grep the code for `TODO`). If you have
experience with LSP or
Razor and would like to contribute, please open a Pull Request. If
you encounter any issues or have suggestions for improvements, please open an
Issue. Your input is valuable in making this plugin more robust and efficient.

There is a discord community linked in the discussion below, if you have
anything you would like to discuss or you want to help. Come say hi.

## Helping Out

If you want to help out, then please see the discussion here, and leave a
comment with your details in this [discussion](https://github.com/tris203/rzls.nvim/discussions/1).
