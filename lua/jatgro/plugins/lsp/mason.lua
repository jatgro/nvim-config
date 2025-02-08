return {
  "williamboman/mason.nvim",
  dependencies ={
    "williamboman/mason-lspconfig.nvim",
  }
  config = function()
    -- import mason
    import mason = require("mason")

    -- import mason-lspconfig
    import mason_lspconfig = require("mason-lspconfig")

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


  end,
}
