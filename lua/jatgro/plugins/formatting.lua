return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        -- Web Development
        javascript = { "prettierd", "eslint_d" },
        typescript = { "prettierd", "eslint_d" },
        javascriptreact = { "prettierd", "eslint_d" },
        typescriptreact = { "prettierd", "eslint_d" },
        svelte = { "prettierd" },
        css = { "prettierd" },
        html = { "prettierd" },
        json = { "prettierd" },
        yaml = { "prettierd" },
        graphql = { "prettierd" },
        
        -- Markup/Data
        markdown = { "prettierd" },
        liquid = { "prettierd" },
        
        -- Programming Languages
        lua = { "stylua" },
        python = { "ruff_format", "ruff_fix" },
        java = { "google-java-format" },
        sh = { "shfmt" },
        sql = { "sqlfmt" },
        go = { "gofumpt", "goimports-reviser", "golines" },
      },
      
      format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true,
        async = false,
      },
      
      formatters = {
        ["google-java-format"] = {
          command = "google-java-format",
          args = { "--aosp", "-" },
          stdin = true,
        },
        ["shfmt"] = {
          command = "shfmt",
          args = { "-i", "2", "-bn", "-ci", "-sr" },
          stdin = true,
        },
        ["sqlfmt"] = {
          command = "sqlfmt",
          args = { "-" },
          stdin = true,
        },
      },
    })

    -- Keymaps for formatting
    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range" })
  end,
}