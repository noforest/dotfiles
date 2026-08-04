-- telescope
-- vim.keymap.set("n", "<leader>ff", ":Telescope find_files<cr>", { silent = true }) !!!!!!!!!!!!!!!!!!!!!!!!!!! est remplacé par snacks car smart
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<cr>", { silent = true })
vim.keymap.set("n", "<leader>fw", ":Telescope grep_string<cr>", { silent = true }) --find word
-- vim.keymap.set("n", "<leader>fa", ":Telescope lsp_dynamic_workspace_symbols<cr>", { silent = true }) -- g pour tous les trucs en rapport avec lsp, et a pour all (symbols)

-- ATTENTION <leader>fd et <leader>fr SONT BIEN DEFINIE dans lazy.lua
-- vim.keymap.set("n", "<leader>fc", ":Telescope git_bcommits<cr>", { silent = true })  !!!!!!!!!// remplacer par <leader>fc dans snacks
vim.keymap.set("n", "<leader><Tab>", ":Telescope buffers<cr>", { silent = true })



-- tree
-- vim.keymap.set("n", "<leader>e", ":NvimTreeFindFileToggle<cr>", { silent = true })
-- --> c'est mini.files qui prend le relais: cd lazy.lua
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
-- !!!!!!!!! DANS LAZY.LUA     { "<leader>ds", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" } !!!!!!!!!!!!


-- lazygit plugin (Plugin for calling lazygit from within neovim)
-- vim.keymap.set('n', '<leader>lg', "<cmd>LazyGit<cr>", { silent = true })




-- --diffViews keymaps
-- vim.keymap.set('n', '<leader>do', ":DiffviewFileHistory %<CR>", { silent = true })
-- vim.keymap.set('n', '<leader>dc', ":DiffviewClose<CR>", { silent = true })
vim.keymap.set("n", "<leader>do", ":CodeDiff history %<CR>", { desc = "CodeDiff history of one file" })
-- vim.keymap.set("v", "<leader>dh", ":'<,'>DiffviewFileHistory<cr>", {desc = "Selection history" })

-- NOTE: regarde les anciennes versions des lignes sélectionnées
vim.keymap.set("v", "<leader>hh", ":'<,'>CodeDiff linehist<cr>", { silent = true }) 





-- Gitsigns : ajouter des mappages avec `on_attach`
local gitsigns = require('gitsigns')

gitsigns.setup({
  current_line_blame = false,
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    -- Fonction de mappage local
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Raccourcis de navigation
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
--   -- Désactive le cursorline pour le panneau nvim-tree
--   -- vim.wo.cursorline = false
--   vim.wo.cursorline = true
--
--   -- Ouvre le fichier et retourne au panneau nvim-tree
--   api.node.open.edit()
--   vim.cmd("wincmd p")
--
--   -- Désactive cursorline à nouveau pour garder le curseur invisible
--   -- vim.wo.cursorline = false
--
--   -- Garder la surbrillance sous le curseur sans afficher le curseur
--   vim.opt.guicursor = "n:blinkon0,i:ver25" -- Désactive le curseur visuellement
-- end
--
--
--
-- local function open_folder_and_highlight_cursor(api)
--   -- Active la surbrillance sous le curseur (cursorline) pour le panneau nvim-tree
--   vim.wo.cursorline = true
--
--   -- Ouvre le dossier sans perdre l'arborescence
--   api.node.open.tab()
--
--   -- Désactive le curseur visuellement sans affecter la ligne de surbrillance
--   vim.opt.guicursor = "n:blinkon0,i:ver25"  -- Cela désactive le curseur sans désactiver le "cursorline"
-- end
--
-- local function my_on_attach(bufnr)
--   local api = require("nvim-tree.api")
--
--   local function opts(desc)
--     return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
--   end
--
--   -- Mappings par défaut
--   api.config.mappings.default_on_attach(bufnr)
--
--   -- Mapping personnalisé pour <Tab>
--   -- vim.keymap.set('n', '<Tab>', function() open_file_and_hide_cursor(api) end, opts("Open File and Stay"))
--
--   -- Mapping personnalisé pour <Tab> : ouvrir fichier ou dossier
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
-- -- Configuration de nvim-tree avec on_attach
-- require("nvim-tree").setup {
--   on_attach = my_on_attach,
--   -- autres options...
-- }

-------------------------------------------------------------------------------------------------------------
-- Toujours pour nvim tree
-- local function open_file_and_hide_cursor(api)
--   vim.wo.cursorline = true
--   api.node.open.no_window_picker()
--   vim.cmd("wincmd p")
--   vim.opt.guicursor = "n:blinkon0,i:ver25" -- Désactive le curseur visuellement
-- end
--
--
-- local function open_folder_and_highlight_cursor(api)
--   vim.wo.cursorline = true
--   api.node.open.tab()
--   vim.opt.guicursor = "n:blinkon0,i:ver25"  -- Cela désactive le curseur sans désactiver le "cursorline"
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
--         enable = false, -- A METTRE TRUE SI JE VEUX LOGOS A GAUCHE: attention ça lague quand j'ouvre pleins de docs
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


-- Assure-toi que vim.lsp est attaché au buffer
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        -- Raccourci leader+r pour renommer un symbole LSP
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename LSP symbol" })
    end,
})
