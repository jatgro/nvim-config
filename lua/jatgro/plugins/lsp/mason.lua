
-- mason.lua (Mason v2 / Mason-LSPConfig v2 for Neovim 0.11+)
-- Requires: mason.nvim >= 2.0, mason-lspconfig.nvim >= 2.0, nvim-lspconfig >= 2.0
-- NOTE: Neovim 0.11 introduced `vim.lsp.config` which this file uses.
-- Ref: https://github.com/mason-org/mason-lspconfig.nvim (v2 docs & requirements)
--      https://newreleases.io/.../mason-lspconfig.nvim/release/v2.0.0 (breaking changes)
--      https://kosu.me/.../breaking-changes-in-mason-2-0-how-i-updated-my-neovim-lsp-config (migration notes)

return {
  "mason-org/mason.nvim",
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jay-babu/mason-nvim-dap.nvim",          -- optional: DAP via Mason
    -- If you use none-ls (null-ls successor), keep this (optional):
    -- "nvimtools/none-ls.nvim",
    -- "jay-babu/mason-null-ls.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",                  -- capabilities for completion
  },

  config = function()
    ---------------------------------------------------------------------------
    -- 1) Mason core (package manager for LSP/DAP/formatters/linters)
    ---------------------------------------------------------------------------
    require("mason").setup({
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
      -- You can omit `registries` to use the default.
      registries = {
        "github:mason-org/mason-registry",
      },
    })

    ---------------------------------------------------------------------------
    -- 2) Mason-LSPConfig v2: install & auto-enable servers (no setup_handlers)
    --    In v2, `automatic_installation` is removed; use `ensure_installed`.
    --    `automatic_enable` auto-runs `vim.lsp.enable()` for installed servers.
    ---------------------------------------------------------------------------
    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "bashls",
        "gopls",
        "graphql",
        "eslint",
        "pyright",
        "yamlls",
        -- Add more servers as needed (e.g., "ts_ls" for TypeScript in lspconfig v2)
      },
      -- auto-enable all servers except those you’ll manage manually
      automatic_enable = { exclude = { "jdtls" } }, -- Java typically uses nvim-jdtls separately
    })

    ---------------------------------------------------------------------------
    -- 3) Global LSP defaults using Neovim’s native API (0.11+)
    --    This is the recommended way in v2-era setups.
    --    It applies to all enabled LSP clients unless overridden per server.
    ---------------------------------------------------------------------------
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    vim.lsp.config("*", {
      capabilities = capabilities,
      -- Example: on_attach for common LSP keymaps
      -- on_attach = function(client, bufnr)
      --   local map = function(mode, lhs, rhs, desc)
      --     vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      --   end
      --   map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", "Go to definition")
      --   map("n", "gD", vim.lsp.buf.declaration,              "Go to declaration")
      --   map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Go to implementations")
      --   map("n", "gr", "<cmd>Telescope lsp_references<CR>",  "References")
      --   map("n", "K",  vim.lsp.buf.hover,                    "Hover documentation")
      --   map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
      --   map("n", "<leader>rn", vim.lsp.buf.rename,           "Rename symbol")
      --   map("n", "[d", vim.diagnostic.goto_prev,             "Prev diagnostic")
      --   map("n", "]d", vim.diagnostic.goto_next,             "Next diagnostic")
