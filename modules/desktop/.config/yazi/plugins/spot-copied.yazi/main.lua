--- Tiny companion to `copy cell`: confirms the copy with a short toast.
--- Chained after it in [spot], since `copy cell` itself is silent.
return {
	entry = function()
		ya.notify { title = "Spot", content = "Cell copied to clipboard", timeout = 1.5 }
	end,
}
