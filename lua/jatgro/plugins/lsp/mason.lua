return {
  "mason-org/mason.nvim",
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jay-babu/mason-nvim-dap.nvim",
    "jay-babu/mason-null-ls.nvim",
    "neovim/nvim-lspconfig", -- Ensure lspconfig loads first
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
      pip = {
        upgrade_pip = true,
      },
      -- Configure npm to use public registry for Mason installations
      registries = {
        "github:mason-org/mason-registry",
      },
      -- max_concurrent_installers = 4,
    })

    mason_lspconfig.setup({
      ensure_installed = {
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "bashls",
        "gopls",
        "graphql",
        "eslint",
        "pyright",
        "yamlls",
      },
      automatic_installation = true,
    })

    -- Setup handlers for LSP servers
    mason_lspconfig.setup_handlers({
      -- Default handler for all servers
      function(server_name)
        if server_name == "jdtls" then
          return -- Handle Java separately with nvim-jdtls
        end
        
        local lspconfig = require("lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local capabilities = cmp_nvim_lsp.default_capabilities()
        
        -- Get server-specific config from lspconfig if available
        local servers = _G.lsp_servers or {}
        local server_config = servers[server_name] or {}
        
        -- Set capabilities
        server_config.capabilities = capabilities
        
        -- Setup the server
        lspconfig[server_name].setup(server_config)
      end,
    })

    -- Moved ensure_installed to mason_tool_installer for better organization
    mason_tool_installer.setup({
      ensure_installed = {
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
      auto_update = false,
      run_on_start = true,
    })
  end,
}
