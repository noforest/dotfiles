#!/bin/sh
# Alt+e under Alacritty: yazi in its own window, right of the one it was opened
# from. If that window is 9, yazi shows as 9.1, and the windows after them
# keep their displayed numbers although their real indexes shift by one.
# Quitting yazi goes back to the origin pane, and closing that pane closes yazi.
#   yazi.sh run <origin_pane_id>   the command of the yazi window
#   yazi.sh refresh                recomputes the displayed numbers (hooks)
#   yazi.sh goto <n> <session_id>  selects the window displayed as n

refresh() {
	# The displayed number lives in @num and the status formats show it
	# instead of #I. In a session without any yazi window, both are unset.
	F=$(tmux show -gv window-status-format | sed 's/#I/#{@num}/g')
	C=$(tmux show -gv window-status-current-format | sed 's/#I/#{@num}/g')
	export F C
	tmux list-windows -a -F '#{session_id} #{window_id} #{window_index} #{@origin_win}' |
		awk '
		function flush(   k, shift, lab, cnt) {
			for (k = 1; k <= n; k++) {
				if (org[k] != "") {
					shift++
					l[k] = lab[org[k]] "." ++cnt[org[k]]
				} else
					l[k] = lab[w[k]] = idx[k] - shift
			}
			for (k = 1; k <= n; k++) {
				if (!shift) {
					print "set -wu -t " w[k] " @num"
					print "set -wu -t " w[k] " window-status-format"
					print "set -wu -t " w[k] " window-status-current-format"
					continue
				}
				print "set -w -t " w[k] " @num \"" l[k] "\""
				print "set -w -t " w[k] " window-status-format \047" ENVIRON["F"] "\047"
				print "set -w -t " w[k] " window-status-current-format \047" ENVIRON["C"] "\047"
			}
			n = 0
		}
		$1 != s { flush(); s = $1 }
		{ n++; w[n] = $2; idx[n] = $3; org[n] = $4 }
		END { flush() }' |
		tmux source -
}

case $1 in
run)
	origin=$2
	win=$(tmux display -p -t "$TMUX_PANE" '#{window_id}')
	tmux set -w -t "$win" @origin_win "$(tmux display -p -t "$origin" '#{window_id}')"
	refresh

	# ponytail: polls every second, a pane hook would react instantly
	(
		while tmux list-panes -a -F '#{pane_id}' | grep -qx "$origin"; do sleep 1; done
		tmux kill-window -t "$win"
	) &
	watcher=$!

	yazi
	kill "$watcher"
	tmux switch-client -t "$origin"
	;;
refresh)
	refresh
	;;
goto)
	w=$(tmux list-windows -t "$3" -F '#{?@num,#{@num},#{window_index}} #{window_id}' |
		awk -v n="$2" '$1 == n { print $2; exit }')
	tmux select-window -t "${w:-$3:$2}"
	;;
esac
