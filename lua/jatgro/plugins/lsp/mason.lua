return {
  "mason-org/mason.nvim",
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
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
      max_concurrent_installers = 4,
    })

    mason_lspconfig.setup({
      -- Updated to use automatic_installation instead of ensure_installed
      -- (more flexible approach)
      automatic_installation = {
        exclude = {}, -- List of LSPs to exclude from automatic installation
      },
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

        -- Formatters
        "prettierd",
        "stylua",
        "black",
        "isort",
        "google-java-format",
        "shfmt",
        "sqlfmt",

        -- Linters
        "eslint_d",
        "flake8",
        "pylint",
        "shellcheck",

        -- Debuggers
        "debugpy",
      },
      auto_update = true,
      run_on_start = true,
    })
  end,
}
