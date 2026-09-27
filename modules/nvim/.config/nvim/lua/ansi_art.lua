-- Converts an ANSI art file (chafa's output) into static coloured text
-- for a `text` section of the snacks dashboard.
--
-- WHY: a `section = "terminal"` section is destroyed and recreated on every
-- call to dashboard:update(), that is on every WinResized, so every time
-- the explorer opens. Hence the flicker, and the art wrapping when the
-- terminal's floating window is not as wide as on the previous render.
--
-- Static text is part of the dashboard buffer: it is never rerun,
-- never reflowed, and follows the layout without getting distorted.

local M = {}

local hl_cache = {}   ---@type table<string, string>          "fg/bg" key -> group name
local hl_defs = {}    ---@type table<string, vim.api.keyset.highlight>  name -> definition
local hl_count = 0
local hooked = false

---Safety cap. nvim stops at 20000 highlight and syntax groups
---combined (E849), after which NO group at all can be created,
---treesitter's and the LSPs' included. This stops well before, even if it
---makes the end of a drawing monochrome, rather than breaking the editor.
local HL_BUDGET = 12000
local warned = false

---Colours of `Normal`, read when they are APPLIED.
---Required: lazy loads the config BEFORE the colorscheme is
---applied, and nvim's default Normal has a #14161b background. Freezing that value
---at parse time painted the inverted cells #14161b instead of #1e1e2e, a background
---slightly darker than the dashboard's, visible as a shadow.
local function normal_colors()
    local n = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    return n.fg and ("#%06x"):format(n.fg) or "#cdd6f4",
           n.bg and ("#%06x"):format(n.bg) or "#1e1e2e"
end

---Darkens a colour by a percentage.
---@param hex string "#rrggbb"
---@param amount number 0 to 1
---@return string
local function darken(hex, amount)
    local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
    if not r then
        return hex
    end
    local f = 1 - amount
    return ("#%02x%02x%02x"):format(
        math.floor(tonumber(r, 16) * f),
        math.floor(tonumber(g, 16) * f),
        math.floor(tonumber(b, 16) * f))
end

---SHADOWS: `vim.g.ansi_art_shadow`
---
---Reverse video cells with no explicit background paint their glyph
---with the buffer background, so it is invisible. Darkening it slightly gives
---a drop shadow effect on the outlines of the drawing.
---
---  vim.g.ansi_art_shadow = nil or false  -- no shadow (default)
---  vim.g.ansi_art_shadow = true          -- automatic shadow: theme background darkened by 35 %
---  vim.g.ansi_art_shadow = 0.5           -- stronger shadow (0 to 1)
---  vim.g.ansi_art_shadow = "#14161b"     -- fixed colour
---
---To apply it right away: `:lua vim.g.ansi_art_shadow = true` then
---`:lua require("ansi_art").refresh()`.
---@param nbg string current Normal background
---@return string
local function shadow_color(nbg)
    local s = vim.g.ansi_art_shadow
    if not s then
        return nbg
    end
    if type(s) == "string" then
        return s
    end
    return darken(nbg, type(s) == "number" and s or 0.35)
end

---Replaces the markers with the current Normal colours.
---@param def table definition that may contain "NORMAL_FG" / "NORMAL_BG"
---@return vim.api.keyset.highlight
local function resolve(def)
    local nfg, nbg = normal_colors()
    local out = { bold = def.bold }
    -- NORMAL_BG as foreground = glyph of an inverted cell: it is what carries
    -- the shadow, if any. As background it stays the real background.
    out.fg = def.fg == "NORMAL_FG" and nfg or (def.fg == "NORMAL_BG" and shadow_color(nbg) or def.fg)
    out.bg = def.bg == "NORMAL_FG" and nfg or (def.bg == "NORMAL_BG" and nbg or def.bg)
    return out
end

---Applies again every group created so far, with the current theme colours.
---Needed because a `:colorscheme` runs `:highlight clear` and wipes the
---art's groups, which is what made the dashboard monochrome.
local function reapply()
    for name, def in pairs(hl_defs) do
        vim.api.nvim_set_hl(0, name, resolve(def))
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

---Creates (or reuses) a highlight group.
---@param fg string|nil  "#rrggbb"
---@param bg string|nil  "#rrggbb"
---@param bold boolean|nil
---@return string|nil
local function hl_group(fg, bg, bold, reverse)
    if reverse then
        -- Markers rather than colours: they are resolved when applied,
        -- once the colorscheme has loaded (see resolve/reapply).
        fg, bg = bg or "NORMAL_BG", fg or "NORMAL_FG"
    end
    if not fg and not bg and not bold then
        return nil
    end
    local key = (fg or "-") .. "/" .. (bg or "-") .. (bold and "/b" or "")
    if hl_cache[key] then
        return hl_cache[key]
    end
    if hl_count >= HL_BUDGET then
        if not warned then
            warned = true
            vim.notify(
                ("ansi_art : %d groupes de surbrillance atteints, le reste de l'art sera monochrome."):format(HL_BUDGET),
                vim.log.levels.WARN)
        end
        return nil
    end
    ensure_hook()
    hl_count = hl_count + 1
    local name = ("SnacksAnsiArt%d"):format(hl_count)
    local def = { fg = fg, bg = bg, bold = bold or nil }
    hl_defs[name] = def
    vim.api.nvim_set_hl(0, name, resolve(def))
    hl_cache[key] = name
    return name
end

---Colour of one of the 16 basic ANSI codes, taken from the colorscheme palette.
---catppuccin (like most) sets vim.g.terminal_color_0..15, which keeps
---the rendering consistent with the theme rather than forcing fixed reds and greens.
---@param idx integer 0..15
---@return string|nil
local function palette(idx)
    local v = vim.g["terminal_color_" .. idx]
    if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then
        return v
    end
    -- fallback: classic ANSI colours, if the theme does not define its palette
    local fallback = {
        [0] = "#45475a", [1] = "#f38ba8", [2] = "#a6e3a1", [3] = "#f9e2af",
        [4] = "#89b4fa", [5] = "#f5c2e7", [6] = "#94e2d5", [7] = "#bac2de",
        [8] = "#585b70", [9] = "#f38ba8", [10] = "#a6e3a1", [11] = "#f9e2af",
        [12] = "#89b4fa", [13] = "#f5c2e7", [14] = "#94e2d5", [15] = "#a6adc8",
    }
    return fallback[idx]
end

---Rounds an RGB component to a given step.
---
---WHY: each (foreground, background) pair met becomes a
---highlight group. In truecolor, a 40 frame GIF produces nearly
---19000 on its own, and nvim refuses more than 20000, treesitter and the LSPs
---included (E849). Rounding to the nearest multiple of 8 (maximum error of
---4 out of 255, invisible) brings the count down to about 4800.
---@param v integer
---@param step integer
---@return integer
local function snap(v, step)
    return math.min(255, math.floor((v + step / 2) / step) * step)
end

---Applies an SGR sequence to the current state.
---@param params string  the body of the sequence, without "\27[" or "m"
---@param state table    { fg = ..., bg = ..., q = quantization step|nil }
local function apply_sgr(params, state)
    local codes = {}
    for n in params:gmatch("[0-9]+") do
        codes[#codes + 1] = tonumber(n)
    end
    if #codes == 0 then           -- "\27[m" is the same as "\27[0m"
        codes = { 0 }
    end
    local i = 1
    while i <= #codes do
        local c = codes[i]
        if c == 0 then
            state.fg, state.bg, state.bold, state.reverse = nil, nil, nil, nil
        elseif c == 1 then
            state.bold = true
        elseif c == 7 then
            -- Reverse video: swaps foreground and background.
            -- chafa uses it to save bytes (52 times in the logo).
            -- Ignoring it gave 52 cells with inverted colours, which visibly
            -- distorted the image compared to what the terminal shows.
            state.reverse = true
        elseif c == 27 then
            state.reverse = nil
        elseif c == 22 then
            state.bold = nil
        elseif c == 39 then
            state.fg = nil
        elseif c == 49 then
            state.bg = nil
        elseif (c == 38 or c == 48) and codes[i + 1] == 2 then
            local r, g, b = codes[i + 2] or 0, codes[i + 3] or 0, codes[i + 4] or 0
            if state.q then
                r, g, b = snap(r, state.q), snap(g, state.q), snap(b, state.q)
            end
            local col = ("#%02x%02x%02x"):format(r, g, b)
            if c == 38 then state.fg = col else state.bg = col end
            i = i + 4
        elseif (c == 38 or c == 48) and codes[i + 1] == 5 then
            local col = palette(codes[i + 2] or 0)       -- 256 palette: only the first 16
            if c == 38 then state.fg = col else state.bg = col end
            i = i + 2
        -- Basic ANSI colours. git --color=always emits ONLY these
        -- (31 red, 32 green): without this case, the git diff stayed monochrome.
        elseif c >= 30 and c <= 37 then
            state.fg = palette(c - 30)
        elseif c >= 90 and c <= 97 then
            state.fg = palette(c - 90 + 8)
        elseif c >= 40 and c <= 47 then
            state.bg = palette(c - 40)
        elseif c >= 100 and c <= 107 then
            state.bg = palette(c - 100 + 8)
        end
        i = i + 1
    end
end

---Turns an ANSI string into a list of LINES of coloured pieces.
---The split is needed for the animation: each line becomes an extmark laid
---over the buffer (see lua/ansi_anim.lua). `M.parse` is now just a
---flattening of this result.
---@param raw string
---@param opts? { quantize?: integer }  rounds 24-bit colours to this step
---                                     (see `snap`: required for a GIF)
---@return table[][] lines  one list of pieces per line
function M.parse_lines(raw, opts)
    local lines = {}
    local state = { fg = nil, bg = nil, q = opts and opts.quantize }

    for line in (raw:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
        local chunks = {}
        local pos = 1
        while pos <= #line do
            -- Every CSI sequence, not only SGR: those that do not
            -- end with "m" (cursor, screen clearing…) are simply
            -- dropped. Handling them here keeps them out of the displayed text.
            local s, e, params, final = line:find("\27%[([0-9;?]*)(%a)", pos)
            if s then
                if s > pos then
                    chunks[#chunks + 1] = { line:sub(pos, s - 1), hl = hl_group(state.fg, state.bg, state.bold, state.reverse) }
                end
                if final == "m" then
                    apply_sgr(params, state)
                end
                pos = e + 1
            else
                local rest = line:sub(pos)
                if #rest > 0 then
                    chunks[#chunks + 1] = { rest, hl = hl_group(state.fg, state.bg, state.bold, state.reverse) }
                end
                break
            end
        end
        lines[#lines + 1] = chunks
    end
    return lines
end

---Turns a string holding ANSI colours into `snacks.dashboard.Text`.
---Used both for an art file and for the coloured output of a command
---(`git diff --color=always`, for example).
---@param raw string
---@param opts? { quantize?: integer }
---@return table[] chunks
function M.parse(raw, opts)
    local chunks = {}
    for _, line in ipairs(M.parse_lines(raw, opts)) do
        vim.list_extend(chunks, line)
        chunks[#chunks + 1] = { "\n" }
    end

    -- drops the final newline, or the dashboard gains an empty line
    if #chunks > 0 and chunks[#chunks][1] == "\n" then
        table.remove(chunks)
    end
    return chunks
end

---Reads an ANSI art file.
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

---Applies every group again with the current settings.
---To call after changing `vim.g.ansi_art_shadow` to see the effect
---without restarting nvim (the dashboard then has to be reopened).
function M.refresh()
    reapply()
end

---Maximum visible width (useful to centre or size).
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
        cur = cur - 1  -- makes up for the "\0" sentinel
    end
    return math.max(max, cur)
end

return M
