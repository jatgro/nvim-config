return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed ={
        "ts_ls",
        "html", 
        "htmx",
        "cssls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "graphql",
        "marksman",
--        "java_language_server",
        "pyright",
        "sqlls",
      }

     })


  end,
}
