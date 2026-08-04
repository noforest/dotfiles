# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration managed with **lazy.nvim**. The primary language is Lua.

## Architecture

**Entry point:** `init.lua` loads modules in order:
1. `keymaps` — core vim keymaps (no plugins)
2. `options` — vim options (indentation, clipboard, autocmds)
3. `plugins.lazy` — all plugin specs (~3300 lines, single file)
4. `plugins.keymaps` — plugin-specific keymaps (telescope, gitsigns, neo-tree, LSP rename)
5. `plugins.options` — plugin setup (catppuccin, copilot, LSP handlers, zoxide autocmd)

Then defines custom highlight groups (`MyInfoMsg`, `MyOrange`, `MyPurple`) and calls `clangd_auto.setup()`.

**Custom module:** `lua/clangd_auto.lua` — auto-generates `.clangd` files at C project roots by scanning preprocessor macros (`#ifdef`, `#ifndef`, `#if X==Y`) and prompting the user which conditional compilation branches to activate. It skips dirs defined in `SKIP_DIRS` and ignores platform/compiler guards in `IGNORE`.

**Custom filetype:** `ftdetect/exa.vim` and `syntax/exa.vim` are symlinks to an external project (`exa` language from the PFA project at `~/Documents/enseirb/s8/pfa/`).

## Plugin Stack

| Category | Plugin |
|---|---|
| Colorscheme | catppuccin-mocha (active) |
| File picker | snacks.nvim (primary), telescope.nvim (live grep / grep string) |
| File tree | neo-tree.nvim |
| Buffer line | barbar.nvim |
| Completion | blink.cmp (LSP > path > buffer > snippets) |
| LSP | nvim-lspconfig + mason + mason-lspconfig |
| Git | gitsigns, vim-fugitive, neogit, codediff.nvim, git-conflict.nvim |
| Terminal | toggleterm |
| Copilot | github/copilot.vim |
| Session | folke/persistence.nvim |
| Navigation | zincoxide (zoxide), folke/flash.nvim |
| Database | vim-dadbod-ui |

**LSP servers configured:** `clangd` (C/C++), `lua_ls`, `texlab` (LaTeX), `ts_ls` (TypeScript), `jdtls` (Java), `rust_analyzer`, `sqls` (SQL — requires `config.yml` at project root).

**Snippets** (LuaSnip) are enabled **only** for `.tex` files.

## Key Mappings Reference

**Leader = `<Space>`**

| Key | Action |
|---|---|
| `,` / `;` | Prev/next buffer (barbar) |
| `<C-j>` | Cycle windows |
| `<leader>c` / `<leader>C` | Close buffer / close all buffers |
| `<leader>t` | Reopen last closed buffer |
| `<leader>e` | Neo-tree toggle |
| `<leader>ff` | Snacks file picker |
| `<leader>fg` / `<leader>fw` | Telescope live grep / grep word under cursor |
| `<leader><Tab>` | Telescope buffers |
| `<leader>fm` | Format (autopep8 for Python, LSP for others) |
| `<leader>r` | LSP rename symbol |
| `<leader>gd` | LSP go to definition |
| `<leader>dp/dn/dd/ds` | Diagnostic prev/next/float/list |
| `<leader>lg` | Lazygit (snacks) |
| `<leader>u` | Undotree |
| `<leader>db` | vim-dadbod-ui |
| `<leader>hB` | Git blame |
| `<leader>hn/hN` | Next/prev git hunk |
| `<leader>do` | CodeDiff history (current file) |
| `<leader>qs/ql` | Restore session / restore last session |
| `<leader>w` | Toggle line wrap |
| `<leader>x` | Toggle colorcolumn at 80 |
| `<leader>z` | Zoxide navigate |
| `<leader><BS>` | Return to startup directory |
| `<C-ù>` | Toggle terminal |
| `<C-J>` (insert) | Accept Copilot suggestion |
| `<CR>` | Clear search highlight |
| `K` / `J` | Move line up/down (normal and visual) |
| `p` / `P` | Paste from system clipboard with auto-indent |

## Notes on plugin.lazy.lua

The file is large and heavily commented-out with alternative configurations. Active configuration is the uncommented code. Many plugins have both a commented-out old approach and the current active approach side-by-side — when editing, be careful not to accidentally uncomment old code.

The `sqls` LSP requires a `config.yml` at the project root (see the inline comment template in `lazy.lua` around line 3235).
