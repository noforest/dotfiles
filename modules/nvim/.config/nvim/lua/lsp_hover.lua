-- LSP hover in the VS Code style.
--
-- The float opens on the signature alone and never moves afterwards. The
-- documentation sits below the fold: calling the hover again enters the float
-- and expands it into a reading window (the border footer says so). <Esc>
-- closes it from either side.
--
-- Python gets two extras: the signatures pyrefly sends are rewritten the way
-- Pylance words them, and the docstring comes from the interpreter when the
-- server has none (compiled modules such as numpy.random), through hover_doc.py.
--
-- The signature help shown while typing a call is prepared here too
-- (M.signature_help), since it reads the same signatures.

local M = {}

local focus_id = 'textDocument/hover'
local max_width = 80       -- of the float as it first opens
local expanded_width = 100 -- once expanded
local expand_hint = ' <leader>gh: expand '
local ns = vim.api.nvim_create_namespace('lsp_hover')
local hover_doc = vim.fn.stdpath('config') .. '/hover_doc.py'
local signature_header = false -- true names the callee above its signatures in the signature help

-- ---------------------------------------------------------------------------
-- Signatures. pyrefly words them after its internals: a constructor is its
-- `__new__` method, the receiver is a parameter, the layout depends on the
-- length. One parser reads every shape it sends and two renderers write them
-- back the way Pylance does, so that no function gets a treatment of its own.
-- ---------------------------------------------------------------------------

---Splits at the commas that sit outside any bracket or string.
---@return string[]
local function split_params(text)
    local parts, depth, quote, start = {}, 0, nil, 1
    for i = 1, #text do
        local ch = text:sub(i, i)
        if quote then
            if ch == quote then quote = nil end
        elseif ch == "'" or ch == '"' then
            quote = ch
        elseif ch == "(" or ch == "[" or ch == "{" then
            depth = depth + 1
        elseif ch == ")" or ch == "]" or ch == "}" then
            depth = depth - 1
        elseif ch == "," and depth == 0 then
            parts[#parts + 1] = vim.trim(text:sub(start, i - 1))
            start = i + 1
        end
    end
    local last = vim.trim(text:sub(start))
    if last ~= "" then parts[#parts + 1] = last end
    return parts
end

---Reads one signature, whatever its layout:
---  def play(self: MDP, state: int) -> int: ...
---  (cls: type[range], stop: SupportsIndex, /) -> range
---  [_T1, _T2](cls: type[zip[_T_co]], iter1: Iterable[_T1], /) -> zip[tuple[_T1, _T2]]
---The receiver (`self` or `cls`) is taken out of the parameters; `class` is the
---class it belongs to.
---@return { name: string?, params: string[], ret: string?, class: string? }?
local function parse(text)
    -- one line, and without the columns pyrefly pads its parameters into
    text = vim.trim(text:gsub("%s+", " ")):gsub("(%S) :", "%1:"):gsub(":%s*%.%.%.$", "")
    local open = text:find("(", 1, true)
    if not open then return end
    local depth, quote, close = 0, nil, nil
    for i = open, #text do
        local ch = text:sub(i, i)
        if quote then
            if ch == quote then quote = nil end
        elseif ch == "'" or ch == '"' then
            quote = ch
        elseif ch == "(" or ch == "[" or ch == "{" then
            depth = depth + 1
        elseif ch == ")" or ch == "]" or ch == "}" then
            depth = depth - 1
            if depth == 0 then close = i break end
        end
    end
    if not close then return end

    local sig = {
        name = text:sub(1, open - 1):match("def ([%w_]+)%s*$"),
        params = split_params(text:sub(open + 1, close - 1)),
        ret = text:sub(close + 1):match("^%s*%->%s*(.-)%s*$"),
    }
    local receiver = sig.params[1] and sig.params[1]:match("^([%a_][%w_]*)")
    if receiver == "self" or receiver == "cls" then
        local type_ = table.remove(sig.params, 1):match(":%s*(.+)$") or ""
        -- cls: type[range]   self: Self@MDP   self: list[_T]   self: numpy.ndarray
        local class = type_:match("^type%[([%w_%.]+)") or type_:match("^Self@([%w_]+)") or type_:match("^([%w_%.]+)")
        sig.class = class and class:match("([%w_]+)$")
        -- a positional-only marker with nothing left before it
        if sig.params[1] == "/" then table.remove(sig.params, 1) end
    end
    return sig
end

---The lines of one signature in a hover: on one line up to one parameter, one
---parameter per line beyond.
local function layout(head, sig, ret)
    local tail = ")" .. (ret and (" -> " .. ret) or "")
    if #sig.params <= 1 then return { head .. "(" .. (sig.params[1] or "") .. tail } end
    local lines = { head .. "(" }
    for i, param in ipairs(sig.params) do
        lines[#lines + 1] = "    " .. param .. (i < #sig.params and "," or "")
    end
    lines[#lines + 1] = tail
    return lines
end

---Rewrites the code block of a hover, given as its lines without the fences.
---`word` is the hovered name.
---  (method) __new__: def __new__(cls: type[range], stop, /) -> range: ...   ->  class range(stop, /)
---  (method) play: def play(self: MDP, state: int, action: int) -> int: ...  ->  (method) def play(...) -> int
---Returns nil for anything that is not a pyrefly signature (variables, modules,
---another server): the block is then shown as it came.
---@param block string[]
---@param word string
---@return string[]?
local function render_hover(block, word)
    local kind, header_name, rest = (block[1] or ""):match("^%((%a+)%) ([%w_]+):%s*(.*)$")
    if kind ~= "function" and kind ~= "method" and kind ~= "class" then return end
    if kind == "class" and #block == 1 then
        local class = rest:match("^type%[([%w_%.]+)%]$") -- (class) MDP: type[MDP]
        return class and { "class " .. class:match("([%w_]+)$") } or nil
    end

    -- one chunk per signature: several `def` follow each other for an overloaded class
    local chunks = {}
    for i, line in ipairs(block) do
        local text = i == 1 and rest or line
        if text:match("^def ") or #chunks == 0 then
            if vim.trim(text) ~= "" and not text:match("^@") then chunks[#chunks + 1] = text end
        elseif not text:match("^@") then
            chunks[#chunks] = chunks[#chunks] .. " " .. text
        end
    end

    local out = {}
    for _, chunk in ipairs(chunks) do
        local sig = parse(chunk)
        if not sig then return end
        local name = sig.name or header_name
        local lines
        -- a constructor shows the class being built, unless the hover is on the dunder itself
        if kind == "class" or ((name == "__new__" or name == "__init__") and word ~= name) then
            local class = (kind == "class" and not header_name:match("^__") and header_name) or sig.class or word
            lines = layout("class " .. class, sig, nil)
        else
            if name == "__call__" and word ~= name then name = word end
            lines = layout(("(%s) def %s"):format(kind, name), sig, sig.ret)
        end
        vim.list_extend(out, lines)
    end
    return #out > 0 and out or nil
end

---Rewrites the first code block of a hover with render_hover and drops
---pyrefly's line of "Go to" file links.
---@param lines string[]
---@param word string
---@return string[]
local function tidy_hover(lines, word)
    local out, block, blocks, in_code = {}, {}, 0, false
    for _, l in ipairs(lines) do
        if l:match("^```") then
            in_code = not in_code
            if in_code then
                blocks = blocks + 1
            elseif blocks == 1 then
                vim.list_extend(out, render_hover(block, word) or block)
            end
            out[#out + 1] = l
        elseif in_code and blocks == 1 then
            block[#block + 1] = l
        elseif not l:match("^Go to %[") then
            out[#out + 1] = in_code and l or (l:gsub("&nbsp;", " "))
        end
    end
    while out[#out] == "" do out[#out] = nil end
    return out
end

---The function whose call the cursor is in, as written: `np.random.randint`.
---It is what stands before the parenthesis left open on the cursor's left;
---the server does not name the callee in its signatures.
---ponytail: brackets inside string literals are counted too, use treesitter if
---that ever picks the wrong call.
---@return string?
local function callee()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.api.nvim_buf_get_lines(0, math.max(0, row - 20), row, false)
    lines[#lines] = lines[#lines]:sub(1, col)
    local text, depth = table.concat(lines, "\n"), 0
    for i = #text, 1, -1 do
        local ch = text:sub(i, i)
        if ch == ")" or ch == "]" or ch == "}" then
            depth = depth + 1
        elseif (ch == "(" or ch == "[" or ch == "{") and depth > 0 then
            depth = depth - 1
        elseif ch == "(" then
            return text:sub(1, i - 1):match("([%a_][%w_%.]*)%s*$")
        end
    end
end

---`name: Type = default` becomes `name=default`. Returns that and the bare
---name, or nil for the `/` and `*` markers.
---@return string?, string?
local function compact_param(text)
    if text == "/" or text == "*" then return end
    local depth, quote, colon, equals = 0, nil, nil, nil
    for i = 1, #text do
        local ch = text:sub(i, i)
        if quote then
            if ch == quote then quote = nil end
        elseif ch == "'" or ch == '"' then
            quote = ch
        elseif ch == "(" or ch == "[" or ch == "{" then
            depth = depth + 1
        elseif ch == ")" or ch == "]" or ch == "}" then
            depth = depth - 1
        elseif depth == 0 and not equals then
            if ch == ":" then
                colon = colon or i
            elseif ch == "=" and not text:sub(i - 1, i - 1):match("[=!<>]") and text:sub(i + 1, i + 1) ~= "=" then
                equals = i
            end
        end
    end
    local name = vim.trim(text:sub(1, (colon or equals or #text + 1) - 1))
    if name == "" then return end
    local default = equals and vim.trim(text:sub(equals + 1)) or ""
    return default ~= "" and (name .. "=" .. default) or name, name
end

---Lays a signatureHelp answer out the way the Signature Hints extension for
---VS Code does:
---  np.random.randint
---  (low, high=None, size=None)
---  (low, high=None, size=None, dtype=...)
---the callee (when signature_header is on), then one line per overload with the names of its parameters and
---their defaults, without annotations or return type. Overloads that take the
---same parameters differ only by what was just dropped and fold into one line.
---`marks` locates the active parameter on each line: { row, start_col, end_col }.
---@param help lsp.SignatureHelp
---@return { lines: string[], marks: integer[][] }?
function M.signature_help(help)
    local lines, marks, seen = {}, {}, {}
    local name = signature_header and callee() or nil
    if name then lines[1] = name end
    for _, sig in ipairs(help.signatures) do
        local parsed = parse(sig.label)
        -- the server counts neither the receiver nor the `/` and `*` markers, like the list built here
        local active = tonumber(sig.activeParameter) or tonumber(help.activeParameter)
        local text, names, mark = "(", {}, nil
        for _, param in ipairs(parsed and parsed.params or {}) do
            local piece, param_name = compact_param(param)
            if piece then
                if #names > 0 then text = text .. ", " end
                if #names == active then mark = { #text, #text + #piece } end
                names[#names + 1] = param_name
                text = text .. piece
            end
        end
        local key = table.concat(names, ",")
        if parsed and not seen[key] then
            seen[key] = true
            lines[#lines + 1] = text .. ")"
            if mark then marks[#marks + 1] = { #lines - 1, mark[1], mark[2] } end
        end
    end
    if #lines == (name and 1 or 0) then return end -- nothing this module can read
    return { lines = lines, marks = marks }
end

local function set_lines(buf, first, last, lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, first, last, false, lines)
    vim.bo[buf].modifiable = false
end

local function set_footer(win, text)
    vim.api.nvim_win_set_config(win, { footer = text, footer_pos = 'right' })
end

---Says that there is more below the fold. A footer wider than the float gets
---cut and shifted by nvim, so a narrow float only gets a mark.
local function set_expand_hint(win)
    local fits = vim.api.nvim_win_get_width(win) >= vim.fn.strdisplaywidth(expand_hint) + 2
    set_footer(win, fits and expand_hint or ' ▼ ')
end

---Shows the documentation's `### Section` lines as titles, without their marker.
local function decorate(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local in_code = false
    for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local marker = l:match("^#+ ")
        if l:match("^```") then
            in_code = not in_code
        elseif marker and not in_code then
            vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = #marker, conceal = "" })
            vim.api.nvim_buf_set_extmark(buf, ns, i - 1, #marker, { end_col = #l, hl_group = 'Title' })
        end
    end
end

---Enters the hover float and turns it into a centered reading window.
local function expand(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local width = math.min(expanded_width, vim.o.columns - 4)
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, width)
    -- the separator above the interpreter's docstring was drawn at the old width
    for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if vim.fn.trim(l, "─") == "" and l ~= "" then set_lines(buf, i - 1, i, { ("─"):rep(width) }) end
    end
    -- render-markdown shows the cursor line raw: keep the cursor off the opening fence
    if vim.api.nvim_buf_line_count(buf) > 1 and vim.api.nvim_win_get_cursor(win)[1] == 1 then
        vim.api.nvim_win_set_cursor(win, { 2, 0 })
    end
    local height = math.min(vim.api.nvim_win_text_height(win, {}).all, math.floor(vim.o.lines * 0.8))
    vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        anchor = 'NW', -- the float may have opened above the cursor, anchored by its bottom edge
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        footer = ' q / <Esc>: close ',
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
    if #lines > sig_end then set_expand_hint(win) end
    decorate(buf)

    -- <Esc> closes the float, whether the cursor is in the code or inside it
    -- (inside it, so does `q`: open_floating_preview maps it).
    -- A key listener rather than a mapping: nothing to restore on the source buffer.
    vim.on_key(function(key)
        if not vim.api.nvim_win_is_valid(win) then
            vim.on_key(nil, ns) -- no `return` of its value: a callback may only return ""
        elseif key == '\27' and vim.fn.mode() == 'n' then
            vim.on_key(nil, ns)
            vim.schedule(function() pcall(vim.api.nvim_win_close, win, true) end)
        end
    end, ns)
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
        decorate(fbuf)
        if vim.api.nvim_get_current_win() == win then
            expand(win) -- already entered: fit the new text
        else
            set_expand_hint(win)
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
        if vim.bo[bufnr].filetype == 'python' then lines = tidy_hover(lines, word) end
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

---Self-check of the signature rewriting: nvim --headless -c "lua require('lsp_hover')._check()" -c q
function M._check()
    local function eq(got, want)
        assert(got == want, ("\n--- got\n%s\n--- want\n%s"):format(got, want))
    end
    local function hover(word, text)
        return table.concat(tidy_hover(vim.split("```python\n" .. text .. "\n```", "\n"), word), "\n"):sub(11, -5)
    end
    -- constructors, however pyrefly lays them out
    eq(hover("range", "(method) __new__: def __new__(\n    cls: type[range],\n    stop: SupportsIndex,\n    /\n) -> range: ..."),
        "class range(\n    stop: SupportsIndex,\n    /\n)")
    eq(hover("MDP", "(method) __init__: def __init__(\n    self    : Self@MDP,\n    n_states: int,\n    gamma   : float = 0.9\n) -> Unknown: ..."),
        "class MDP(\n    n_states: int,\n    gamma: float = 0.9\n)")
    eq(hover("Point", "(class) Point: def Point(\n    self: Point,\n    x   : int\n) -> Point: ..."), "class Point(x: int)")
    eq(hover("zip", "(method) __new__: [_T1, _T2](\n    cls   : type[zip[_T_co]],\n    iter1 : Iterable[_T1],\n    iter2 : Iterable[_T2],\n    /\n) -> zip[tuple[_T1, _T2]]"),
        "class zip(\n    iter1: Iterable[_T1],\n    iter2: Iterable[_T2],\n    /\n)")
    eq(hover("dict", "(class) __init__: type[dict]"), "class dict")
    eq(hover("list", "(class) list: \n@overload\ndef __init__() -> list[Unknown]: ...\ndef __init__(iterable: Iterable[Unknown], /) -> list[Unknown]: ..."),
        "class list()\nclass list(\n    iterable: Iterable[Unknown],\n    /\n)")
    -- the dunder at its own definition is a method like any other
    eq(hover("__init__", "(method) __init__: def __init__(\n    self : Self@Agent,\n    env  : Unknown\n) -> Unknown: ..."),
        "(method) def __init__(env: Unknown) -> Unknown")
    -- methods and functions: no receiver, on one line or several alike
    eq(hover("get_gamma", "(method) get_gamma: def get_gamma(self: Self@MDP) -> Unknown: ..."), "(method) def get_gamma() -> Unknown")
    eq(hover("play", "(method) play: def play(\n    self: MDP,\n    state: int,\n    action: int\n) -> tuple[int, float]: ..."),
        "(method) def play(\n    state: int,\n    action: int\n) -> tuple[int, float]")
    eq(hover("zeros", "(method) __call__: def __call__(\n    self  : _ConstructorEmpty,\n    /,\n    shape : SupportsIndex,\n    dtype : None                      = None\n) -> ndarray: ..."),
        "(method) def zeros(\n    shape: SupportsIndex,\n    dtype: None = None\n) -> ndarray")
    eq(hover("print", "(function) print: def print(\n    *values: object,\n    sep    : str | None = ' ',\n    end    : str | None = '\\n'\n) -> None: ..."),
        "(function) def print(\n    *values: object,\n    sep: str | None = ' ',\n    end: str | None = '\\n'\n) -> None")
    eq(hover("make", "(method) make: def make() -> MDP: ..."), "(method) def make() -> MDP")
    -- not signatures, or not pyrefly's shape: untouched
    for _, text in ipairs({ "(variable) m: MDP", "(class) NoneType: None", "(module) np: Module[numpy]", "(keyword) in",
        "(variable) f: (int) -> str", "bool | Unknown", "(function) def f(\n    a: int\n) -> int" }) do
        eq(hover("x", text), text)
    end

    -- signature help: names and defaults, overloads stacked, repeats folded
    local function help(active, ...)
        local signatures = {}
        for i, label in ipairs({ ... }) do signatures[i] = { label = label, activeParameter = active } end
        local view = M.signature_help({ signatures = signatures, activeParameter = active })
        local shown = {}
        for _, m in ipairs(view.marks) do shown[#shown + 1] = ("%d:%s"):format(m[1], view.lines[m[1] + 1]:sub(m[2] + 1, m[3])) end
        return table.concat(view.lines, "\n") .. "  |  " .. table.concat(shown, " ")
    end
    local header = signature_header
    signature_header = false
    eq(help(0, "(cls: type[range], stop: SupportsIndex, /) -> range",
        "(cls: type[range], start: SupportsIndex, stop: SupportsIndex, step: SupportsIndex = 1, /) -> range"),
        "(stop)\n(start, stop, step=1)  |  0:stop 1:start")
    eq(help(1, "(self: RandomState, low: int, high: int | None = None, size: None = None) -> int",
        "(self: RandomState, low: int, high: int | None = None, size: _ShapeLike | None = None) -> ndarray",
        "(self: RandomState, low: int, high: int | None = None, size: None = None, dtype: type[bool] = ...) -> bool"),
        "(low, high=None, size=None)\n(low, high=None, size=None, dtype=...)  |  0:high=None 1:high=None")
    eq(help(1, "def play(self: Self@MDP, state: Unknown, action: Unknown) -> Unknown: ..."), "(state, action)  |  0:action")
    eq(help(2, [[def print(*values: object, sep: str | None = " ", end: str | None = "\n", file: SupportsWrite[str] | None = None, flush: Literal[False] = False) -> None: ...]]),
        [[(*values, sep=" ", end="\n", file=None, flush=False)  |  0:end="\n"]])
    eq(help(0, "(self: _ConstructorEmpty, /, shape: SupportsIndex, dtype: None = None, *, device: Literal['cpu'] | None = None) -> ndarray"),
        "(shape, dtype=None, device=None)  |  0:shape")
    eq(help(1, "def f(a: dict[str, int] = {'x': 1, 'y': 2}, b: Callable[[int], bool] = lambda v: v == 1, **kwargs: Any) -> None"),
        "(a={'x': 1, 'y': 2}, b=lambda v: v == 1, **kwargs)  |  0:b=lambda v: v == 1")
    eq(help(0, "def make() -> MDP: ..."), "()  |  ")
    signature_header = header
    print("ok")
end

return M
