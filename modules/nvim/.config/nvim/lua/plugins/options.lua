
-- ================== catpuccin only =============================

-- -- GIVE the colorscheme background THE same colour as my terminal!!!!!!!!!!!!!!!
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


-- wraps the diagnostics
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf", -- for the quickfix and loclist
  callback = function()
    vim.wo.wrap = true
  end,
})



-- vim.keymap.set('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)

-- -- Function disabling the Markdown render plugin
-- local function disable_markdown_render()
--   vim.cmd('RenderMarkdown disable')
-- end
--
-- -- Function enabling the Markdown render plugin again
-- local function enable_markdown_render()
--   vim.cmd('RenderMarkdown enable')
-- end
--
--
-- -- Shortcut key for the LSP hover
-- vim.keymap.set('n', '<leader>gh', function()
--   disable_markdown_render() -- Disable the Markdown render plugin
--   vim.lsp.buf.hover() -- Call the LSP hover function
--
--   -- Set an autocommand enabling the Markdown render plugin again when the cursor moves
--   local group = vim.api.nvim_create_augroup('MarkdownRenderGroup', { clear = true })
--   vim.api.nvim_create_autocmd('CursorMoved', {
--     group = group,
--     callback = function()
--       enable_markdown_render() -- Enable the Markdown render plugin again
--       vim.api.nvim_del_augroup_by_name('MarkdownRenderGroup') -- Delete the autocommand after use
--     end,
--   })
-- end)


vim.cmd("doautocmd BufReadPost")

-- Error handler ignoring one specific error
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
    if err and err.message and err.message:match("height' key must be a positive Integer") then
        return -- Ignore the error
    end
    -- Call the default handler if the error is not the one to ignore
    vim.lsp.handlers.signature_help(err, result, ctx, config)
end



-- Records the current directory in zoxide on every change
vim.api.nvim_create_autocmd({'DirChanged'}, {
    pattern = '*',
    callback = function()
        vim.fn.jobstart({'zoxide', 'add', vim.fn.getcwd()})
    end
})



-- vim.api.nvim_create_autocmd("BufReadPost", {
--     pattern = "*.java",
--     callback = function()
--         -- wait for jdtls to be attached
--         vim.defer_fn(function()
--             local bufnr = vim.api.nvim_get_current_buf()
--             for _, client in pairs(vim.lsp.get_clients({bufnr = bufnr})) do
--                 if client.name == "jdtls" then
--                     vim.cmd("LspStop jdtls")
--                     print("jdtls stopped for this Java file")
--                     break
--                 end
--             end
--         end, 10000)  -- delay in ms, adjustable
--     end,
-- })



-- Autocmd fired every time an LSP client attaches to a buffer
-- vim.api.nvim_create_autocmd("LspAttach", {
--     callback = function(args)
--         local client = vim.lsp.get_client_by_id(args.data.client_id)
--         local bufnr = args.buf
--         -- if it is jdtls and a Java file
--         if client.name == "jdtls" and vim.bo[bufnr].filetype == "java" then
--             vim.cmd("LspStop jdtls")
--             print("jdtls stopped automatically for this Java buffer")
--         end
--     end,
-- })
--
--
-- -- Override vim.notify to ignore the jdtls warning
-- local original_notify = vim.notify
-- vim.notify = function(msg, level, opts)
--     if type(msg) == "string" and msg:match("Client jdtls quit") then
--         return -- ignores this message
--     end
--     original_notify(msg, level, opts)
-- end


-- vim.api.nvim_create_autocmd("LspAttach", {
--     callback = function(args)
--         local client = vim.lsp.get_client_by_id(args.data.client_id)
--         local bufnr = args.buf
--
--         if client.name == "jdtls" and vim.bo[bufnr].filetype == "java" then
--             -- Disables completion
--             client.server_capabilities.completionProvider = nil
--             -- Disables signature help
--             client.server_capabilities.signatureHelpProvider = nil
--             -- Disables hover
--             client.server_capabilities.hoverProvider = nil
--             -- Disables document formatting if you want
--             client.server_capabilities.documentFormattingProvider = false
--
--             -- print("jdtls completions/snippets/signature/hover disabled for this buffer")
--         end
--     end,
-- })


-- Disabled along with the github/copilot.vim plugin (see lazy.lua).
-- Without the plugin, copilot#Accept() does not exist: this shortcut would raise an
-- error on every <C-J> in insert mode.
-- vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
--     expr = true,
--     replace_keycodes = false
-- })
-- vim.g.copilot_no_tab_map = true
