return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    { "windwp/nvim-ts-autotag", opts = {} },
  },
  config = function()
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt.foldenable = false
    vim.opt.foldlevel = 99

    require("nvim-treesitter").install({
      "json", "javascript", "typescript", "tsx", "yaml", "html", "css", "prisma",
      "markdown", "markdown_inline", "graphql", "svelte", "bash", "lua", "vim",
      "dockerfile", "gitignore", "query", "vimdoc", "java", "python", "sql", "xml", "toml",
    })

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(args.buf))
        if stat and stat.size > 100 * 1024 then
          return
        end
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
