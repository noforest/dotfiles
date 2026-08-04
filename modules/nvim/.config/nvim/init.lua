require("keymaps")
require("options")
require("plugins.lazy")
require("plugins.keymaps")
require("plugins.options")

vim.api.nvim_set_hl(0, "MyInfoMsg", {
    fg = "#94e2d5",       -- Couleur du texte en rouge
    bg = "#1e1e2e",       -- Couleur de fond en noir
    bold = true,          -- Texte en gras
    italic = false,       -- Pas d'italique
    underline = false,    -- Pas de soulignement
    undercurl = false,    -- Pas de soulignement ondulé
    -- Autres options disponibles :
    -- reverse = false,   -- Pas d'inversion
    -- standout = false,  -- Pas de mise en évidence
    -- strikethrough = false -- Pas de barré
})

vim.api.nvim_set_hl(0, "MyOrange", {
    fg = "#fab387",       -- Couleur du texte en rouge
    bg = "#1e1e2e",       -- Couleur de fond en noir
    bold = true,          -- Texte en gras
    italic = false,       -- Pas d'italique
    underline = false,    -- Pas de soulignement
    undercurl = false,    -- Pas de soulignement ondulé
    -- Autres options disponibles :
    -- reverse = false,   -- Pas d'inversion
    -- standout = false,  -- Pas de mise en évidence
    -- strikethrough = false -- Pas de barré
})

vim.api.nvim_set_hl(0, "MyPurple", {
    fg = "#b270ff",
    bg = "#1e1e2e",
    bold = true,
    italic = false,
    underline = false,
    undercurl = false,
    -- Autres options disponibles :
    -- reverse = false,   -- Pas d'inversion
    -- standout = false,  -- Pas de mise en évidence
    -- strikethrough = false -- Pas de barré
})

-- Charger le module
require("clangd_auto").setup()
