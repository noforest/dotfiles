--- Richer <Tab> spot table: size, owner, permissions, full path, dir counts.
--- Registered as the spotter for `*`, so it also has to reproduce what the
--- built-in spotters contribute; it does that by calling their own spot_base.

local M = {}

local function date(t) return t and os.date("%Y-%m-%d %H:%M:%S", math.floor(t)) or "-" end

-- a cell given a list of strings renders one line each, so long values wrap
-- instead of being truncated; VALUE_W matches the table's second column
local VALUE_W = 58
local function wrapped(label, value)
	value = tostring(value or "-")
	if #value <= VALUE_W then return ui.Row { label, value } end
	local lines = {}
	for i = 1, #value, VALUE_W do lines[#lines + 1] = value:sub(i, i + VALUE_W - 1) end
	return ui.Row({ label, lines }):height(#lines)
end

local function dir_counts(url)
	local ok, files = pcall(fs.read_dir, url, {})
	if not ok or not files then return "-" end
	local dirs = 0
	for _, f in ipairs(files) do
		if f.cha.is_dir then dirs = dirs + 1 end
	end
	return string.format("%d entries (%d dirs, %d files)", #files, dirs, #files - dirs)
end

-- rows the matching built-in spotter would have added (image dimensions, etc.)
local function builtin_rows(job)
	local name
	-- `folder` is skipped on purpose: its only extra row is a size we already show
	if job.file.cha.is_dir then return {}
	elseif job.mime:match("^image/") then name = "image"
	elseif job.mime:match("^video/") then name = "video"
	end
	if not name then return {} end
	local ok, mod = pcall(require, name)
	if not ok or not mod or not mod.spot_base then return {} end
	local ok2, rows = pcall(mod.spot_base, mod, job)
	return (ok2 and rows) and rows or {}
end

function M:spot(job)
	local cha = job.file.cha

	local owner = "-"
	if cha.uid then
		owner = string.format("%s:%s", ya.user_name(cha.uid) or cha.uid, ya.group_name(cha.gid) or cha.gid or "?")
	end

	local rows = {
		ui.Row({ "Base" }):style(ui.Style():fg("green")),
		ui.Row { "  Size:",     cha.is_dir and dir_counts(job.file.url) or ya.readable_size(cha.len or 0) },
		ui.Row { "  Mimetype:", job.mime },
		ui.Row { "  Created:",  date(cha.btime) },
		ui.Row { "  Modified:", date(cha.mtime) },
		ui.Row { "  Accessed:", date(cha.atime) },
		ui.Row {},

		ui.Row({ "Location" }):style(ui.Style():fg("green")),
		wrapped("  Name:", job.file.name),
		wrapped("  Path:", tostring(job.file.url)),
	}
	if job.file.link_to then
		rows[#rows + 1] = wrapped("  Links to:", tostring(job.file.link_to))
	end

	for _, r in ipairs({
		ui.Row {},
		ui.Row({ "Ownership" }):style(ui.Style():fg("green")),
		ui.Row { "  Owner:", owner },
		ui.Row { "  Perms:", cha.perm and cha:perm() or "-" },
		ui.Row { "  Links:", tostring(cha.nlink or "-") },
	}) do rows[#rows + 1] = r end

	local extra = builtin_rows(job)
	if #extra > 0 then
		rows[#rows + 1] = ui.Row {}
		for _, r in ipairs(extra) do rows[#rows + 1] = r end
	end

	ya.spot_table(
		job,
		ui.Table(rows)
			:area(ui.Pos { "center", w = 76, h = 26 })
			:row(1)
			:col(1)
			:col_style(th.spot.tbl_col)
			:cell_style(th.spot.tbl_cell)
			:widths { ui.Constraint.Length(14), ui.Constraint.Fill(1) }
	)
end

return M
