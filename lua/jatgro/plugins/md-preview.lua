return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function()
    if vim.fn["mkdp#util#install"] then
      vim.fn["mkdp#util#install"]()
    end
  end,
}
