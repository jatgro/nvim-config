vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps -------------------

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk"})

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
-- keymap.set("n", "x", '"_x"')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number"}) -- increment
keymap.set("n", "<leader>-", "<C-x>", {desc = "Decrement number"})  -- decrement

-- window management 
keymap.set("n", "<leader>sv", "<C-w>v", {desc = "Split window vertically"}) -- split window verically
keymap.set("n", "<leader>sh", "<C-w>s", {desc = "Split window horizontally"}) --ssplit window horizontally
keymap.set("n", "<leader>se", "<C-w>=", {desc = "Make splits of equal size"}) -- Make splits of equal width & height 
keymap.set("n", "<leader>sx", "<cmd>close<CR>", {desc = "Close the current split "}) -- close the current split

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", {desc = "Open new tab"}) -- open new tab 
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", {desc = "Close current tab "}) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", {desc = "Go to next tab"}) -- go to next tab 
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", {desc = "Go to previous tab"}) -- go to previous tab 
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", {desc =  "Open the current buffer in new tab"}) -- move the current buffer to a new tab


keymap.set("n", "<leader>e", "<cmd>Explore<CR>", {desc =  "Open the current buffer in new tab"}) -- open the explorer 
