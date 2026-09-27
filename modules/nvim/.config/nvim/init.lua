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
