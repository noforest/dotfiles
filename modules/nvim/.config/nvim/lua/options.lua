vim.cmd("let g:netrw_liststyle = 3")

-- -- Disable the background colour to get the terminal's
-- vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
-- vim.cmd("hi LineNr guibg=NONE ctermbg=NONE")
-- vim.cmd("hi SignColumn guibg=NONE ctermbg=NONE")

local opt = vim.opt

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- languages for the spell checker
opt.spelllang = { "en_us", "fr" }
-- A missing dictionary is fetched without asking, and only once the event is
-- over: neogit sets 'spell' on its commit buffer from an RPC request, where
-- neither the prompt nor a notification can open, and the commit editor breaks.
-- This replaces the autocommand of runtime/plugin/spellfile.lua.
vim.g.loaded_spellfile_plugin = true
require("nvim.spellfile").config({ confirm = false })
vim.api.nvim_create_autocmd("SpellFileMissing", {
    callback = function(args)
        vim.schedule(function()
            local spell = vim.wo.spell -- the download leaves it toggled
            require("nvim.spellfile").get(args.match)
            vim.wo.spell = spell
        end)
    end,
})

-- line numbers
opt.relativenumber = false -- absolute line numbers only
opt.number = true
opt.cursorline = false

-- tabs & indentation
opt.tabstop = 4 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one
opt.smartindent = true  -- Smart indentation
opt.scrolloff = 3
opt.cinkeys:remove("0#")

-- DiffView Delete line as in CodeDiff 
-- add this anyway -> vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#444444" })
vim.opt.fillchars:append { diff = "╱" }


-- options.lua
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
-- vim.opt.fileencodings = { "utf-8", "utf-16", "latin1" }
vim.opt.fileencodings = { "utf-8", "latin1" }


opt.wrap = false
opt.linebreak = true          -- wrap cleanly without breaking words
opt.breakindent = true        -- keep the indentation for wrapped lines
-- -- opt.showbreak = "↳"          -- symbol marking the start of a wrapped line
--
--
-- -- Move by visual line in normal and visual mode
-- for _, mode in ipairs({ "n", "v" }) do
--     vim.keymap.set(mode, "j", "gj", { noremap = true, silent = true })
--     vim.keymap.set(mode, "k", "gk", { noremap = true, silent = true })
--     vim.keymap.set(mode, "<Down>", "gj", { noremap = true, silent = true })
--     vim.keymap.set(mode, "<Up>", "gk", { noremap = true, silent = true })
--     vim.keymap.set(mode, "$", "g$", { noremap = true, silent = true })
--     vim.keymap.set(mode, "0", "g0", { noremap = true, silent = true })
-- end



vim.o.autoread = true


-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- appearance

-- turn on termguicolors for (nightfly) colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

-- keep changes even after the file is closed
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

-- Disable the bottom bar
vim.opt.laststatus = 0

-- disable the insert mode, visual mode etc. indicator
vim.opt.showmode = false

-- Show the line and column numbers in the command line
vim.opt.ruler = true

-- Show the relative position in the file (top, bottom, etc.)
vim.opt.showcmd = true


vim.o.shell = "/bin/bash"

-- opt.colorcolumn = "80"

-- I also don't want <CR> to move me down a line
vim.api.nvim_set_keymap('n', '<CR>', ':nohlsearch<CR>', { noremap = true, silent = true })

-- -- :noh on <CR>, and markdown links moved to <leader><CR>
-- vim.api.nvim_create_autocmd("BufEnter", {
--     pattern = "*.md",
--     callback = function()
--         local buf = vim.api.nvim_get_current_buf()
--
--         -- Get the plugin's existing <CR> mapping
--         local original_cr
--         local maps = vim.api.nvim_buf_get_keymap(buf, 'n')
--         for _, m in ipairs(maps) do
--             if m.lhs == "<CR>" then
--                 original_cr = m.rhs
--                 break
--             end
--         end
--
--         -- Remap <CR> to :noh
--         vim.keymap.set("n", "<CR>", ":noh<CR>", { silent = true, buffer = true })
--
--         -- Remap <C-CR> for the old behaviour
--         if original_cr then
--             vim.keymap.set("n", "<leader><CR>", original_cr, { silent = true, buffer = true })
--         end
--     end,
-- })

-- a link can no longer be opened with <CR> in markdown (use :gx)
-- vim.api.nvim_create_autocmd("FileType", {
--     pattern = "markdown",
--     callback = function()
--         vim.keymap.set("n", "<CR>", function()
--             vim.cmd("noh")
--         end, { buffer = true, silent = true })
--     end,
-- })

--disables comment autocompletion
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})


-- ~~~~~~~ fills the empty space in nvim, because there are sometimes black gaps
vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  callback = function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    if not normal.bg then return end
    io.write(string.format("\027]11;#%06x\027\\", normal.bg))
  end,
})

-- vim.api.nvim_create_autocmd("VimLeave", {
--   callback = function()
--     -- Explicitly changes the background colour on quit
--     io.write("\027]11;#101010\027\\")  -- Replace #000000 with the default colour of your `st` terminal
--   end,
-- })
vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
        -- Resets the background colour to the terminal default
        io.write("\027]111\027\\")  -- Sequence resetting the background colour
    end,
})


vim.api.nvim_create_autocmd('BufReadPost', {
    desc = 'Open file at the last position it was edited earlier',
    group = misc_augroup,
    pattern = '*',
    command = 'silent! normal! g`"zv'
})

-- -- ~~~~~~~ The code below keeps the cursor from stepping back when entering normal mode

-- vim.api.nvim_create_autocmd("InsertLeave", {
--   callback = function()
--     if vim.fn.col('.') < vim.fn.col('$') then
--       vim.cmd("normal! l")
--     end
--   end,
-- })



-- local function update_bufferline()
--     local buffer_count = #vim.api.nvim_list_bufs()
--     if buffer_count == 1 then
--         vim.opt_local.showtabline = 0  -- Hide the tab line (bufferline)
--     else
--         vim.opt_local.showtabline = 2  -- Always show the tab line
--     end
-- end


-- Keep terminal colors consistent after quitting Vim in tmux

vim.cmd([[
if exists('$TMUX')
    " Tell Vim to use 256 colors and prevent background reset on exit
    set t_ti= t_te=
    set t_8f=\\<Esc>[38;2;%lu;%lu;%lum
    set t_8b=\\<Esc>[48;2;%lu;%lu;%lum
    endif
    ]])

-- vim.api.nvim_create_autocmd("BufEnter", {
--     pattern = "*.rs",
--     callback = function()
--         -- Save the cursor position
--         local cursor_pos = vim.api.nvim_win_get_cursor(0)
--         local view = vim.fn.winsaveview()
--
--         -- Go to the end of the file
--         vim.cmd("normal! G")
--
--         -- Add a new line
--         vim.cmd("normal! o")
--
--         -- Delete the line just added
--         vim.cmd("normal! dd")
--
--         -- Restore the cursor position and the view
--         vim.fn.winrestview(view)
--         vim.api.nvim_win_set_cursor(0, cursor_pos)
--         vim.bo.modified = true
--     end,
--     desc = "Marks Rust files as modified when opened"
-- })

