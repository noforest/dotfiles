-- The config and its plugins are written against nvim 0.12: nvim-treesitter for
-- one calls vim.list.unique, and installs no parser without it. An older nvim
-- would fail in many places, some of them silently: say it once and stop.
if vim.fn.has("nvim-0.12") == 0 then
    vim.api.nvim_echo({ { "This config needs nvim 0.12 or newer, this is "
        .. tostring(vim.version()) .. ". Nothing was loaded.", "ErrorMsg" } }, true, {})
    return
end

require("keymaps")
require("options")

-- NOTE: before lazy starts
vim.g.ansi_art_shadow = true        -- theme background darkened by 35 %
vim.g.ansi_art_shadow = 1         -- stronger (0 to 1)
vim.g.ansi_art_shadow = "#14161b"   -- fixed colour
require("plugins.lazy")
require("plugins.keymaps")
require("plugins.options")

vim.api.nvim_set_hl(0, "MyInfoMsg", {
    fg = "#94e2d5",       -- Text colour in red
    bg = "#1e1e2e",       -- Background colour in black
    bold = true,          -- Bold text
    italic = false,       -- No italics
    underline = false,    -- No underline
    undercurl = false,    -- No wavy underline
    -- Other available options:
    -- reverse = false,   -- No reverse
    -- standout = false,  -- No standout
    -- strikethrough = false -- No strikethrough
})

vim.api.nvim_set_hl(0, "MyOrange", {
    fg = "#fab387",       -- Text colour in red
    bg = "#1e1e2e",       -- Background colour in black
    bold = true,          -- Bold text
    italic = false,       -- No italics
    underline = false,    -- No underline
    undercurl = false,    -- No wavy underline
    -- Other available options:
    -- reverse = false,   -- No reverse
    -- standout = false,  -- No standout
    -- strikethrough = false -- No strikethrough
})

vim.api.nvim_set_hl(0, "MyPurple", {
    fg = "#b270ff",
    bg = "#1e1e2e",
    bold = true,
    italic = false,
    underline = false,
    undercurl = false,
    -- Other available options:
    -- reverse = false,   -- No reverse
    -- standout = false,  -- No standout
    -- strikethrough = false -- No strikethrough
})

-- Load the module
require("clangd_auto").setup()
