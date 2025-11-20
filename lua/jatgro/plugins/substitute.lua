return {
  "gbprod/substitute.nvim",
  keys = {
    { "s", mode = "n" },
    { "ss", mode = "n" },
    { "S", mode = "n" },
    { "s", mode = "x" },
  },
  config = function()
    local substitute = require("substitute")
    
    substitute.setup()

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n","s", substitute.operator, {desc ="substitute with motion"})
    keymap.set("n","ss", substitute.line, {desc ="substitute line"})
    keymap.set("n","S", substitute.eol, {desc ="substitute to the end of the line "})
    keymap.set("x","s", substitute.visual, {desc ="substitute in the visual mode"})

  end
}
