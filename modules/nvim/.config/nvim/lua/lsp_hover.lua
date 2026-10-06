-- LSP hover in the VS Code style.
--
-- The float opens on the signature alone and never moves afterwards. The
-- documentation sits below the fold: calling the hover again enters the float
-- and expands it into a reading window (the border footer says so).
--
-- Python gets two extras: the signatures pyrefly sends are rewritten the way
-- Pylance words them, and the docstring comes from the interpreter when the
-- server has none (compiled modules such as numpy.random), through hover_doc.py.

local M = {}

local focus_id = 'textDocument/hover'
local max_width = 80       -- of the float as it first opens
local expanded_width = 100 -- once expanded
local expand_hint = ' <leader>gh: expand '
local hover_doc = vim.fn.stdpath('config') .. '/hover_doc.py'

---Rewrites the first code block of a hover, as pyrefly sends it:
---  (method) __new__: def __new__(cls: type[range], stop, /) -> range: ...   becomes  class range(stop, /)
---  (method) play: def play(self: MDP, state: int) -> int: ...              becomes  (method) def play(state: int) -> int
---and drops its line of "Go to" file links. `word` is the hovered name.
---Other servers do not match these shapes and pass through untouched.
---@param lines string[]
---@param word string
---@return string[]
local function tidy_signature(lines, word)
    local out = {}
    local block, row = 0, 0 -- code block being read (0: none yet), row inside it
    local in_code, ctor, dropped_self = false, false, false
    for _, l in ipairs(lines) do
        if l:match("^```") then
            in_code = not in_code
            if in_code then block, row = block + 1, 0 end
            out[#out + 1] = l
        elseif in_code and block == 1 then
            row = row + 1
            -- pyrefly pads its parameters into columns, which pushes the defaults far to the right
            l = l:gsub("(%S)%s+:", "%1:"):gsub("(%S)%s%s+=", "%1 ="):gsub(": %.%.%.$", "")
            local keep = true
            if row == 1 then
                local kind, name, rest = l:match("^%((%a+)%) ([%w_]+): (.*)$")
                if kind and (kind == "class" or name == "__new__" or name == "__init__") then
                    -- a constructor: show the class being built, not its dunder method
                    ctor = true
                    l = "class " .. (name:match("^__") and word or name) .. (rest:match("%($") and "(" or "")
                elseif kind and rest:match("^def ") then
                    if name == "__call__" then name = word end
                    l = ("(%s) def %s%s"):format(kind, name, (rest:gsub("^def [%w_]+", "")))
                end
            elseif row == 2 and (l:match("^%s+self[:,]") or l:match("^%s+cls[:,]")) then
                keep, dropped_self = false, true
            elseif row == 3 and dropped_self and l:match("^%s+/,?$") then
                keep = false -- a positional-only marker with nothing left before it
            elseif ctor and l:match("^%) %->") then
                l = ")"
            end
            if keep then out[#out + 1] = l end
        elseif not l:match("^Go to %[") then
            out[#out + 1] = in_code and l or (l:gsub("&nbsp;", " "))
        end
    end
    while out[#out] == "" do out[#out] = nil end
    return out
end

local function set_lines(buf, first, last, lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, first, last, false, lines)
    vim.bo[buf].modifiable = false
end

local function set_footer(win, text)
    vim.api.nvim_win_set_config(win, { footer = text, footer_pos = 'right' })
end

---Enters the hover float and turns it into a centered reading window.
local function expand(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local width = math.min(expanded_width, vim.o.columns - 4)
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, width)
    -- the separator above the interpreter's docstring was drawn at the old width
    for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if l:match("^─+$") then set_lines(buf, i - 1, i, { ("─"):rep(width) }) end
    end
    local height = math.min(vim.api.nvim_win_text_height(win, {}).all, math.floor(vim.o.lines * 0.8))
    vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        anchor = 'NW', -- the float may have opened above the cursor, anchored by its bottom edge
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        footer = ' q: close ',
        footer_pos = 'right',
    })
end

---@return integer? bufnr of the float
local function show(lines)
    local sig_end = #lines
    for i = 2, #lines do
        if lines[i]:match("^```") then sig_end = i break end
    end
    local buf, win = vim.lsp.util.open_floating_preview(lines, 'markdown', {
        border = 'rounded',
        focus_id = focus_id,
        max_width = max_width,
    })
    if not win then return end
    -- stop before the closing fence: treesitter conceals that line
    local sig_height = vim.api.nvim_win_text_height(win, { end_row = sig_end - 2 }).all
    vim.api.nvim_win_set_height(win, math.min(sig_height, vim.api.nvim_win_get_height(win)))
    if #lines > sig_end then set_footer(win, expand_hint) end
    return buf
end

function M.hover()
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.w[w][focus_id] then return expand(w) end
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local expr, word = vim.fn.expand('<cexpr>'), vim.fn.expand('<cword>')

    -- The interpreter runs alongside the LSP request and its docstring is appended
    -- below the fold whenever it lands: the float neither waits for it nor resizes.
    local fbuf, doc
    local function append_doc()
        local win = fbuf and doc and vim.fn.bufwinid(fbuf) or -1
        if win == -1 then return end
        local lines = { ("─"):rep(vim.api.nvim_win_get_width(win)) }
        vim.list_extend(lines, vim.split(doc, "\n"))
        set_lines(fbuf, -1, -1, lines)
        if vim.api.nvim_get_current_win() == win then
            expand(win) -- already entered: fit the new text
        else
            set_footer(win, expand_hint)
        end
    end

    -- ponytail: hover_doc.py only replays single-line imports, parse with ast
    -- there if multi-line `from x import (...)` ever matters.
    if vim.bo[bufnr].filetype == 'python' and expr:match("^[%a_][%w_%.]*$") then
        vim.system({ 'python3', hover_doc, expr }, {
            stdin = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
            text = true,
            timeout = 5000,
        }, vim.schedule_wrap(function(out)
            local text = vim.trim(out.stdout or "")
            if out.code == 0 and text ~= "" then
                doc = text
                append_doc()
            end
        end))
    end

    vim.lsp.buf_request_all(bufnr, 'textDocument/hover', function(client)
        return vim.lsp.util.make_position_params(0, client.offset_encoding)
    end, function(results)
        local lines = {}
        for _, r in pairs(results) do
            local contents = r.result and r.result.contents
            if contents then
                vim.list_extend(lines, vim.lsp.util.convert_input_to_markdown_lines(contents))
            end
        end
        lines = tidy_signature(lines, word)
        if #lines == 0 then
            return vim.notify('No information available', vim.log.levels.INFO)
        end
        local buf = show(lines)
        -- the server sent no documentation of its own
        if lines[#lines]:match("^```") then
            fbuf = buf
            append_doc()
        end
    end)
end

---Self-check of tidy_signature: nvim --headless -c "lua require('lsp_hover')._check()" -c q
function M._check()
    local function tidy(word, text)
        return table.concat(tidy_signature(vim.split(text, "\n"), word), "\n")
    end
    local function eq(got, want)
        assert(got == want, ("\n--- got\n%s\n--- want\n%s"):format(got, want))
    end
    eq(tidy("range", "```python\n(method) __new__: def __new__(\n    cls: type[range],\n    stop: SupportsIndex,\n    /\n) -> range: ...\n```\n\nGo to [range](file:///x)"),
        "```python\nclass range(\n    stop: SupportsIndex,\n    /\n)\n```")
    eq(tidy("MDP", "```python\n(method) __init__: def __init__(\n    self    : MDP,\n    n_states: int,\n    gamma   : float = 0.9\n) -> Unknown: ...\n```"),
        "```python\nclass MDP(\n    n_states: int,\n    gamma: float = 0.9\n)\n```")
    eq(tidy("Point", "```python\n(class) Point: def Point(\n    self: Point,\n    x   : int\n) -> Point: ...\n```"),
        "```python\nclass Point(\n    x: int\n)\n```")
    eq(tidy("dict", "```python\n(class) __init__: type[dict]\n```"), "```python\nclass dict\n```")
    eq(tidy("zip", "```python\n(method) __new__: [_T1, _T2](\n    cls   : type[zip[_T_co]],\n    iter1 : Iterable[_T1],\n    /\n) -> zip[tuple[_T1, _T2]]\n```"),
        "```python\nclass zip(\n    iter1: Iterable[_T1],\n    /\n)\n```")
    eq(tidy("zeros", "```python\n(method) __call__: def __call__(\n    self  : _ConstructorEmpty,\n    /,\n    shape : SupportsIndex,\n    dtype : None                      = None\n) -> ndarray: ...\n```"),
        "```python\n(method) def zeros(\n    shape: SupportsIndex,\n    dtype: None = None\n) -> ndarray\n```")
    eq(tidy("play", "```python\n(method) play: def play(\n    self: MDP,\n    state: int\n) -> tuple[int, float]: ...\n```\n---\nPlay one&nbsp;step."),
        "```python\n(method) def play(\n    state: int\n) -> tuple[int, float]\n```\n---\nPlay one step.")
    eq(tidy("len", "```python\n(function) len: def len(self: list[int]) -> int: ...\n```"),
        "```python\n(function) def len(self: list[int]) -> int\n```")
    eq(tidy("make", "```python\n(method) make: def make() -> MDP: ...\n```"), "```python\n(method) def make() -> MDP\n```")
    -- already fine, or not pyrefly's shape: untouched
    eq(tidy("m", "```python\n(variable) m: MDP\n```"), "```python\n(variable) m: MDP\n```")
    eq(tidy("f", "```python\n(function) def f(\n    a: int\n) -> int\n```\ndoc"), "```python\n(function) def f(\n    a: int\n) -> int\n```\ndoc")
    print("ok")
end

return M
