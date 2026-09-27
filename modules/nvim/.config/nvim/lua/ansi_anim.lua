-- Animates a GIF on the snacks dashboard, with the same constraints as the still
-- art of lua/ansi_art.lua: nothing may be destroyed or recreated when the
-- dashboard updates.
--
-- WHY NOT A `terminal` SECTION: it is destroyed and recreated on every
-- dashboard:update(), so on every WinResized, so on every <leader>e. It
-- lives in a floating window laid over the dashboard: flicker
-- guaranteed, and chafa rerun over and over for nothing.
--
-- HOW: the first frame of the GIF is laid down as static text, exactly
-- as the PNG was. It reserves the room in the buffer and sets
-- the layout. The next frames are then PAINTED OVER IT with
-- `virt_text` extmarks: the buffer text never changes, there is no reflow
-- nor layout recomputation, and if the animation stops the still frame remains.
--
-- `virt_text_win_col` rather than `virt_text_pos = "overlay"`: the art lives in
-- pane 2, and snacks builds each line by joining pane 1 and then a
-- gap. The BYTE column where the art starts therefore varies from line to line
-- (the icons of pane 1 are multibyte), whereas the SCREEN column
-- is constant, which is the whole point of panes. So the screen is used.
-- Safe here: the dashboard forces `wrap = false`.
--
-- PROPORTIONS: `--font-ratio` is not optional here. When its output goes
-- to a file, chafa can no longer query the terminal and falls back to
-- cells twice as tall as they are wide. Roboto Mono 12.5 in Alacritty
-- gives 10 × 24 px: without telling chafa, the drawing comes out stretched 20 % in
-- height. Measuring a cell = finding the horizontal step between two glyphs
-- and the vertical step between two lines, on a screenshot.
--
-- To regenerate the frames (chafa's raw output is kept as
-- is, the split into frames happens here):
--   chafa --size 50 --font-ratio 10/24 samurai_float.gif > samurai_float_frames.txt

local ansi_art = require("ansi_art")

local M = {}

local ns = vim.api.nvim_create_namespace("ansi_art_anim")
local augroup = vim.api.nvim_create_augroup("AnsiArtAnim", { clear = true })
local uv = vim.uv or vim.loop
local cache = {} ---@type table<string, table>  path -> animation already loaded

local Anim = {}
Anim.__index = Anim

---Splits chafa's raw output into frames.
---
---For a GIF, chafa writes: `ESC[?25l`, as many `ESC D` as lines (to
---reserve the room), `ESC[<n>A` to move back up, `ESC[s` to save the
---position, then the frames separated by `ESC[u` (back to the saved
---position), and finally `ESC[?25h`.
---
---CSI sequences are ignored by ansi_art's parser, but `ESC D` is not
---one (no `[`): it has to be removed by hand, or it would end up
---in the displayed text.
---
---Everything is done by slicing rather than with patterns: the file weighs 1 MB,
---and one `gsub` more or less counts in tens of milliseconds
---paid at nvim startup. Hence the cleanup targeting only the first and the
---last frame, the only ones affected.
---@param raw string
---@return string[]
local function split_frames(raw)
    local parts = vim.split(raw, "\27[u", { plain = true })
    if #parts == 0 then
        return {}
    end
    parts[1] = parts[1]:gsub("\27D", "")                -- preamble
    parts[#parts] = parts[#parts]:gsub("\27%[%?25h", "") -- cursor restored

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

---Loads an ANSI animation file (chafa's output on a GIF).
---The result is cached: reopening the dashboard does not read the file again.
---@param path string
---@param opts? { delay?: integer, quantize?: integer, hide_cursor?: boolean }
---  delay    : delay between frames in ms (default 80, about 12 fps)
---  hide_cursor : hides the terminal cursor while the animation runs
---                (default true, see `Anim:hide_cursor`). Set to false to
---                keep it visible: it shows the selected menu entry.
---  quantize : rounding step for 24-bit colours (default 8). Each pair of
---             colours becomes a highlight group, and nvim refuses
---             more than 20000 in total (E849, treesitter and LSP included). In
---             pure truecolor this GIF asks for ~19000 on its own, rounded to a
---             multiple of 8, it asks for ~4800 for a colour difference
---             nobody can see. Set to 0 to disable.
---@return table|nil anim, string|nil err
function M.load(path, opts)
    if cache[path] then
        return cache[path]
    end

    local fd = io.open(path, "r")
    if not fd then
        return nil, "file not found: " .. path
    end
    local raw = fd:read("*a")
    fd:close()

    local frames = split_frames(raw)
    if #frames == 0 then
        return nil, "no frame in " .. path
    end

    local quantize = (opts and opts.quantize) or 8
    local self = setmetatable({
        frames = frames,
        parsed = {},                        -- converted frames, on demand
        idx = 1,
        delay = (opts and opts.delay) or 80,
        hide = not (opts and opts.hide_cursor == false),
        parse_opts = quantize > 0 and { quantize = quantize } or nil,
    }, Anim)

    -- Only the first frame is converted right away: it is the only one
    -- needed at startup. The other 39 are converted as the animation goes,
    -- once each, to avoid paying for ~1 MB of parsing when nvim starts.
    self.parsed[1] = ansi_art.parse_lines(frames[1], self.parse_opts)

    cache[path] = self
    return self
end

---The coloured pieces of a frame, converted on demand.
---@param i integer
---@return table[][]
function Anim:lines(i)
    if not self.parsed[i] then
        self.parsed[i] = ansi_art.parse_lines(self.frames[i], self.parse_opts)
    end
    return self.parsed[i]
end

---The first frame, in the format a dashboard `text` section expects.
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

---Is the buffer still there and shown? Otherwise the animation is pointless.
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

---Paints a frame over the buffer lines.
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

---Hides the terminal cursor during the animation.
---
---WHY: painting a frame is ~35 KB of escape sequences, twelve
---times per second, and 60 % of the cells change from one frame to the next. Between
---nvim, tmux and the terminal, the cursor ends up drawn in the middle of the
---drawing, at a different position on each frame: it looks like a cursor
---jumping around on the GIF. chafa does exactly the same thing when it
---animates a GIF (that is the `ESC[?25l` at the top of the frames file), and for
---this very reason.
---
---nvim does not expose `ESC[?25l`. `guicursor` is used instead: it makes nvim emit an
---OSC 12 with the colour of the target group. A cursor the colour of the background is
---invisible whatever its shape, including the hollow rectangle Alacritty
---draws when the window is not focused.
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
    -- Our extmarks are cleared: the buffer shows its own text again, that is the
    -- first frame. A stopped animation turns back into the former still art.
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
    end
end

function Anim:start()
    if #self.frames < 2 or not self:alive() then
        return
    end
    -- The current frame is painted without waiting for the first tick: after a
    -- dashboard:update() the buffer has just shown frame 1 again, and 80 ms of
    -- going backwards would show.
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

---Attaches the animation where the dashboard has just laid down the art.
---To call from an item's `render` hook: snacks passes it the position of
---the item's first line, `{ 1-indexed line, 0-indexed column of the last
---indentation character }`. The art therefore starts at byte `col + 1`.
---@param buf integer
---@param pos integer[]  the second argument of the `render` hook
function Anim:attach(buf, pos)
    self:stop()
    self.buf = buf
    self.row = pos[1] - 1        -- extmarks: 0-indexed lines

    -- The cursor is only hidden while INSIDE the dashboard: leaving for
    -- another buffer (neo-tree, a file) must bring it back at once, without
    -- waiting for the next timer tick. The autocommands attached to the buffer
    -- go away with it on their own, and the augroup is cleared on every attach.
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

    -- `render` is called BEFORE snacks writes the lines into the buffer:
    -- wait for the end of the cycle to measure the indentation and set the extmarks.
    vim.schedule(function()
        if not self:alive() then
            return
        end
        local line = vim.api.nvim_buf_get_lines(buf, self.row, self.row + 1, false)[1] or ""
        -- Screen column, not bytes (see the file header).
        self.col = vim.fn.strdisplaywidth(line:sub(1, pos[2] + 1))
        self:start()
    end)
end

return M
