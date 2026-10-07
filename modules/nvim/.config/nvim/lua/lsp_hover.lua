-- LSP hover in the VS Code style.
--
-- The float opens on the signature alone and never moves afterwards. The
-- documentation sits below the fold: calling the hover again enters the float
-- and expands it into a reading window (the border footer says so), where the
-- long type annotations shortened in the small float are spelled out. <Esc>
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
local max_annotation = 48  -- longer type annotations are shortened in that first float
local expanded_width = 100 -- once expanded
local expand_hint = ' <leader>gh: expand '
local ns = vim.api.nvim_create_namespace('lsp_hover')
local hover_doc = vim.fn.stdpath('config') .. '/hover_doc.py'
-- Where the signature help names the callee:
--   'left'   np.random.randint(low, high=None, size=None)   before each signature
--   'top'    on a line of its own, over a rule
--   false    nowhere, the signatures start at their parenthesis like the server's
local signature_name = 'left'
-- Calls whose signature help is never shown. Globs, tested against the name as
-- written (`trajectory.append`) and against its last part (`append`): `*` stops
-- at a dot, `**` does not. { "print", "logging.*", "np.random.**" }
local signature_exclude = { "append" }
-- The rule under the name when it is on top. A thin line sits in the middle of its cell: the thin
-- ones drawn at the top (U+203E, U+23BA) are missing from most monospace fonts,
-- and the block drawn at the top (U+2594) is three times as thick.
local rule_char = "─"

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

---Cuts `name: Type = default` into its three parts; the last two may be nil.
---@return string, string?, string?
local function split_param(text)
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
    local annotation = colon and vim.trim(text:sub(colon + 1, (equals or #text + 1) - 1)) or nil
    local default = equals and vim.trim(text:sub(equals + 1)) or nil
    return name, annotation ~= "" and annotation or nil, default ~= "" and default or nil
end

---An annotation longer than max_annotation is cut there and ends on `…`. The
---brackets and the string left open by the cut are closed after it: the hover
---is highlighted as Python, and unbalanced brackets would cost the lines below
---their colours.
---  _NestedSequence[_SupportsArray[dtype[numpy.bool | floating | integer]]] | float
---  _NestedSequence[_SupportsArray[dtype[numpy.bool…]]]
local function shorten(annotation)
    if #annotation <= max_annotation then return annotation end
    local cut, closers, quote = annotation:sub(1, max_annotation), {}, nil
    -- not in the middle of a name: `dtype[…` rather than `dtype[num…`
    if annotation:sub(max_annotation + 1, max_annotation + 1):match("[%w_]") then
        local whole = cut:gsub("[%w_]+$", "")
        if whole ~= "" then cut = whole end
    end
    cut = cut:gsub("%s+$", "")
    for i = 1, #cut do
        local ch = cut:sub(i, i)
        if quote then
            if ch == quote then quote = nil end
        elseif ch == "'" or ch == '"' then
            quote = ch
        elseif ch == "(" or ch == "[" or ch == "{" then
            table.insert(closers, 1, ch == "(" and ")" or ch == "[" and "]" or "}")
        elseif ch == ")" or ch == "]" or ch == "}" then
            table.remove(closers, 1)
        end
    end
    return cut .. "…" .. (quote or "") .. table.concat(closers)
end

---A parameter with its annotation shortened.
local function short_param(text)
    local name, annotation, default = split_param(text)
    if not annotation or #annotation <= max_annotation then return text end
    return name .. ": " .. shorten(annotation) .. (default and (" = " .. default) or "")
end

---The lines of one signature in a hover, in full and with its long annotations
---shortened (same number of lines in both). It stays on one line up to one
---parameter when that fits the float, and takes one line per parameter otherwise.
---@param suffix string appended after the return type: ": ..." in a list of overloads
---@return string[], string[]
local function layout(head, sig, ret, suffix)
    local function build(params, tail, one_line)
        if one_line then return { head .. "(" .. (params[1] or "") .. tail } end
        local lines = { head .. "(" }
        for i, param in ipairs(params) do
            lines[#lines + 1] = "    " .. param .. (i < #params and "," or "")
        end
        lines[#lines + 1] = tail
        return lines
    end
    local full_tail = ")" .. (ret and (" -> " .. ret) or "") .. suffix
    local short_tail = ")" .. (ret and (" -> " .. shorten(ret)) or "") .. suffix
    local one_line = #sig.params <= 1 and #head + #(sig.params[1] or "") + #full_tail + 1 <= max_width
    return build(sig.params, full_tail, one_line), build(vim.tbl_map(short_param, sig.params), short_tail, one_line)
end

---Rewrites the code block of a hover, given as its lines without the fences.
---`word` is the hovered name.
---  (method) __new__: def __new__(cls: type[range], stop, /) -> range: ...   ->  class range(stop, /)
---  (method) play: def play(self: MDP, state: int, action: int) -> int: ...  ->  (method)
---                                                                             def play(...) -> int
---A list of overloads is laid out the way Pylance does, each def closed by a
---body so that it stays valid Python for the highlighter:
---  (method)
---  def choice(...) -> int: ...
---
---  def choice(...) -> Any: ...
---Returns the block in full and with its long annotations shortened, or nil for
---anything that is not a pyrefly signature (variables, modules, another
---server): the block is then shown as it came.
---@param block string[]
---@param word string
---@return string[]?, string[]?
local function render_hover(block, word)
    local kind, header_name, rest = (block[1] or ""):match("^%((%a+)%) ([%w_]+):%s*(.*)$")
    if kind ~= "function" and kind ~= "method" and kind ~= "class" then return end
    if kind == "class" and #block == 1 then
        local class = rest:match("^type%[([%w_%.]+)%]$") -- (class) MDP: type[MDP]
        local line = class and { "class " .. class:match("([%w_]+)$") } or nil
        return line, line
    end

    -- one chunk per signature: several `def` follow each other for an overloaded callable
    local chunks = {}
    for i, line in ipairs(block) do
        local text = i == 1 and rest or line
        if text:match("^def ") or #chunks == 0 then
            if vim.trim(text) ~= "" and not text:match("^@") then chunks[#chunks + 1] = text end
        elseif not text:match("^@") then
            chunks[#chunks] = chunks[#chunks] .. " " .. text
        end
    end

    local full, short = {}, {}
    for i, chunk in ipairs(chunks) do
        local sig = parse(chunk)
        if not sig then return end
        local name = sig.name or header_name
        local head, ret, suffix
        -- a constructor shows the class being built, unless the hover is on the dunder itself
        if kind == "class" or ((name == "__new__" or name == "__init__") and word ~= name) then
            local class = (kind == "class" and not header_name:match("^__") and header_name) or sig.class or word
            head, ret, suffix = "class " .. class, nil, ""
        else
            if name == "__call__" and word ~= name then name = word end
            -- the kind on a line of its own, then the def: with one signature or several.
            -- A list of overloads needs each def closed by a body to stay valid Python.
            head, ret, suffix = "def " .. name, sig.ret, #chunks > 1 and ": ..." or ""
            if i == 1 then full[1], short[1] = ("(%s)"):format(kind), ("(%s)"):format(kind) end
        end
        if i > 1 then full[#full + 1], short[#short + 1] = "", "" end
        local full_lines, short_lines = layout(head, sig, ret, suffix)
        vim.list_extend(full, full_lines)
        vim.list_extend(short, short_lines)
    end
    if #full == 0 then return end
    return full, short
end

---Rewrites the first code block of a hover with render_hover and drops
---pyrefly's line of "Go to" file links. Returns the hover to show, and the
---lines of its signature block in full when some annotations were shortened.
---@param lines string[]
---@param word string
---@return string[], string[]?
local function tidy_hover(lines, word)
    local out, block, blocks, in_code, full_block = {}, {}, 0, false, nil
    for _, l in ipairs(lines) do
        if l:match("^```") then
            in_code = not in_code
            if in_code then
                blocks = blocks + 1
            elseif blocks == 1 then
                local full, short = render_hover(block, word)
                vim.list_extend(out, short or block)
                if full and table.concat(full, "\n") ~= table.concat(short, "\n") then full_block = full end
            end
            out[#out + 1] = l
        elseif in_code and blocks == 1 then
            block[#block + 1] = l
        elseif not l:match("^Go to %[") then
            out[#out + 1] = in_code and l or (l:gsub("&nbsp;", " "))
        end
    end
    while out[#out] == "" do out[#out] = nil end
    return out, full_block
end

---The function whose call the cursor is in, as written: `np.random.randint`.
---It is what stands before the parenthesis left open on the cursor's left;
---the server does not name the callee in its signatures. Empty when nothing
---nameable stands there (`f()(`, `(1, `), nil when no parenthesis is open.
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
            return text:sub(1, i - 1):match("([%a_][%w_%.]*)%s*$") or ""
        end
    end
end

---Whether a callee is in signature_exclude.
local function excluded(name)
    for _, glob in ipairs(signature_exclude) do
        local pattern = "^" .. vim.pesc(glob):gsub("%%%*%%%*", ".*"):gsub("%%%*", "[^.]*") .. "$"
        if name:match(pattern) or (name:match("[%w_]+$") or ""):match(pattern) then return true end
    end
    return false
end

---`name: Type = default` becomes `name=default`. Returns that and the bare
---name, or nil for the `/` and `*` markers.
---@return string?, string?
local function compact_param(text)
    if text == "/" or text == "*" then return end
    local name, _, default = split_param(text)
    if name == "" then return end
    return default and (name .. "=" .. default) or name, name
end

---Lays a signatureHelp answer out the way the Signature Hints extension for
---VS Code does:
---  np.random.randint(low, high=None, size=None)
---  np.random.randint(low, high=None, size=None, dtype=...)
---one line per overload, named after the callee as signature_name says, with the names of its parameters and
---their defaults, without annotations or return type. Overloads that take the
---same parameters differ only by what was just dropped and fold into one line.
---`marks` locates the active parameter on each line: { row, start_col, end_col }.
---`rule` is the row of the blank line left for the rule, if any.
---`name_rows` are the rows that start with the callee, `name_width` its length.
---Returns false when the cursor is in no call, or in one that signature_exclude
---lists: pyrefly still answers right before the opening parenthesis, where
---there is no callee to name, and the popup has no business staying open there. Returns nil when it cannot read
---the signatures, which are then the caller's to show.
---@param help lsp.SignatureHelp
---@param name string? of the callee, read from the code when nil
---@return { lines: string[], marks: integer[][], rule: integer?, name_rows: integer[], name_width: integer }|false|nil
function M.signature_help(help, name)
    local lines, marks, seen = {}, {}, {}
    name = name or callee()
    if not name or excluded(name) then return false end
    local on_top = signature_name == 'top' and name ~= ""
    local prefix = signature_name == 'left' and name or ""
    -- The blank line is where the caller draws a rule under the name (`rule`).
    -- A space rather than nothing: blink drops empty lines.
    if on_top then lines = { name, " " } end
    local head = #lines
    for _, sig in ipairs(help.signatures) do
        local parsed = parse(sig.label)
        -- the server counts neither the receiver nor the `/` and `*` markers, like the list built here
        local active = tonumber(sig.activeParameter) or tonumber(help.activeParameter)
        local text, names, mark = prefix .. "(", {}, nil
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
    if #lines == head then return end -- nothing this module can read
    -- the rows that start with the name
    local name_rows = {}
    if on_top then
        name_rows = { 0 }
    elseif prefix ~= "" then
        for i = 1, #lines do name_rows[i] = i - 1 end
    end
    return { lines = lines, marks = marks, rule = on_top and 1 or nil, name_rows = name_rows, name_width = #name }
end

---Whether the cursor sits between the parentheses of a call whose signature
---help is wanted.
function M.in_call()
    local name = callee()
    return name ~= nil and not excluded(name)
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

---Shows the documentation's `### Section` lines as titles, without their marker,
---and colours the name of each `def`: a signature shown alone has no body, which
---is not valid Python, and the highlighter then leaves its name uncoloured.
local function decorate(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local in_code = false
    for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local marker = l:match("^#+ ")
        local def_name = in_code and l:match("^def ([%w_]+)")
        if l:match("^```") then
            in_code = not in_code
        elseif def_name then
            vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 4, { end_col = 4 + #def_name, hl_group = '@function', priority = 200 })
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
    -- render-markdown turns wrap off in an LSP float whose text fits, which the
    -- small float does: the full annotations put back below would run off the window
    vim.wo[win].wrap = true
    -- the reading window has room for the annotations shortened in the small one
    local full_block = vim.b[buf].lsp_hover_full
    if full_block then
        set_lines(buf, 1, 1 + #full_block, full_block)
        vim.b[buf].lsp_hover_full = nil
        decorate(buf) -- the marks of the lines just replaced went with them
    end
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

---@param lines string[] the hover, with its long annotations shortened
---@param full_block string[]? its signature block in full, put back by expand()
---@return integer? bufnr of the float
local function show(lines, full_block)
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
    vim.b[buf].lsp_hover_full = full_block
    if #lines > sig_end or full_block then set_expand_hint(win) end
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
        vim.wo[win].wrap = true -- see expand(): the docstring is wider than the signature
        decorate(fbuf)
        if vim.api.nvim_get_current_win() == win then
            expand(win) -- already entered: fit the new text
        else
            set_expand_hint(win)
        end
    end

    -- ponytail: hover_doc.py only replays single-line imports, parse with ast
    -- there if multi-line `from x import (...)` ever matters.
    if vim.bo[bufnr].filetype == 'python' and expr:match("^[%a_][%w_%.]*$") and vim.fn.executable('python3') == 1 then
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
        local full_block
        if vim.bo[bufnr].filetype == 'python' then lines, full_block = tidy_hover(lines, word) end
        if #lines == 0 then
            return vim.notify('No information available', vim.log.levels.INFO)
        end
        local buf = show(lines, full_block)
        -- the server sent no documentation of its own
        if lines[#lines]:match("^```") then
            fbuf = buf
            append_doc()
        end
    end)
end

-- ---------------------------------------------------------------------------
-- The signature help popup, shown by blink.cmp while a call is being typed.
-- ---------------------------------------------------------------------------

---Takes over the signature help of blink.cmp in Python buffers. Call it once,
---after `require('blink.cmp').setup()`.
---  * what it shows: M.signature_help, instead of the labels of the server
---  * when: exactly while the cursor is between the parentheses of a call.
---    blink opens it on a typed "(" or "," and only refreshes it on a cursor move.
---  * elsewhere: only the active overload, the window otherwise lists them all.
---blink has no API for any of this, so its window function is wrapped at run
---time. Should an update move what the wrapper needs, it warns once and steps
---aside: the stock popup of blink keeps working.
function M.setup_signature()
    local ok, cmp, window, trigger, config = pcall(function()
        return require('blink.cmp'), require('blink.cmp.signature.window'),
            require('blink.cmp.signature.trigger'), require('blink.cmp.config')
    end)
    local highlight_ns = ok and config.appearance and config.appearance.highlight_ns
    if not (ok and highlight_ns and type(window.open_with_signature_help) == 'function' and window.win
            and type(trigger.hide) == 'function' and cmp.show_signature and cmp.is_signature_visible) then
        return vim.notify_once('lsp_hover: blink.cmp changed, its own signature help is used as is', vim.log.levels.WARN)
    end

    local open = window.open_with_signature_help
    window.open_with_signature_help = function(context, help)
        local signatures = help and help.signatures or {}
        local view = nil
        if vim.bo.filetype == 'python' and #signatures > 0 then
            view = M.signature_help(help)
            -- the cursor left the call: close, rather than keep a nameless popup
            if view == false then return trigger.hide() end
        end
        if not view then
            local active = signatures[(help and help.activeSignature or 0) + 1]
            if active then
                help = vim.tbl_extend('force', help, { signatures = { active }, activeSignature = 0 })
            end
            return open(context, help)
        end

        open(context, {
            signatures = vim.tbl_map(function(line) return { label = line } end, view.lines),
            activeSignature = 0,
        })
        local buf = window.win:get_buf()
        -- blink would highlight the active parameter on the first line only
        for _, mark in ipairs(view.marks) do
            vim.api.nvim_buf_set_extmark(buf, highlight_ns, mark[1], mark[2],
                { end_col = mark[3], hl_group = 'BlinkCmpSignatureHelpActiveParameter' })
        end
        -- The callee in the plain text colour. The popup is highlighted as a bare
        -- line of Python, which would colour it as a call whatever it is in the code.
        for _, row in ipairs(view.name_rows) do
            vim.api.nvim_buf_set_extmark(buf, highlight_ns, row, 0,
                { end_col = view.name_width, hl_group = 'NormalFloat', priority = 5000 })
        end
        -- A rule between the callee and its signatures, in the colour of the border.
        -- Virtual text over a blank line, like blink's own separator: the buffer is
        -- highlighted as Python and a line of dashes in it would be a syntax error.
        if view.rule then
            local width = 0
            for _, line in ipairs(view.lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
            vim.api.nvim_buf_set_extmark(buf, highlight_ns, view.rule, 0, {
                virt_text = { { rule_char:rep(width), 'FloatBorder' } },
                virt_text_pos = 'overlay',
            })
        end
    end

    vim.api.nvim_create_autocmd('CursorMovedI', {
        group = vim.api.nvim_create_augroup('LspHoverSignature', { clear = true }),
        callback = function()
            if vim.bo.filetype ~= 'python' then return end
            if not cmp.is_signature_visible() and M.in_call() then cmp.show_signature() end
        end,
    })
end

---Self-check of the signature rewriting: nvim --headless -c "lua require('lsp_hover')._check()" -c q
function M._check()
    local function eq(got, want)
        assert(got == want, ("\n--- got\n%s\n--- want\n%s"):format(got, want))
    end
    -- the signature block of a hover: as the small float shows it, and in full
    local function hover(word, text, full)
        local short, full_block = tidy_hover(vim.split("```python\n" .. text .. "\n```", "\n"), word)
        if full then return table.concat(full_block or {}, "\n") end
        return table.concat(short, "\n"):sub(11, -5)
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
        "class list()\n\nclass list(\n    iterable: Iterable[Unknown],\n    /\n)")
    -- the dunder at its own definition is a method like any other
    eq(hover("__init__", "(method) __init__: def __init__(\n    self : Self@Agent,\n    env  : Unknown\n) -> Unknown: ..."),
        "(method)\ndef __init__(env: Unknown) -> Unknown")
    -- methods and functions: no receiver, on one line or several alike
    eq(hover("get_gamma", "(method) get_gamma: def get_gamma(self: Self@MDP) -> Unknown: ..."), "(method)\ndef get_gamma() -> Unknown")
    eq(hover("play", "(method) play: def play(\n    self: MDP,\n    state: int,\n    action: int\n) -> tuple[int, float]: ..."),
        "(method)\ndef play(\n    state: int,\n    action: int\n) -> tuple[int, float]")
    eq(hover("zeros", "(method) __call__: def __call__(\n    self  : _ConstructorEmpty,\n    /,\n    shape : SupportsIndex,\n    dtype : None                      = None\n) -> ndarray: ..."),
        "(method)\ndef zeros(\n    shape: SupportsIndex,\n    dtype: None = None\n) -> ndarray")
    eq(hover("print", "(function) print: def print(\n    *values: object,\n    sep    : str | None = ' ',\n    end    : str | None = '\\n'\n) -> None: ..."),
        "(function)\ndef print(\n    *values: object,\n    sep: str | None = ' ',\n    end: str | None = '\\n'\n) -> None")
    eq(hover("make", "(method) make: def make() -> MDP: ..."), "(method)\ndef make() -> MDP")
    -- several overloads: Pylance's layout, each def valid Python
    eq(hover("choice", "(method) choice: \n@overload\ndef choice(\n    self: RandomState,\n    a   : int\n) -> int: ...\ndef choice(\n    self: RandomState,\n    a   : ArrayLike,\n    size: None = None\n) -> Any: ..."),
        "(method)\ndef choice(a: int) -> int: ...\n\ndef choice(\n    a: ArrayLike,\n    size: None = None\n) -> Any: ...")
    -- long annotations: shortened with their brackets closed, default kept, spelled out in full on expand
    local long = "(method) choice: def choice(\n    self: RandomState,\n    a: ArrayLike,\n    p: _NestedSequence[_SupportsArray[dtype[numpy.bool | floating | integer]]] | float | None = None\n) -> ndarray[tuple[Any, ...], dtype[signedinteger[_NBitLong]]]: ..."
    eq(hover("choice", long),
        "(method)\ndef choice(\n    a: ArrayLike,\n    p: _NestedSequence[_SupportsArray[dtype[numpy.bool…]]] = None\n) -> ndarray[tuple[Any, ...], dtype[signedinteger[…]]]")
    eq(hover("choice", long, true),
        "(method)\ndef choice(\n    a: ArrayLike,\n    p: _NestedSequence[_SupportsArray[dtype[numpy.bool | floating | integer]]] | float | None = None\n) -> ndarray[tuple[Any, ...], dtype[signedinteger[_NBitLong]]]")
    eq(shorten("Literal['a very long string literal that goes on and on', 'b'] | None"), "Literal['a very long string literal that goes on…']")
    -- nothing to shorten: no second version kept
    eq(hover("play", "(method) play: def play(self: MDP, state: int) -> int: ...", true), "")
    -- one parameter, but too long for one line: laid out like the others, so it gets shortened too
    eq(hover("seed", "(method) seed: def seed(self: RandomState, seed: _NestedSequence[_SupportsArray[dtype[numpy.bool | floating | integer]]] | int | None = None) -> None: ..."),
        "(method)\ndef seed(\n    seed: _NestedSequence[_SupportsArray[dtype[numpy.bool…]]] = None\n) -> None")
    -- not signatures, or not pyrefly's shape: untouched
    for _, text in ipairs({ "(variable) m: MDP", "(class) NoneType: None", "(module) np: Module[numpy]", "(keyword) in",
        "(variable) f: (int) -> str", "bool | Unknown", "(function) def f(\n    a: int\n) -> int" }) do
        eq(hover("x", text), text)
    end

    -- signature help: names and defaults, overloads stacked, repeats folded
    local function help(active, ...)
        local signatures = {}
        for i, label in ipairs({ ... }) do signatures[i] = { label = label, activeParameter = active } end
        local view = M.signature_help({ signatures = signatures, activeParameter = active }, "f")
        local shown = {}
        for _, m in ipairs(view.marks) do shown[#shown + 1] = ("%d:%s"):format(m[1], view.lines[m[1] + 1]:sub(m[2] + 1, m[3])) end
        return table.concat(view.lines, "\n") .. "  |  " .. table.concat(shown, " ")
    end
    local name_setting, exclude_setting = signature_name, signature_exclude
    signature_name, signature_exclude = false, {}
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
    -- where the callee is named
    local two = { signatures = { { label = "(cls: type[range], stop: SupportsIndex, /) -> range" },
        { label = "(cls: type[range], start: SupportsIndex, stop: SupportsIndex, step: SupportsIndex = 1, /) -> range" } }, activeParameter = 0 }
    local function shown(view)
        local parts = {}
        for _, m in ipairs(view.marks) do parts[#parts + 1] = ("%d:%s"):format(m[1], view.lines[m[1] + 1]:sub(m[2] + 1, m[3])) end
        return table.concat(view.lines, "\n") .. "  |  " .. table.concat(parts, " ") .. "  |  rule=" .. tostring(view.rule)
    end
    signature_name = 'left'
    eq(shown(M.signature_help(two, "np.arange")), "np.arange(stop)\nnp.arange(start, stop, step=1)  |  0:stop 1:start  |  rule=nil")
    signature_name = 'top'
    eq(shown(M.signature_help(two, "range")), "range\n \n(stop)\n(start, stop, step=1)  |  2:stop 3:start  |  rule=1")
    -- excluded calls
    signature_exclude = { "append", "logging.*", "np.random.**" }
    for name, want in pairs({ ["trajectory.append"] = true, append = true, ["logging.info"] = true, ["logging.a.b"] = false,
        ["np.random.rng.choice"] = true, ["np.zeros"] = false, appendix = false, [""] = false }) do
        eq(tostring(excluded(name)), tostring(want))
    end
    eq(tostring(M.signature_help(two, "trajectory.append")), "false")
    signature_name, signature_exclude = name_setting, exclude_setting
    print("ok")
end

return M
