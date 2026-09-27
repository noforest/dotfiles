-- telescope
-- vim.keymap.set("n", "<leader>ff", ":Telescope find_files<cr>", { silent = true }) !!!!!!!!!!!!!!!!!!!!!!!!!!! replaced by snacks because it is smart
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<cr>", { silent = true })
vim.keymap.set("n", "<leader>fw", ":Telescope grep_string<cr>", { silent = true }) --find word
-- vim.keymap.set("n", "<leader>fa", ":Telescope lsp_dynamic_workspace_symbols<cr>", { silent = true }) -- g for everything related to lsp, and a for all (symbols)

-- CAREFUL <leader>fd and <leader>fr ARE DEFINED in lazy.lua
-- vim.keymap.set("n", "<leader>fc", ":Telescope git_bcommits<cr>", { silent = true })  !!!!!!!!!// replaced by <leader>fc in snacks
vim.keymap.set("n", "<leader><Tab>", ":Telescope buffers<cr>", { silent = true })



-- tree
-- vim.keymap.set("n", "<leader>e", ":NvimTreeFindFileToggle<cr>", { silent = true })
-- --> mini.files takes over: see lazy.lua
vim.keymap.set("n", "<leader>e", ":Neotree toggle<cr>", { silent = true })


-- vim-dadbod-ui
vim.keymap.set("n", "<leader>db", ":DBUIToggle<cr>", { silent = true })




-- Undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>dN', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float)
-- !!!!!!!!! IN LAZY.LUA     { "<leader>ds", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" } !!!!!!!!!!!!


-- lazygit plugin (Plugin for calling lazygit from within neovim)
-- vim.keymap.set('n', '<leader>lg', "<cmd>LazyGit<cr>", { silent = true })




-- --diffViews keymaps
-- vim.keymap.set('n', '<leader>do', ":DiffviewFileHistory %<CR>", { silent = true })
-- vim.keymap.set('n', '<leader>dc', ":DiffviewClose<CR>", { silent = true })
vim.keymap.set("n", "<leader>do", ":CodeDiff history %<CR>", { desc = "CodeDiff history of one file" })
-- vim.keymap.set("v", "<leader>dh", ":'<,'>DiffviewFileHistory<cr>", {desc = "Selection history" })

-- NOTE: shows the older versions of the selected lines
vim.keymap.set("v", "<leader>hh", ":'<,'>CodeDiff linehist<cr>", { silent = true }) 





-- Gitsigns: add mappings with `on_attach`
local gitsigns = require('gitsigns')

gitsigns.setup({
  current_line_blame = false,
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    -- Local mapping function
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation shortcuts
    map('n', '<leader>hn', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    map('n', '<leader>hN', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    -- Actions
    -- map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>')
    map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>')
    -- map('n', '<leader>hR', gs.reset_buffer)
    map('n', '<leader>hu', gs.undo_stage_hunk)
    map({'n', 'v'}, '<leader>hp', gs.preview_hunk)
    -- map('n', '<leader>hb', function() gs.blame_line { full = true } end)
    -- map('n', '<leader>hB', gs.blame)
    -- map('n', '<leader>tB', gs.toggle_current_line_blame)
    -- map('n', '<leader>hd', gs.diffthis)
    -- map('n', '<leader>hD', function() gs.diffthis('~') end)
  end
})

vim.keymap.set('n', '<leader>hB', ":G blame<CR>", { silent = true })

-- local function open_file_and_hide_cursor(api)
--   -- Disables cursorline for the nvim-tree panel
--   -- vim.wo.cursorline = false
--   vim.wo.cursorline = true
--
--   -- Opens the file and goes back to the nvim-tree panel
--   api.node.open.edit()
--   vim.cmd("wincmd p")
--
--   -- Disables cursorline again to keep the cursor invisible
--   -- vim.wo.cursorline = false
--
--   -- Keep the highlight under the cursor without showing the cursor
--   vim.opt.guicursor = "n:blinkon0,i:ver25" -- Hides the cursor visually
-- end
--
--
--
-- local function open_folder_and_highlight_cursor(api)
--   -- Enables the highlight under the cursor (cursorline) for the nvim-tree panel
--   vim.wo.cursorline = true
--
--   -- Opens the folder without losing the tree
--   api.node.open.tab()
--
--   -- Hides the cursor visually without affecting the highlight line
--   vim.opt.guicursor = "n:blinkon0,i:ver25"  -- This hides the cursor without disabling "cursorline"
-- end
--
-- local function my_on_attach(bufnr)
--   local api = require("nvim-tree.api")
--
--   local function opts(desc)
--     return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
--   end
--
--   -- Default mappings
--   api.config.mappings.default_on_attach(bufnr)
--
--   -- Custom mapping for <Tab>
--   -- vim.keymap.set('n', '<Tab>', function() open_file_and_hide_cursor(api) end, opts("Open File and Stay"))
--
--   -- Custom mapping for <Tab>: open a file or a folder
--   vim.keymap.set('n', '<Tab>', function()
--     local node = api.tree.get_node_under_cursor()
--     if node and node.type == 'directory' then
--       open_folder_and_highlight_cursor(api)
--     else
--       open_file_and_hide_cursor(api)
--     end
--   end, opts("Open File or Folder and Highlight"))
-- end
--
-- -- nvim-tree configuration with on_attach
-- require("nvim-tree").setup {
--   on_attach = my_on_attach,
--   -- other options...
-- }

-------------------------------------------------------------------------------------------------------------
-- Still for nvim tree
-- local function open_file_and_hide_cursor(api)
--   vim.wo.cursorline = true
--   api.node.open.no_window_picker()
--   vim.cmd("wincmd p")
--   vim.opt.guicursor = "n:blinkon0,i:ver25" -- Hides the cursor visually
-- end
--
--
-- local function open_folder_and_highlight_cursor(api)
--   vim.wo.cursorline = true
--   api.node.open.tab()
--   vim.opt.guicursor = "n:blinkon0,i:ver25"  -- This hides the cursor without disabling "cursorline"
-- end
--
-- local function my_on_attach(bufnr)
--   local api = require("nvim-tree.api")
--   local function opts(desc)
--     return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
--   end
--   api.config.mappings.default_on_attach(bufnr)
--   vim.keymap.set('n', '<Tab>', function()
--     local node = api.tree.get_node_under_cursor()
--     if node and node.type == 'directory' then
--       open_folder_and_highlight_cursor(api)
--     else
--       open_file_and_hide_cursor(api)
--     end
--   end, opts("Open File or Folder and Highlight"))
-- end
--
--
-- require("nvim-tree").setup {
--     on_attach = my_on_attach,
--     view = {
--         width = 43,
--     },
--
--     diagnostics = {
--         enable = false, -- SET TO TRUE IF I WANT ICONS ON THE LEFT: careful, it lags when I open lots of docs
--         show_on_dirs = true,
--         show_on_open_dirs = true,
--         debounce_delay = 50,
--         severity = {
--             min = vim.diagnostic.severity.HINT,
--             max = vim.diagnostic.severity.ERROR,
--         },
--         icons = {
--             hint = " ",
--             info = " ",
--             warning = " ",
--             error = " ",
--         },
--     },
-- }


-- Make sure vim.lsp is attached to the buffer
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        -- leader+r shortcut to rename an LSP symbol
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename LSP symbol" })
    end,
})
