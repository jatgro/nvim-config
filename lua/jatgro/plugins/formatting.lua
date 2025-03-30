return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        -- Web Development
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
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
        python = { "isort", "black" },
        java = { "google-java-format" },
        sh = { "shfmt" },
        sql = { "sqlfmt" },
        
        -- Add more filetypes as needed
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
    end, { desc = "[M]arkup [P]rettify (format file/range)" })

    -- Create autocmd to format on save for specific filetypes
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        conform.format({ bufnr = args.buf })
      end,
    })
  end,
}
