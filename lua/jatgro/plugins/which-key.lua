return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  config = function()
    local wk = require("which-key")
    
    wk.setup({})
    
    -- Register key groups
    wk.add({
      { "<leader>c", group = "Code/Copilot" },
      { "<leader>d", group = "Database/Diagnostics" },
      { "<leader>e", group = "Explorer" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Git Hunks" },
      { "<leader>l", group = "LSP/Lint" },
      { "<leader>m", group = "Molten/Markup/Format" }, -- Updated group name
      { "<leader>n", group = "Notifications" },
      { "<leader>s", group = "Split/Session" },
      { "<leader>t", group = "Tabs/Todos/Theme" },
      { "<leader>w", group = "Workspace" },
      { "<leader>x", group = "Trouble" },
    })
  end,
}