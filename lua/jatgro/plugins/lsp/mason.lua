return {
  "mason-org/mason.nvim",
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jay-babu/mason-nvim-dap.nvim",
    "jay-babu/mason-null-ls.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      -- max_concurrent_installers = 4,
    })

    mason_lspconfig.setup({
      ensure_installed = {
        "html",
        "cssls",
        "css_variables",
        "cssmodules_ls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "bashls",
        "gopls",
        "graphql",
        "eslint",
        "pyright",
        "yamlls",
        "markdown_oxide",
      },
      automatic_enable = false,
      automatic_installation = true,
    })

    -- Moved ensure_installed to mason_tool_installer for better organization
    mason_tool_installer.setup({
      ensure_installed = {
        -- LSP servers
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "graphql",
        "marksman",
        "pyright",
        "sqlls",
        "gopls",
        "ruff-lsp",

        -- Formatters
        "prettierd",
        "stylua",
        "google-java-format",
        "shfmt",
        "sqlfmt",
        "gofumpt",

        -- Linters
        "eslint_d",
        "shellcheck",
        "goimports-reviser",
        "golines",

        -- Debuggers
        "debugpy",
      },
      auto_update = true,
      run_on_start = true,
    })
  end,
}
