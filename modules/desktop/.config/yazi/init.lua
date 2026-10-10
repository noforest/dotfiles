function Status:name()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end
	local linked = ""
	if h.link_to ~= nil then
		linked = " -> " .. tostring(h.link_to)
	end

	return ui.Span(" " .. h.name .. linked)
end

Status:children_add(function()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ui.Line({})
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("#6495ED"),
		ui.Span(":"):fg("#87CEFA"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("#6495ED"),
		ui.Span(" "),
	})
end, 500, Status.RIGHT)

Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ui.Line({})
	end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("#87CEFA")
end, 500, Header.LEFT)

require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})
-- DuckDB plugin configuration
require("duckdb"):setup({
    mode = "standard", -- ou "summarized"
    row_id = true,
    minmax_column_width = 25,
    column_fit_factor = 10.0
})

require("custom-shell"):setup({
    history_path = "default",
    save_history = true,
})

-- undo.yazi records file operations from yazi's own DDS events. Without this
-- call nothing is recorded and `u` has an empty journal to work from.
require("undo"):setup()

-- Under tmux the preview of the file yazi opens on is sometimes never drawn,
-- about one start in two with ghostty: an image is there as soon as the cursor
-- moves, and always there without tmux. Whatever loses that first image at
-- startup, asking for the preview once more shortly after brings it back.
-- 0.15 s is the shortest wait that never missed: 8 starts of 8, against 5 of 8
-- at 0.05 s and 3 of 8 with no wait at all.
if os.getenv("TMUX") then
	ya.async(function()
		ya.sleep(0.15)
		ya.emit("peek", { force = true })
	end)
end
