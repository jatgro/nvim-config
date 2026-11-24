return {
  "meanderingprogrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you use standalone mini plugins, replace with "echasnovski/mini.nvim"
  ft = { "markdown", "copilot-chat" },
  keys = {
    { "<leader>tm", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown Render" },
  },
  opts = {
    file_types = { "markdown", "copilot-chat" },
  },
}
