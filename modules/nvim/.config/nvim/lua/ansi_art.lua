-- Convertit un fichier d'art ANSI (sortie de chafa) en texte coloré statique
-- pour une section `text` du dashboard de snacks.
--
-- POURQUOI : une section `section = "terminal"` est détruite et recréée à chaque
-- appel de dashboard:update(), c'est-à-dire à chaque WinResized — donc à chaque
-- ouverture de l'explorer. D'où le clignotement, et l'art qui se replie quand la
-- fenêtre flottante du terminal n'a pas la même largeur qu'au rendu précédent.
--
-- Un texte statique fait partie du buffer du dashboard : il n'est jamais relancé,
-- jamais reflowé, et suit la mise en page sans se déformer.

local M = {}

local hl_cache = {}   ---@type table<string, string>          clé "fg/bg" -> nom du groupe
local hl_defs = {}    ---@type table<string, vim.api.keyset.highlight>  nom -> définition
local hl_count = 0
local hooked = false

---Réapplique tous les groupes créés jusqu'ici.
---Nécessaire parce qu'un `:colorscheme` fait `:highlight clear` et efface donc
---les groupes de l'art — c'est ce qui rendait le dashboard monochrome, la
---config étant chargée AVANT que le colorscheme ne soit appliqué.
local function reapply()
    for name, def in pairs(hl_defs) do
        vim.api.nvim_set_hl(0, name, def)
    end
end

local function ensure_hook()
    if hooked then
        return
    end
    hooked = true
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("AnsiArtHighlights", { clear = true }),
        callback = reapply,
        desc = "Réapplique les couleurs de l'art ANSI après un changement de thème",
    })
end

---Crée (ou réutilise) un groupe de surbrillance pour un couple avant-plan / arrière-plan.
---@param fg string|nil  "#rrggbb"
---@param bg string|nil  "#rrggbb"
---@return string|nil
local function hl_group(fg, bg)
    if not fg and not bg then
        return nil
    end
    local key = (fg or "-") .. "/" .. (bg or "-")
    if hl_cache[key] then
        return hl_cache[key]
    end
    ensure_hook()
    hl_count = hl_count + 1
    local name = ("SnacksAnsiArt%d"):format(hl_count)
    local def = { fg = fg, bg = bg }
    hl_defs[name] = def
    vim.api.nvim_set_hl(0, name, def)
    hl_cache[key] = name
    return name
end

---Applique une séquence SGR à l'état courant.
---@param params string  le corps de la séquence, sans "\27[" ni "m"
---@param state table    { fg = ..., bg = ... }
local function apply_sgr(params, state)
    local codes = {}
    for n in params:gmatch("[0-9]+") do
        codes[#codes + 1] = tonumber(n)
    end
    if #codes == 0 then           -- "\27[m" équivaut à "\27[0m"
        codes = { 0 }
    end
    local i = 1
    while i <= #codes do
        local c = codes[i]
        if c == 0 then
            state.fg, state.bg = nil, nil
        elseif c == 39 then
            state.fg = nil
        elseif c == 49 then
            state.bg = nil
        elseif (c == 38 or c == 48) and codes[i + 1] == 2 then
            local col = ("#%02x%02x%02x"):format(codes[i + 2] or 0, codes[i + 3] or 0, codes[i + 4] or 0)
            if c == 38 then state.fg = col else state.bg = col end
            i = i + 4
        elseif (c == 38 or c == 48) and codes[i + 1] == 5 then
            i = i + 2             -- palette 256 : ignorée, chafa émet du 24 bits ici
        end
        i = i + 1
    end
end

---Traduit une chaîne contenant des couleurs ANSI en `snacks.dashboard.Text`.
---Sert autant pour un fichier d'art que pour la sortie colorée d'une commande
---(`git diff --color=always`, par exemple).
---@param raw string
---@return table[] chunks
function M.parse(raw)
    local chunks = {}
    local state = { fg = nil, bg = nil }

    for line in (raw:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
        local pos = 1
        while pos <= #line do
            -- Toutes les séquences CSI, pas seulement les SGR : celles qui ne se
            -- terminent pas par « m » (curseur, effacement d'écran…) sont simplement
            -- jetées. Les traiter ici évite qu'elles finissent dans le texte affiché.
            local s, e, params, final = line:find("\27%[([0-9;?]*)(%a)", pos)
            if s then
                if s > pos then
                    chunks[#chunks + 1] = { line:sub(pos, s - 1), hl = hl_group(state.fg, state.bg) }
                end
                if final == "m" then
                    apply_sgr(params, state)
                end
                pos = e + 1
            else
                local rest = line:sub(pos)
                if #rest > 0 then
                    chunks[#chunks + 1] = { rest, hl = hl_group(state.fg, state.bg) }
                end
                break
            end
        end
        chunks[#chunks + 1] = { "\n" }
    end

    -- retire le saut de ligne final, sinon le dashboard gagne une ligne vide
    if #chunks > 0 and chunks[#chunks][1] == "\n" then
        table.remove(chunks)
    end
    return chunks
end

---Lit un fichier d'art ANSI.
---@param path string
---@return table[]|nil chunks, string|nil err
function M.read(path)
    local fd = io.open(path, "r")
    if not fd then
        return nil, "fichier introuvable : " .. path
    end
    local raw = fd:read("*a")
    fd:close()
    return M.parse(raw)
end

---Largeur visible maximale (utile pour centrer ou dimensionner).
---@param chunks table[]
---@return integer
function M.width(chunks)
    local max, cur = 0, 0
    for _, c in ipairs(chunks) do
        for part, nl in (c[1] .. "\0"):gmatch("([^\n]*)(\n?)") do
            cur = cur + vim.fn.strdisplaywidth(part)
            if nl == "\n" then
                max = math.max(max, cur); cur = 0
            end
        end
        cur = cur - 1  -- compense le "\0" sentinelle
    end
    return math.max(max, cur)
end

return M
