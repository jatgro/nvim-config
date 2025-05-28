-- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.

return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local none_ls = require("none-ls")
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    none_ls.setup({
      sources = {
        -- Formatting/Diagnostics for your existing languages:
        -- Go (enhancements beyond gopls)
        none_ls.builtins.formatting.gofumpt,
        none_ls.builtins.formatting.goimports_reviser,
        none_ls.builtins.formatting.golines,

        -- Lua (complements lua_ls)
        none_ls.builtins.formatting.stylua,

        -- JavaScript/TypeScript (complements Svelte/GraphQL/Emmet setup)
        none_ls.builtins.diagnostics.eslint_d,
        none_ls.builtins.code_actions.eslint_d,
        none_ls.builtins.formatting.prettier.with({
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

        -- Java (complements jdtls)
        none_ls.builtins.formatting.google_java_format,

        -- Shell/Bash (common companion to other langs)
        none_ls.builtins.diagnostics.shellcheck,
        none_ls.builtins.formatting.shfmt,
      },
        on_attach = function(client, bufnr)
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
                    return client.name == "none-ls"
                  end,
                })
              end,
            })
          end
        end,
      },
    })
  end,
}
