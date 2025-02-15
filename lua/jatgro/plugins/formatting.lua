return {
  "stevearc/conform.nvim",
  event = { "bufreadpre", "bufnewfile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        java = { "google-java-format" }, -- Add this line for Java
      },

      -- Formatter configurations
      formatters = {
        ["google-java-format"] = {
          command = "google-java-format",
          args = { "--aosp", "-" }, -- Use "--aosp" for AOSP style
          stdin = true,
        },

        format_on_save = {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        },
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "format file or range (in visual mode)" })
  end,
}
