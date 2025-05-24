# Neovim LSP Keymaps

This file documents all LSP-related keybindings configured in the Neovim LSP setup.

## Normal Mode (`n`)

| Keybinding   | Description                                   |
| ------------ | --------------------------------------------- |
| `gD`         | Go to declaration                             |
| `gd`         | Show definition                               |
| `gR`         | Show references (Telescope)                   |
| `gi`         | Show implementations (Telescope)              |
| `gtd`        | Show type definitions (Telescope)             |
| `<leader>ca` | Code actions                                  |
| `<leader>rn` | Rename symbol                                 |
| `<leader>D`  | Buffer diagnostics (Telescope)                |
| `<leader>d`  | Line diagnostics (float)                      |
| `[d`         | Previous diagnostic                           |
| `]d`         | Next diagnostic                               |
| `K`          | Hover documentation                           |
| `<leader>mp` | Format buffer                                 |
| `<leader>cl` | Run code lens                                 |
| `<leader>rs` | Restart LSP (only if `lsp-restart` is loaded) |

## Normal + Visual Mode (`n`, `v`)

| Keybinding   | Description  |
| ------------ | ------------ |
| `<leader>ca` | Code actions |
