return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      python = { "pylint" },
      java = { "checkstyle" },
    }

    -- Configure the Checkstyle linter

    lint.linters.checkstyle = {
      cmd = "checkstyle",
      args = { "-c", "~/.config/checkstyle/google_checks.xml" },
      stdin = false,
      stream = "stderr",
      ignore_exitcode = true,
      parser = require("lint.parser").from_errorformat("%f:%l:%c: %m", {
        source = "checkstyle",
        severity = vim.diagnostic.severity.WARN,
      }),
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>lc", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
