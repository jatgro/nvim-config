-- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.

return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local null_ls = require("null-ls")
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    null_ls.setup({
      sources = {
        -- Formatting/Diagnostics for your existing languages:
        -- Go (enhancements beyond gopls)
        null_ls.builtins.formatting.gofumpt,
        null_ls.builtins.formatting.goimports_reviser,
        null_ls.builtins.formatting.golines,

        -- Lua (complements lua_ls)
        null_ls.builtins.formatting.stylua,

        -- JavaScript/TypeScript (complements Svelte/GraphQL/Emmet setup)

        null_ls.builtins.formatting.prettier.with({
          filetypes = {
            "javascript",
            "typescript",
            "svelte",
            "graphql",
            "html",
            "css",
            "scss",
            "less",
          },
        }),

        -- Python (modern and faster setup)
        null_ls.builtins.formatting.ruff,
        null_ls.builtins.diagnostics.ruff,

        -- Java (complements jdtls)
        null_ls.builtins.formatting.google_java_format,

        -- Shell/Bash (common companion to other langs)
        -- null_ls.builtins.diagnostics.shellcheck,
        null_ls.builtins.formatting.shfmt,

        -- ESLint diagnostics and code actions
        -- null_ls.builtins.code_actions.eslint.with({
        --   command = vim.fn.stdpath("data") .. "/mason/bin/eslint",
        -- }),
      },
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
                filter = function(client)
                  -- Prefer none-ls for formatting where available
                  return client.name == "none_ls"
                end,
              })
            end,
          })
        end
      end,
    })
  end,
}
