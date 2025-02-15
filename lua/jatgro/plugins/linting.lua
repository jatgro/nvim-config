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
      args = { "-f", "xml", "-" },
      stdin = true,
      stream = "stdout",
      ignore_exitcode = true,
      parser = function(output, bufnr)
        local diagnostics = {}
        for file, line, col, message in
          output:gmatch(
            '<file name="[^"]-">.-<error line="(%d+)" column="(%d+)" severity="[^"]-" message="([^"]-)" source="([^"]-)"'
          )
        do
          table.insert(diagnostics, {
            lnum = tonumber(line) - 1,
            col = tonumber(col) - 1,
            message = message,
            severity = vim.diagnostic.severity.WARN,
            source = "checkstyle",
          })
        end
        return diagnostics
      end,
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
