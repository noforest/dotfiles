#!/bin/sh
# Pane jump list, like Ctrl-o / Ctrl-i in nvim, across windows and sessions.
#   jump.sh record <pane_id>   run by the pane-focus-in hook
#   jump.sh back | forward     bound to Alt+o / Alt+i
list=$(tmux show -gqv @jump_list)
pos=$(tmux show -gqv @jump_pos)
pos=${pos:-0}

case $1 in
record)
	# a move made by back/forward is not a new jump
	if [ "$(tmux show -gqv @jump_skip)" = "$2" ]; then
		tmux set -gu @jump_skip
		exit 0
	fi
	# like nvim, a new jump drops the entries ahead of the current one
	new=$(printf '%s\n' $list | head -n "$pos")
	[ "$(printf '%s\n' "$new" | tail -n 1)" = "$2" ] || new="$new $2"
	new=$(printf '%s\n' $new | tail -n 100)
	tmux set -g @jump_list "$(echo $new)" \; set -g @jump_pos "$(printf '%s\n' $new | wc -l)"
	;;
back | forward)
	[ "$1" = back ] && step=-1 || step=1
	alive=$(tmux list-panes -a -F '#{pane_id}')
	cur=$(tmux display -p '#{pane_id}')
	set -- $list
	i=$pos
	while :; do
		i=$((i + step))
		[ "$i" -ge 1 ] && [ "$i" -le $# ] || exit 0
		eval p=\${$i}
		# closed panes and the current one are skipped
		[ "$p" != "$cur" ] && printf '%s\n' "$alive" | grep -qx "$p" && break
	done
	tmux set -g @jump_pos "$i" \; set -g @jump_skip "$p" \; switch-client -t "$p"
	;;
esac
