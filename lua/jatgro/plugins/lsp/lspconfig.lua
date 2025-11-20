return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    "mason-org/mason-lspconfig.nvim",
    "mfussenegger/nvim-jdtls",
  },
  config = function()
    local lspconfig = require("lspconfig")
    local util = require("lspconfig/util")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- Enhanced capabilities
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Diagnostic configuration
    vim.diagnostic.config({
      virtual_text = {
        prefix = "●",
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- Diagnostic signs
    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    -- Keymaps on LSP attach
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
        end

        -- Navigation
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gR", "<cmd>Telescope lsp_references<CR>", "Show references")
        map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Show implementations")
        map("n", "gtd", "<cmd>Telescope lsp_type_definitions<CR>", "Show type definitions")
        
        -- Actions
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        
        -- Diagnostics
        map("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Buffer diagnostics")
        map("n", "<leader>d", vim.diagnostic.open_float, "Line diagnostics")
        map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
        
        -- Documentation
        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        
        -- Formatting
        map("n", "<leader>mp", function()
          vim.lsp.buf.format({ async = true })
        end, "Format buffer")
      end,
    })

    -- Server configurations
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
            completion = { callSnippet = "Replace" },
          },
        },
      },
      gopls = {
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_dir = util.root_pattern("go.work", "go.mod", ".git"),
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = { unusedparams = true },
          },
        },
      },
      pyright = {
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
            },
          },
        },
      },
      svelte = {
        on_attach = function(client)
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
              client.notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(ctx.file) })
            end,
          })
        end,
      },
      graphql = {
        filetypes = { "graphql", "gql", "svelte", "typescript", "javascript" },
      },
      emmet_ls = {
        filetypes = {
          "html", "css", "scss", "less", "svelte",
          "javascriptreact", "typescriptreact",
        },
      },
    }

    -- Expose server configurations and capabilities for mason-lspconfig
    _G.lsp_servers = servers
    _G.lsp_capabilities = capabilities
  end,
}