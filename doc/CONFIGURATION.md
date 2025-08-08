# Example configurations

- [Example configurations](#example-configurations)
  - [1. lazy.nvim example](#1-lazynvim-example)
    - [Manually](#manually)
    - [Mason](#mason)
  - [2. vim.pack example (Neovim 0.12+)](#2-vimpack-example-neovim-012)
    - [Overall structure](#overall-structure)
    - [`init.lua`](#initlua)
    - [`lsp/roslyn.lua`](#lsproslynlua)
      - [Manually](#manually-1)
      - [Mason](#mason-1)
    - [`lua/config/filetypes.lua`](#luaconfigfiletypeslua)
    - [`lua/plugins/roslyn-nvim.lua`](#luapluginsroslyn-nvimlua)
    - [`lua/plugins/rzls-nvim.lua`](#luapluginsrzls-nvimlua)

## 1. lazy.nvim example

### Manually

```lua
return {
    {
        "seblyng/roslyn.nvim",
        ft = { "cs", "razor" },
        dependencies = {
            {
                -- By loading as a dependency, we ensure that we are available to set
                -- the handlers for Roslyn.
                "tris203/rzls.nvim",
                config = true,
            },
        },
        config = function()
            -- Adjust these paths to where you installed Roslyn and rzls.
            local roslyn_base_path = vim.fs.joinpath(vim.fn.stdpath("data"), "roslyn")
            local rzls_base_path = vim.fs.joinpath(vim.fn.stdpath("data"), "rzls")

            local cmd = {
                "dotnet",
                vim.fs.joinpath(roslyn_base_path, "Microsoft.CodeAnalysis.LanguageServer.dll"),
                "--stdio",
                "--logLevel=Information",
                "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
                "--razorSourceGenerator=" .. vim.fs.joinpath(rzls_base_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
                "--razorDesignTimePath=" .. vim.fs.joinpath(rzls_base_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
                "--extension",
                vim.fs.joinpath(rzls_base_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
            }

            vim.lsp.config("roslyn", {
                cmd = cmd,
                handlers = require("rzls.roslyn_handlers"),
                settings = {
                    ["csharp|inlay_hints"] = {
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
                    ["csharp|code_lens"] = {
                        dotnet_enable_references_code_lens = true,
                    },
                },
            })
            vim.lsp.enable("roslyn")
        end,
        init = function()
            -- We add the Razor file types before the plugin loads.
            vim.filetype.add({
                extension = {
                    razor = "razor",
                    cshtml = "razor",
                },
            })
        end,
    },
}
```

### Mason

```lua
return {
    {
        "seblyng/roslyn.nvim",
        ft = { "cs", "razor" },
        dependencies = {
            {
                -- By loading as a dependencies, we ensure that we are available to set
                -- the handlers for Roslyn.
                "tris203/rzls.nvim",
                config = true,
            },
        },
        config = function()
            local mason_registry = require("mason-registry")
            local rzls_pkg = mason_registry.get_package("rzls")
            local rzls_path = vim.fs.joinpath(rzls_pkg:get_install_path(), "libexec")

            local cmd = {
                "roslyn",
                "--stdio",
                "--logLevel=Information",
                "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
                "--razorSourceGenerator=" .. vim.fs.joinpath(rzls_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
                "--razorDesignTimePath=" .. vim.fs.joinpath(rzls_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
                "--extension",
                vim.fs.joinpath(rzls_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
            }

            vim.lsp.config("roslyn", {
                cmd = cmd,
                handlers = require("rzls.roslyn_handlers"),
                settings = {
                    ["csharp|inlay_hints"] = {
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
                    ["csharp|code_lens"] = {
                        dotnet_enable_references_code_lens = true,
                    },
                },
            })
            vim.lsp.enable("roslyn")
        end,
        init = function()
            -- We add the Razor file types before the plugin loads.
            vim.filetype.add({
                extension = {
                    razor = "razor",
                    cshtml = "razor",
                },
            })
        end,
    },
}
```


## 2. vim.pack example (Neovim 0.12+)

Example of a modular configuration with `vim.pack` in `Neovim v0.12+`

### Overall structure

```text
├── init.lua
├── lsp
│   └── roslyn.lua
└── lua
    ├── config
    │   └── filetypes.lua
    └── plugins
        ├── roslyn-nvim.lua
        └── rzls-nvim.lua
```

### `init.lua`
```lua
-- Core
require("config.filetypes")

-- Plugins
require("plugins.rzls-nvim")
require("plugins.roslyn-nvim")
```

### `lsp/roslyn.lua`

#### Manually

```lua
-- Adjust these paths to where you installed Roslyn and rzls.
local roslyn_base_path = vim.fs.joinpath(vim.fn.stdpath("data"), "roslyn")
local rzls_base_path = vim.fs.joinpath(vim.fn.stdpath("data"), "rzls")

local cmd = {
    "dotnet",
    vim.fs.joinpath(roslyn_base_path, "Microsoft.CodeAnalysis.LanguageServer.dll"),
    "--stdio",
    "--logLevel=Information",
    "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
    "--razorSourceGenerator=" .. vim.fs.joinpath(rzls_base_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
    "--razorDesignTimePath=" .. vim.fs.joinpath(rzls_base_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
    "--extension",
    vim.fs.joinpath(rzls_base_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
}

vim.lsp.config("roslyn", {
    cmd = cmd,
    handlers = require("rzls.roslyn_handlers"),
    filetypes = { "cs" },
    root_markers = { { ".sln", ".csproj", "project.json" }, ".git" },
    settings = {
        ["csharp|inlay_hints"] = {
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
        ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
        },
        ["csharp|completion"] = {
            dotnet_show_name_completion_suggestions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
        },
        ["csharp|background_analysis"] = {
            background_analysis = {
                dotnet_analyzer_diagnostics_scope = "fullSolution",
                dotnet_compiler_diagnostics_scope = "fullSolution",
            },
        },
    }
})
```

#### Mason

```lua
require("mason-registry")
local rzls_path = vim.fn.expand("$MASON/packages/rzls/libexec")

local cmd = {
    "roslyn",
    "--stdio",
    "--logLevel=Information",
    "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
    "--razorSourceGenerator=" .. vim.fs.joinpath(rzls_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
    "--razorDesignTimePath=" .. vim.fs.joinpath(rzls_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
    "--extension",
    vim.fs.joinpath(rzls_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
}

vim.lsp.config("roslyn", {
    cmd = cmd,
    handlers = require("rzls.roslyn_handlers"),
    filetypes = { "cs" },
    root_markers = { { ".sln", ".csproj", "project.json" }, ".git" },
    settings = {
        ["csharp|inlay_hints"] = {
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
        ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
        },
        ["csharp|completion"] = {
            dotnet_show_name_completion_suggestions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
        },
        ["csharp|background_analysis"] = {
            background_analysis = {
                dotnet_analyzer_diagnostics_scope = "fullSolution",
                dotnet_compiler_diagnostics_scope = "fullSolution",
            },
        },
    }
})
```


### `lua/config/filetypes.lua`

```lua
vim.filetype.add({
  extension = {
    razor = "razor",
    cshtml = "razor",
  },
})
```

### `lua/plugins/roslyn-nvim.lua`

```lua
vim.pack.add({ "https://github.com/seblyng/roslyn.nvim.git" })

require("roslyn").setup({
    ft = { "cs", "razor" }
})
```

### `lua/plugins/rzls-nvim.lua`

```lua
vim.pack.add({ "https://github.com/tris203/rzls.nvim.git" })

require("rzls").setup({})
```