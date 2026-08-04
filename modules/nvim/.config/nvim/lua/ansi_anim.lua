-- Anime un GIF sur le dashboard de snacks, avec les mêmes contraintes que l'art
-- fixe de lua/ansi_art.lua : rien ne doit être détruit ni recréé quand le
-- dashboard se met à jour.
--
-- POURQUOI PAS UNE SECTION `terminal` : elle est détruite et recréée à chaque
-- dashboard:update(), donc à chaque WinResized — donc à chaque <leader>e. Elle
-- vit dans une fenêtre flottante posée par-dessus le dashboard : clignotement
-- garanti, et un chafa relancé en boucle pour rien.
--
-- COMMENT : la première image du GIF est posée en texte statique, exactement
-- comme le PNG l'était. C'est elle qui réserve la place dans le buffer et fixe
-- la mise en page. Les images suivantes sont ensuite PEINTES PAR-DESSUS avec des
-- extmarks `virt_text` : le texte du buffer ne change jamais, il n'y a ni reflow
-- ni recalcul de layout, et si l'animation s'arrête on retombe sur l'image fixe.
--
-- `virt_text_win_col` plutôt que `virt_text_pos = "overlay"` : l'art vit dans le
-- pane 2, et snacks construit chaque ligne en concaténant le pane 1 puis un
-- écart. La colonne d'OCTETS où commence l'art varie donc d'une ligne à l'autre
-- (les icônes du pane 1 sont multi-octets), alors que la colonne d'ÉCRAN, elle,
-- est constante — c'est tout l'intérêt des panes. On se cale donc sur l'écran.
-- Sans danger ici : le dashboard force `wrap = false`.
--
-- PROPORTIONS — `--font-ratio` n'est pas facultatif ici. Quand sa sortie part
-- dans un fichier, chafa ne peut plus interroger le terminal et retombe sur des
-- cellules deux fois plus hautes que larges. Roboto Mono 12.5 dans Alacritty
-- donne 10 × 24 px : sans le dire à chafa, le dessin sort étiré de 20 % en
-- hauteur. Mesurer une cellule = repérer le pas horizontal entre deux glyphes
-- et le pas vertical entre deux lignes, sur une capture d'écran.
--
-- Pour régénérer les images (la sortie brute de chafa est conservée telle
-- quelle, le découpage en images se fait ici) :
--   chafa --size 50 --font-ratio 10/24 samurai_float.gif > samurai_float_frames.txt

local ansi_art = require("ansi_art")

local M = {}

local ns = vim.api.nvim_create_namespace("ansi_art_anim")
local augroup = vim.api.nvim_create_augroup("AnsiArtAnim", { clear = true })
local uv = vim.uv or vim.loop
local cache = {} ---@type table<string, table>  chemin -> animation déjà chargée

local Anim = {}
Anim.__index = Anim

---Découpe la sortie brute de chafa en images.
---
---chafa écrit, pour un GIF : `ESC[?25l`, autant de `ESC D` que de lignes (pour
---réserver la place), `ESC[<n>A` pour remonter, `ESC[s` pour mémoriser la
---position, puis les images séparées par `ESC[u` (retour à la position
---mémorisée), et enfin `ESC[?25h`.
---
---Les séquences CSI sont ignorées par le parseur d'ansi_art, mais `ESC D` n'en
---est pas une (pas de `[`) : il faut la retirer à la main, sinon elle finirait
---dans le texte affiché.
---
---Tout se fait à coups de découpes plutôt que de motifs : le fichier pèse 1 Mo,
---et un `gsub` de plus ou de moins s'y compte en dizaines de millisecondes
---payées au démarrage de nvim. D'où le nettoyage ciblé sur la première et la
---dernière image, seules concernées.
---@param raw string
---@return string[]
local function split_frames(raw)
    local parts = vim.split(raw, "\27[u", { plain = true })
    if #parts == 0 then
        return {}
    end
    parts[1] = parts[1]:gsub("\27D", "")                -- préambule
    parts[#parts] = parts[#parts]:gsub("\27%[%?25h", "") -- curseur rétabli

    local frames = {}
    for _, part in ipairs(parts) do
        while part:sub(-1) == "\n" do
            part = part:sub(1, -2)
        end
        if part ~= "" then
            frames[#frames + 1] = part
        end
    end
    return frames
end

---Charge un fichier d'animation ANSI (sortie de chafa sur un GIF).
---Le résultat est mémorisé : rouvrir le dashboard ne relit pas le fichier.
---@param path string
---@param opts? { delay?: integer, quantize?: integer, hide_cursor?: boolean }
---  delay    : délai entre images en ms (défaut 80, soit ~12 i/s)
---  hide_cursor : masque le curseur du terminal tant que l'animation tourne
---                (défaut true, voir `Anim:hide_cursor`). Mettre false pour le
---                garder visible : il indique l'entrée de menu sélectionnée.
---  quantize : pas d'arrondi des couleurs 24 bits (défaut 8). Chaque couple de
---             couleurs devient un groupe de surbrillance, et nvim en refuse
---             plus de 20000 en tout (E849, treesitter et LSP compris). En
---             truecolor pur ce GIF en réclame ~19000 à lui seul ; arrondi au
---             multiple de 8, il en réclame ~4800 pour un écart de couleur
---             invisible. Mettre 0 pour désactiver.
---@return table|nil anim, string|nil err
function M.load(path, opts)
    if cache[path] then
        return cache[path]
    end

    local fd = io.open(path, "r")
    if not fd then
        return nil, "fichier introuvable : " .. path
    end
    local raw = fd:read("*a")
    fd:close()

    local frames = split_frames(raw)
    if #frames == 0 then
        return nil, "aucune image dans " .. path
    end

    local quantize = (opts and opts.quantize) or 8
    local self = setmetatable({
        frames = frames,
        parsed = {},                        -- images converties, à la demande
        idx = 1,
        delay = (opts and opts.delay) or 80,
        hide = not (opts and opts.hide_cursor == false),
        parse_opts = quantize > 0 and { quantize = quantize } or nil,
    }, Anim)

    -- Seule la première image est convertie tout de suite : c'est la seule dont
    -- on ait besoin au démarrage. Les 39 autres le seront au fil de l'animation,
    -- une fois chacune, pour ne pas payer ~1 Mo de parsing au lancement de nvim.
    self.parsed[1] = ansi_art.parse_lines(frames[1], self.parse_opts)

    cache[path] = self
    return self
end

---Les morceaux colorés d'une image, convertis à la demande.
---@param i integer
---@return table[][]
function Anim:lines(i)
    if not self.parsed[i] then
        self.parsed[i] = ansi_art.parse_lines(self.frames[i], self.parse_opts)
    end
    return self.parsed[i]
end

---La première image, au format attendu par une section `text` du dashboard.
---@return table[] chunks
function Anim:text()
    local chunks = {}
    for i, line in ipairs(self.parsed[1]) do
        if i > 1 then
            chunks[#chunks + 1] = { "\n" }
        end
        vim.list_extend(chunks, line)
    end
    return chunks
end

---Le buffer est-il toujours là et affiché ? Sinon l'animation n'a plus d'objet.
---@return boolean
function Anim:alive()
    if not (self.buf and vim.api.nvim_buf_is_valid(self.buf)) then
        return false
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == self.buf then
            return true
        end
    end
    return false
end

---Peint une image par-dessus les lignes du buffer.
---@param i integer
function Anim:draw(i)
    local buf, row = self.buf, self.row
    local frame = self:lines(i)
    local total = vim.api.nvim_buf_line_count(buf)

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for n, line in ipairs(frame) do
        local lnum = row + n - 1
        if lnum >= total then
            break
        end
        local virt = {}
        for _, chunk in ipairs(line) do
            virt[#virt + 1] = chunk.hl and { chunk[1], chunk.hl } or { chunk[1] }
        end
        vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
            virt_text = virt,
            virt_text_win_col = self.col,
            hl_mode = "replace",
            priority = 200,
        })
    end
end

---Masque le curseur du terminal pendant l'animation.
---
---POURQUOI : peindre une image, c'est ~35 Ko de séquences d'échappement, douze
---fois par seconde — 60 % des cellules changent d'une image à l'autre. Entre
---nvim, tmux et le terminal, le curseur finit par être dessiné au milieu du
---dessin, à une position différente à chaque image : on croit voir un curseur
---sauter au hasard sur le GIF. chafa fait exactement la même chose quand il
---anime un GIF — c'est le `ESC[?25l` en tête du fichier d'images — et pour
---cette raison précise.
---
---nvim n'expose pas `ESC[?25l`. On passe par `guicursor` : il fait émettre un
---OSC 12 avec la couleur du groupe visé. Un curseur de la couleur du fond est
---invisible quelle que soit sa forme, y compris le rectangle creux qu'Alacritty
---dessine quand la fenêtre n'a pas le focus.
function Anim:hide_cursor()
    if not self.hide or self.saved_cursor then
        return
    end
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local bg = normal.bg and ("#%06x"):format(normal.bg) or "#000000"
    vim.api.nvim_set_hl(0, "AnsiArtAnimNoCursor", { fg = bg, bg = bg })
    self.saved_cursor = vim.o.guicursor
    vim.o.guicursor = "a:AnsiArtAnimNoCursor"
end

function Anim:show_cursor()
    if not self.saved_cursor then
        return
    end
    vim.o.guicursor = self.saved_cursor
    self.saved_cursor = nil
end

function Anim:stop()
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    self:show_cursor()
    -- On efface nos extmarks : le buffer reprend son texte, c'est-à-dire la
    -- première image. Une animation arrêtée redevient l'art fixe d'avant.
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
    end
end

function Anim:start()
    if #self.frames < 2 or not self:alive() then
        return
    end
    -- On peint l'image courante sans attendre le premier tic : après un
    -- dashboard:update() le buffer vient de réafficher l'image 1, et 80 ms de
    -- retour en arrière se verraient.
    self:draw(self.idx)

    if vim.api.nvim_get_current_buf() == self.buf then
        self:hide_cursor()
    end

    self.timer = uv.new_timer()
    self.timer:start(self.delay, self.delay, vim.schedule_wrap(function()
        if not self:alive() then
            self:stop()
            return
        end
        self.idx = self.idx % #self.frames + 1
        self:draw(self.idx)
    end))
end

---Accroche l'animation à l'endroit où le dashboard vient de poser l'art.
---À appeler depuis le hook `render` d'un item : snacks y passe la position de
---la première ligne de l'item, `{ ligne 1-indexée, colonne 0-indexée du dernier
---caractère d'indentation }`. L'art commence donc à l'octet `col + 1`.
---@param buf integer
---@param pos integer[]  le second argument du hook `render`
function Anim:attach(buf, pos)
    self:stop()
    self.buf = buf
    self.row = pos[1] - 1        -- extmarks : lignes 0-indexées

    -- Le curseur n'est masqué que tant qu'on est DANS le dashboard : sortir vers
    -- un autre buffer (neo-tree, un fichier) doit le rendre immédiatement, sans
    -- attendre le prochain tic du timer. Les autocommandes attachées au buffer
    -- disparaissent d'elles-mêmes avec lui ; l'augroup est vidé à chaque attache.
    vim.api.nvim_clear_autocmds({ group = augroup })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = augroup,
        buffer = buf,
        callback = function()
            if self.timer then
                self:hide_cursor()
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
        group = augroup,
        buffer = buf,
        callback = function() self:show_cursor() end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = augroup,
        buffer = buf,
        callback = function() self:stop() end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = augroup,
        callback = function() self:show_cursor() end,
    })

    -- `render` est appelé AVANT que snacks n'écrive les lignes dans le buffer :
    -- on attend la fin du cycle pour mesurer l'indentation et poser les extmarks.
    vim.schedule(function()
        if not self:alive() then
            return
        end
        local line = vim.api.nvim_buf_get_lines(buf, self.row, self.row + 1, false)[1] or ""
        -- Colonne d'écran, pas d'octets (voir l'en-tête du fichier).
        self.col = vim.fn.strdisplaywidth(line:sub(1, pos[2] + 1))
        self:start()
    end)
end

return M
