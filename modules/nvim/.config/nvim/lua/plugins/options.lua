
-- ================== catpuccin only =============================

-- -- METTRE LE FOND du colorscheme DE la meme couleur que mon terminal!!!!!!!!!!!!!!!
require("catppuccin").setup({

    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        blink_cmp = true,
    },

    -- custom_highlights = function(colors)
    --     return {
    --         -- =========================
    --         -- Code (mantle)
    --         -- =========================
    --         Normal = { bg = colors.mantle },
    --         NormalNC = { bg = colors.mantle },
    --
    --         -- =========================
    --         -- Neo-tree (crust)
    --         -- =========================
    --         NeoTreeNormal = { bg = colors.crust },
    --         NeoTreeNormalNC = { bg = colors.crust },
    --         NeoTreeEndOfBuffer = { bg = colors.crust },
    --         NeoTreeTitleBar = { bg = colors.crust },
    --         NeoTreeWinSeparator = {
    --             fg = colors.crust,
    --             bg = colors.crust,
    --         },
    --
    --         -- =========================
    --         -- Snacks.nvim picker (crust)
    --         -- =========================
    --         -- SnacksPicker = { bg = colors.crust },
    --         -- -- SnacksPickerBorder = { bg = colors.crust, fg = colors.crust },
    --         -- -- SnacksPickerTitle = { bg = colors.crust },
    --         -- -- SnacksPickerPrompt = { bg = colors.crust },
    --         -- -- SnacksPickerList = { bg = colors.crust },
    --
    --         -- =========================
    --         -- Telescope (crust)
    --         -- =========================
    --         -- TelescopeNormal = { bg = colors.crust },
    --         -- -- TelescopeBorder = { bg = colors.crust, fg = colors.crust },
    --         -- -- TelescopePromptNormal = { bg = colors.crust },
    --         -- -- TelescopePromptBorder = { bg = colors.crust, fg = colors.crust },
    --         -- -- TelescopeResultsNormal = { bg = colors.crust },
    --         -- -- TelescopePreviewNormal = { bg = colors.crust },
    --     }
    -- end,
})


-- setup must be called before loading
vim.cmd.colorscheme "catppuccin"

vim.cmd("colorscheme catppuccin-mocha") -- set color theme
-- vim.cmd("colorscheme no-clown-fiesta") -- set color theme

-- vim.cmd("highlight SignColumn guibg=NONE")
-- vim.o.background = "dark" -- or "light" for light mode

-- Load and setup function to choose plugin and language highlights
vim.g.startify_custom_header = "" -- startify remove random quote

vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "#181825" })



-- ===============================================================


-- -- ==================== one dark =================================
-- vim.cmd.colorscheme("everblush")
-- local bg = "#1b1b1b"
--
-- vim.api.nvim_set_hl(0, "Normal",      { bg = bg })
-- vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg })
-- vim.api.nvim_set_hl(0, "SignColumn",  { bg = bg })
--
-- vim.api.nvim_set_hl(0, "NeoTreeNormal",        { bg = bg })
-- vim.api.nvim_set_hl(0, "NeoTreeNormalNC",      { bg = bg })
-- vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer",   { bg = bg })
-- vim.api.nvim_set_hl(0, "NeoTreeSignColumn",    { bg = bg })
-- vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = bg, fg = bg })
--
-- -- ===============================================================


vim.opt.termguicolors = true      --bufferline
-- require("bufferline").setup {
--
--   -- highlights = require("catppuccin.groups.integrations.bufferline").get(),
--   highlights = {
--     buffer_selected = {
--       bold = true,
--       italic = false,
--     },
--   },
--
--   options = {
--
--     always_show_bufferline = true,
--     auto_toggle_bufferline = true,
--     indicator = {
--       icon = '▎', -- this should be omitted if indicator style is not 'icon'
--       style = 'icon'
--     },
--
--     sort_by = 'directory',
--   },
-- }


-- permet de renvoyer à la ligne les diagnostics
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf", -- pour la quickfix et loclist
  callback = function()
    vim.wo.wrap = true
  end,
})



-- vim.keymap.set('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)

-- -- Fonction pour désactiver le plugin de rendu Markdown
-- local function disable_markdown_render()
--   vim.cmd('RenderMarkdown disable')
-- end
--
-- -- Fonction pour réactiver le plugin de rendu Markdown
-- local function enable_markdown_render()
--   vim.cmd('RenderMarkdown enable')
-- end
--
--
-- -- Configuration de la touche de raccourci pour le hover LSP
-- vim.keymap.set('n', '<leader>gh', function()
--   disable_markdown_render() -- Désactiver le plugin de rendu Markdown
--   vim.lsp.buf.hover() -- Appeler la fonction de hover LSP
--
--   -- Définir une autocommande pour réactiver le plugin de rendu Markdown lors d'un mouvement de curseur
--   local group = vim.api.nvim_create_augroup('MarkdownRenderGroup', { clear = true })
--   vim.api.nvim_create_autocmd('CursorMoved', {
--     group = group,
--     callback = function()
--       enable_markdown_render() -- Réactiver le plugin de rendu Markdown
--       vim.api.nvim_del_augroup_by_name('MarkdownRenderGroup') -- Supprimer l'autocommande après utilisation
--     end,
--   })
-- end)


vim.cmd("doautocmd BufReadPost")

-- Gestionnaire d'erreurs pour ignorer l'erreur spécifique
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
    if err and err.message and err.message:match("height' key must be a positive Integer") then
        return -- Ignorer l'erreur
    end
    -- Appeler le gestionnaire par défaut si l'erreur n'est pas celle que nous voulons ignorer
    vim.lsp.handlers.signature_help(err, result, ctx, config)
end



-- Enregistre le répertoire courant dans zoxide à chaque changement
vim.api.nvim_create_autocmd({'DirChanged'}, {
    pattern = '*',
    callback = function()
        vim.fn.jobstart({'zoxide', 'add', vim.fn.getcwd()})
    end
})



-- vim.api.nvim_create_autocmd("BufReadPost", {
--     pattern = "*.java",
--     callback = function()
--         -- attendre que jdtls soit attaché
--         vim.defer_fn(function()
--             local bufnr = vim.api.nvim_get_current_buf()
--             for _, client in pairs(vim.lsp.get_clients({bufnr = bufnr})) do
--                 if client.name == "jdtls" then
--                     vim.cmd("LspStop jdtls")
--                     print("jdtls stopped for this Java file")
--                     break
--                 end
--             end
--         end, 10000)  -- délai en ms, ajustable
--     end,
-- })



-- Autocmd déclenché à chaque fois qu'un client LSP s'attache à un buffer
-- vim.api.nvim_create_autocmd("LspAttach", {
--     callback = function(args)
--         local client = vim.lsp.get_client_by_id(args.data.client_id)
--         local bufnr = args.buf
--         -- si c'est jdtls et un fichier Java
--         if client.name == "jdtls" and vim.bo[bufnr].filetype == "java" then
--             vim.cmd("LspStop jdtls")
--             print("jdtls stopped automatically for this Java buffer")
--         end
--     end,
-- })
--
--
-- -- Override vim.notify pour ignorer le warning de jdtls
-- local original_notify = vim.notify
-- vim.notify = function(msg, level, opts)
--     if type(msg) == "string" and msg:match("Client jdtls quit") then
--         return -- ignore ce message
--     end
--     original_notify(msg, level, opts)
-- end


-- vim.api.nvim_create_autocmd("LspAttach", {
--     callback = function(args)
--         local client = vim.lsp.get_client_by_id(args.data.client_id)
--         local bufnr = args.buf
--
--         if client.name == "jdtls" and vim.bo[bufnr].filetype == "java" then
--             -- Désactive la complétion
--             client.server_capabilities.completionProvider = nil
--             -- Désactive la signature help
--             client.server_capabilities.signatureHelpProvider = nil
--             -- Désactive le hover
--             client.server_capabilities.hoverProvider = nil
--             -- Désactive le document formatting si tu veux
--             client.server_capabilities.documentFormattingProvider = false
--
--             -- print("jdtls completions/snippets/signature/hover disabled for this buffer")
--         end
--     end,
-- })


-- Désactivé en même temps que le plugin github/copilot.vim (voir lazy.lua).
-- Sans le plugin, copilot#Accept() n'existe pas : ce raccourci produirait une
-- erreur à chaque <C-J> en mode insertion.
-- vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
--     expr = true,
--     replace_keycodes = false
-- })
-- vim.g.copilot_no_tab_map = true
