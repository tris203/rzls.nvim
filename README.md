# rzls.nvim 🚀

## Description 📄

`rzls.nvim` is a Neovim plugin for the Razor Language Server (rzls). It provides
language server protocol (LSP) support for Razor/Blazor/CSHTML files, bringing
powerful development features to Neovim. ✨

With `rzls.nvim`, you can enjoy a seamless coding experience with features like
auto-completion, go-to-definition, and more all from within neovim 💻🔧

### Features

| Feature               | Support |
| --------------------- | ------- |
| Hover                 | ✅      |
| Diagnositcs           | ✅      |
| Go To Definition      | ✅      |
| Go To References      | ✅      |
| Semantic Highlighting | ✅      |
| Formatting            | ✅      |
| Rename Symbol         | ✅      |
| Signature Help        | ✅      |
| Completions           | ✅      |
| Inlay Hints           | ✅      |
| Code Actions          | ❌      |
| Folding               | ✅      |
| CodeLens              | ❌      |
| Format New Files      | ❌      |

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

You must install the following plug ins:

- [seblyng/roslyn.nvim](https://github.com/seblyng/roslyn.nvim)

> [!CAUTION]
> Please see Integration section for extra arguments that must be passed to
> roslyn.nvim setup.

The `html-lsp` is also required to provide completions and formatting. You can
install and configure it via `mason` and `nvim-lspconfig`.

## Integration

You can pass a configuration table to the `setup` function. The configuration options are:

- `on_attach`: A function that is called when the LSP client attaches to a
  buffer. If you don't know what this is, or your on_attach function is provided
  by an autocommand. You omit the option, or pass an empty function.
- `capabilities`: A table that defines the capabilities of the LSP client. If
  you don't know what this is, it can either be omitted or found in the
  documentation of your cmp provider.
- `path`: The path to the rzls executable if not installed via mason. If you
  have installed via mason you can omit this option.

You also must configure the [`roslyn.nvim`](https://github.com/seblyng/roslyn.nvim) plugin
to communicate with the razor LSP. To do so, you must pass the handlers defined in the
`rzls.roslyn_handlers` module:

```lua
require('roslyn').setup {
  args = {
    '--stdio',
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
    --[[ the rest of your roslyn config ]]
    handlers = require 'rzls.roslyn_handlers',
  },
}
```

### Example config

```lua
return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'razor' },
    dependencies = {
      {
        -- By loading as a dependencies, we ensure that we are available to set
        -- the handlers for roslyn
        'tris203/rzls.nvim',
        config = function()
          ---@diagnostic disable-next-line: missing-fields
          require('rzls').setup {}
        end,
      },
    },
    config = function()
      require('roslyn').setup {
        args = {
          '--stdio',
          '--logLevel=Information',
          '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
          '--razorSourceGenerator='
            .. vim.fs.joinpath(vim.fn.stdpath 'data' --[[@as string]], 'mason', 'packages', 'roslyn', 'libexec', 'Microsoft.CodeAnalysis.Razor.Compiler.dll'),
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
        ---@diagnostic disable-next-line: missing-fields
        config = {
          handlers = require 'rzls.roslyn_handlers',
          settings = {
            ['csharp|inlay_hints'] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,

              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_indexer_parameters = true,
              dotnet_enable_inlay_hints_for_literal_parameters = true,
              dotnet_enable_inlay_hints_for_object_creation_parameters = true,
              dotnet_enable_inlay_hints_for_other_parameters = true,
              dotnet_enable_inlay_hints_for_parameters = true,
              dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            },
            ['csharp|code_lens'] = {
              dotnet_enable_references_code_lens = true,
            },
          },
        },
      }
    end,
    init = function()
      -- we add the razor filetypes before the plugin loads
      vim.filetype.add {
        extension = {
          razor = 'razor',
          cshtml = 'razor',
        },
      }
    end,
  },
}
```

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

If you use trouble for diagnostics, then you want to exclude the virtual
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
