return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    "mfussenegger/nvim-jdtls", -- Added Java LSP dependency
  },
  config = function()
    local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local keymap = vim.keymap
    local jdtls = require("jdtls") -- Added Java LSP

    -- Enhanced capabilities
    local capabilities = vim.tbl_deep_extend("force", cmp_nvim_lsp.default_capabilities(), {
      textDocument = {
        codeLens = { dynamicRegistration = true },
      },
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    })

    -- Improved diagnostic signs
    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        -- Enhanced keymaps
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
        end

        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gd", vim.lsp.buf.definition, "Show definition")
        map("n", "gR", "<cmd>Telescope lsp_references<CR>", "Show references")
        map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Show implementations")
        map("n", "gtd", "<cmd>Telescope lsp_type_definitions<CR>", "Show type definitions")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Buffer diagnostics")
        map("n", "<leader>d", vim.diagnostic.open_float, "Line diagnostics")
        map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "<leader>f", vim.lsp.buf.format, "Format buffer")
        map("n", "<leader>cl", "<cmd>lua vim.lsp.codelens.run()<CR>", "Run code lens")

        -- Only set LSP restart if available
        if package.loaded["lsp-restart"] then
          map("n", "<leader>rs", "<cmd>LspRestart<CR>", "Restart LSP")
        end
      end,
    })

    -- First ensure mason-lspconfig is setup
    mason_lspconfig.setup()

    -- Then get the list of installed servers
    local installed_servers = mason_lspconfig.get_installed_servers()

    -- Configure each server explicitly
    for _, server_name in ipairs(installed_servers) do
      local server_config = {
        capabilities = capabilities,
      }

      -- Server-specific configurations
      if server_name == "lua_ls" then
        server_config.settings = {
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
        }
      elseif server_name == "svelte" then
        server_config.on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = true
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
              client.notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(ctx.file) })
            end,
          })
        end
      elseif server_name == "graphql" then
        server_config.filetypes = { "graphql", "gql", "svelte", "typescript", "javascript" }
      elseif server_name == "emmet_ls" then
        server_config.filetypes = {
          "html",
          "css",
          "scss",
          "less",
          "svelte",
          "javascriptreact",
          "typescriptreact",
        }
      elseif server_name == "jdtls" then
        -- Skip as we handle Java separately
        goto continue
      end

      lspconfig[server_name].setup(server_config)
      ::continue::
    end

    -- Java LSP setup (handled separately)
    jdtls.start_or_attach({
      cmd = { -- Your existing Java config from previous file },
        root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),
        capabilities = capabilities,
        settings = {
          java = {
            configuration = {
              runtimes = {
                { name = "JavaSE-23", path = "/Library/Java/JavaVirtualMachines/openjdk-23.jdk/Contents/Home" },
              },
            },
          },
        },
      },
    })
  end,
}
