---@diagnostic disable: undefined-global
-- space bar leader key
vim.g.mapleader = " "

-- buffers
-- vim.keymap.set("n", "<leader>n", ":bn<cr>", { silent = true })
-- vim.keymap.set("n", "<leader>b", ":bp<cr>", { silent = true })


-- Si j'ai bufferline d'activer!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- vim.keymap.set("n", ",", ":BufferLineCyclePrev<cr>", { silent = true })
-- vim.keymap.set("n", ";", ":BufferLineCycleNext<cr>", { silent = true })


vim.keymap.set("n", ",", "<Cmd>BufferPrevious<CR>", { silent = true })
vim.keymap.set("n", ";", "<Cmd>BufferNext<CR>", { silent = true })
vim.keymap.set("n", "<A-,>", "<Cmd>BufferMovePrevious<CR>", { silent = true })
vim.keymap.set("n", "<A-;>", "<Cmd>BufferMoveNext<CR>", { silent = true })

-- vim.keymap.set("n", "<C-,>", ":BufferLineCyclePrev<CR>", { silent = true })
-- vim.keymap.set("n", "<C-;>", ":BufferLineCycleNext<CR>", { silent = true })

-- Si je désactive bufferline !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- vim.keymap.set("n", ",", ":bp<cr>", { silent = true })
-- vim.keymap.set("n", ";", ":bn<cr>", { silent = true })


----------Comme pour dwm, <C-j> ou <leader>j ou <Alt-j> permet de changer de fenêtres (ici dans nvim ce sont des splits)
vim.keymap.set("n", "<C-j>", "<C-w><C-w>", { silent = true })
-- vim.keymap.set("n", "<M-j>", "<C-w><C-w>", { silent = true })
-- vim.keymap.set("n", "<leader>j", "<C-w><C-w>", { silent = true })




-- vim.keymap.set("n", "<leader>b", function()
--     local original_win = vim.api.nvim_get_current_win()
--
--     -- Essayer de se déplacer vers n'importe quel autre split
--     local found_other_win = false
--
--     -- Essayer en bas
--     vim.cmd("wincmd j")
--     if vim.api.nvim_get_current_win() ~= original_win then
--         found_other_win = true
--     else
--         -- Essayer à droite
--         vim.cmd("wincmd l")
--         if vim.api.nvim_get_current_win() ~= original_win then
--             found_other_win = true
--         else
--             -- Essayer en haut
--             vim.cmd("wincmd k")
--             if vim.api.nvim_get_current_win() ~= original_win then
--                 found_other_win = true
--             else
--                 -- Essayer à gauche
--                 vim.cmd("wincmd h")
--                 if vim.api.nvim_get_current_win() ~= original_win then
--                     found_other_win = true
--                 end
--             end
--         end
--     end
--
--     if not found_other_win then
--         print("Aucun autre split trouvé")
--         vim.api.nvim_set_current_win(original_win)
--         return
--     end
--
--     local target_win = vim.api.nvim_get_current_win()
--     local target_buf = vim.api.nvim_win_get_buf(target_win)
--
--     -- Récupérer le contenu du split cible
--     local content = vim.api.nvim_buf_get_lines(target_buf, 0, -1, false)
--     local original_filetype = vim.bo.filetype
--     local original_bufname = vim.fn.bufname(target_buf)
--
--     -- Générer le nom de fichier
--     local timestamp = os.date('%H%M%S')
--     local basename = original_bufname ~= '' and 
--     vim.fn.fnamemodify(original_bufname, ':t:r') .. "_" .. timestamp or 
--     "buffer_" .. timestamp
--
--     local extension = original_filetype ~= '' and original_filetype or "txt"
--     local filename = "/tmp/" .. basename .. "." .. extension
--
--     -- Sauvegarder dans /tmp
--     local file = io.open(filename, "w")
--     if file then
--         file:write(table.concat(content, "\n"))
--         file:close()
--     else
--         print("Erreur: Impossible d'écrire dans " .. filename)
--         vim.api.nvim_set_current_win(original_win)
--         return
--     end
--
--     -- Fermer le split cible
--     vim.cmd("close")
--
--     -- Retourner à la fenêtre originale et ouvrir le nouveau fichier
--     vim.api.nvim_set_current_win(original_win)
--     vim.cmd("edit " .. filename)
--     vim.bo.buflisted = true
--     vim.bo.swapfile = false
--
--     if original_filetype ~= '' then
--         vim.bo.filetype = original_filetype
--     end
--
--     -- print('Split converti en buffer: ' .. filename)
-- end, { silent = true })

-- vim.keymap.set("n", "<leader>b", function()
--     local original_win = vim.api.nvim_get_current_win()
--     vim.cmd("wincmd j")
--     local filename = "/tmp/buffer_" .. os.date('%H%M%S') .. ".txt"
--     vim.cmd("w " .. filename .. " | close | e " .. filename)
--     vim.bo.buflisted = true
-- end, { silent = true })




-- vim.keymap.set("n", "<leader>n", ":tabn<cr>", { silent = true })

-- vim.keymap.set("n", "<leader>c", ":Bdelete<cr>", { silent = true })
-- vim.keymap.set("n", "<Leader>C", function()
--     vim.cmd("bufdo bwipeout")
-- end, { silent = true })

vim.keymap.set("n", "<leader>c", function()
    if vim.bo.modified then
        local choice = vim.fn.confirm("Buffer modified, close anyway?", "&Yes\n&No", 1)
        if choice == 1 then
            vim.cmd("Bdelete!")
        end
    else
        vim.cmd("Bdelete")
    end
end, { silent = true })

vim.keymap.set("n", "<Leader>C", function()
    -- nbr de buffers modifiés
    local modified_count = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "modified") then
            modified_count = modified_count + 1
        end
    end

    -- S'il y a des buffers non saved, demander confirmation
    if modified_count > 0 then
        local message = modified_count == 1 
        and "Buffer modified, close anyway?" 
        or "Multiple buffers modified, close anyway?"

        local choice = vim.fn.confirm(message, "&Yes\n&No", 1)
        if choice == 1 then
            vim.cmd("bufdo! bwipeout!")
        end
    else
        vim.cmd("bufdo bwipeout")
    end
end, { silent = true })



vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center the screen on the next/prev search result with n/N
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")


-- windows
vim.keymap.set("n", "<leader><left>", ":vertical resize +10<cr>")
vim.keymap.set("n", "<leader><right>", ":vertical resize -10<cr>")
vim.keymap.set("n", "<leader><up>", ":resize +10<cr>")
vim.keymap.set("n", "<leader><down>", ":resize -10<cr>")


-- Définir un autocmd pour ajuster le raccourci en fonction du type de fichier
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype

    if filetype == "python" then
      -- Si le fichier est de type Python, utiliser black pour formater
      vim.keymap.set("n", "<leader>fm", ":silent !autopep8 --indent-size 2 --in-place %<cr>",
        { noremap = true, silent = true, buffer = true })
    else
      -- Sinon, utiliser la fonction LSP pour formater
      vim.keymap.set("n", "<leader>fm", vim.lsp.buf.format, { noremap = true, silent = true, buffer = true })
    end
  end
})

-- ---------------------------------------------------------------------------------------------------
-- vim.api.nvim_set_keymap('n', 'p', "p`[v`]=<CR>`]", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'P', "P`[v`]=<CR>`]", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('x', 'p', '"_PP`[v`]=<CR>`]', { noremap = true, silent = true })

-- amélioration des précédentes: permettent de bien lié le clipboard au registre de nvim
vim.api.nvim_set_keymap('n', 'p', '"+p`[v`]=<CR>`]', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'P', '"+P`[v`]=<CR>`]', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', 'p', '"_"+P`[v`]=<CR>`]', { noremap = true, silent = true })




-- comment.nvim
-- Keymap pour copier sans descendre d'une ligne
vim.api.nvim_set_keymap('x', 'gyc', 'ygvgc', { silent = true })
vim.api.nvim_set_keymap('x', 'gyb', 'ygvgb', { silent = true })

-- -- Keymap pour copier sans descendre d'une ligne
-- vim.api.nvim_set_keymap('x', 'y', 'ygv<Esc>', { noremap = true, silent = true })





-- -- CODE DEPASSÉ: c'est une save ou cas où
-- vim.api.nvim_set_keymap('v', 'p', '"_dP`[v`]=<CR>`]', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('x', 'p', '0"_dO<Esc>P`[v`]=<CR>`]', { noremap = true, silent = true })






-- vim.api.nvim_set_keymap('x', 'P', '0"_dP`[v`]=<CR>`]', { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('v', 'y', "y`[V$`]=<CR>`[", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('x', 'p', '0"_dP`[v`]=<CR>`]$a<CR><Esc>k$', { noremap = true, silent = true })
-- vim.keymap.set("x", "p", [["_dP]])

-- Remap arrow keys to move all cursors in visual multi mode
-- vim.g.VM_maps = {
--   ["Move Left"]  = "<Left>",
--   ["Move Down"]  = "<Down>",
--   ["Move Up"]    = "<Up>",
--   ["Move Right"] = "<Right>",
-- }

-- Remapper les touches directionnelles
-- vim.api.nvim_set_keymap('n', '<Up>', 'k', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Down>', 'j', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Left>', 'h', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Right>', 'l', { noremap = true, silent = true })

vim.api.nvim_set_keymap(
  'n',
  '<leader>m',
  'iint main(int argc, char *argv[]) {\n\nreturn 0;\n}<Esc>', -- le texte à insérer
  { noremap = true, silent = true }
)


vim.keymap.set('n', '<leader>;', 'A;<Esc>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>,', 'A,<Esc>', { noremap = true, silent = true })

-- Remap for moving lines up and down in normal mode
vim.keymap.set('n', 'K', ':m .-2<CR>==', { noremap = true, silent = true })
vim.keymap.set('n', 'J', ':m .+1<CR>==', { noremap = true, silent = true })

-- Remap for moving lines up and down in visual mode
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })

-- Remap Shift+V pour sélectionner la ligne et déplacer le curseur à la fin
-- vim.api.nvim_set_keymap('n', 'V', 'V$', { noremap = true, silent = true })

vim.keymap.set('n', '<S-Up>', '<Nop>')
vim.keymap.set('n', '<S-Down>', '<Nop>')
vim.keymap.set('n', '<S-Left>', '<Nop>')
vim.keymap.set('n', '<S-Right>', '<Nop>')

vim.keymap.set('v', '<S-Up>', '<Nop>')
vim.keymap.set('v', '<S-Down>', '<Nop>')
vim.keymap.set('v', '<S-Left>', '<Nop>')
vim.keymap.set('v', '<S-Right>', '<Nop>')

vim.keymap.set('i', '<S-Up>', '<Nop>')
vim.keymap.set('i', '<S-Down>', '<Nop>')
vim.keymap.set('i', '<S-Left>', '<Nop>')
vim.keymap.set('i', '<S-Right>', '<Nop>')


-- vim.keymap.set('n', 's', '<Nop>', { noremap = true, silent = true })
-- vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- function _G.set_terminal_keymaps()
--     local opts = {buffer = 0}
--     vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
--     vim.keymap.set('n', '<esc>', ":ToggleTerm<CR>", opts)
--     vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
--     vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
--     vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
--     vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
--     vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
--     vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
-- end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
-- vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

vim.keymap.set('n', '<C-ù>',":ToggleTerm<CR>", { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('t', '<C-ù>', '<Esc><Esc>', { noremap = true, silent = true })
-- vim.keymap.set("n", "<C-w>", "<Nop>", { remap = true, silent = true })
-- vim.keymap.set("i", "<C-w>", "<Nop>", { remap = true, silent = true })


-- vim.keymap.set("n", "n", ";", { noremap = true })
-- vim.keymap.set("n", "N", ",", { noremap = true })



-- Toggle wrap avec <leader>w
vim.keymap.set('n', '<leader>w', function()
    vim.wo.wrap = not vim.wo.wrap
    local status = vim.wo.wrap and "wrap enabled" or "wrap disabled"
    vim.notify(status, vim.log.levels.INFO, { title = "Wrap", timeout = 3000 })
end, { desc = "Toggle wrap with visible feedback" })


-- Toggle colorcolumn à 80 avec <leader>x
vim.keymap.set('n', '<leader>x', function()
    if vim.wo.colorcolumn == "" then
        vim.wo.colorcolumn = "80"
    else
        vim.wo.colorcolumn = ""
    end
end, { desc = "Toggle colorcolumn at 80" })



-- Sauvegarde du répertoire courant au démarrage
vim.g.startup_dir = vim.fn.getcwd()

vim.keymap.set("n", "<leader>z", function()
    vim.ui.input({ 
        prompt = "Path for :Z ", 
        default = "", 
        completion = "file"  -- enables path auto-completion
    }, function(input)
        if input and input ~= "" then
            vim.cmd("Z " .. input)
        end
    end)
end, { desc = "Run :Z with user input path" })


vim.keymap.set('n', '<leader><BS>', function()
    vim.cmd('cd ' .. vim.g.startup_dir)
    vim.notify('Returned to: ' .. vim.g.startup_dir, vim.log.levels.INFO, { title = 'Initial Directory' })
end, { desc = 'Return to the Neovim startup directory' })


-- Empêcher la sélection automatique du premier item
vim.o.completeopt = "menuone,noinsert,noselect"

vim.api.nvim_set_keymap('i', '<Tab>', 'pumvisible() ? "\\<C-n>" : "\\<Tab>"', {expr = true, noremap = true})
vim.api.nvim_set_keymap('i', '<C-n>', 'pumvisible() ? "\\<C-n>" : "\\<C-n>"', {expr = true, noremap = true})
vim.api.nvim_set_keymap('i', '<C-p>', 'pumvisible() ? "\\<C-p>" : "\\<C-p>"', {expr = true, noremap = true})

-- System to keep history of closed buffers
local closed_buffers = {}

vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
        local buf = args.buf
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" then
            table.insert(closed_buffers, 1, name)
            -- Keep only the last 10
            if #closed_buffers > 10 then
                table.remove(closed_buffers)
            end
        end
    end,
})

vim.keymap.set('n', '<leader>t', function()
    if #closed_buffers > 0 then
        local file = table.remove(closed_buffers, 1)
        vim.cmd('edit ' .. vim.fn.fnameescape(file))
    else
        print("No closed buffer to restore")
    end
end, { desc = "Reopen last closed buffer" })
