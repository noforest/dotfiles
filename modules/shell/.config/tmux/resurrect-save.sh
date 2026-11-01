#!/bin/sh
# Saves the tmux environment with tmux-resurrect (prefix + Ctrl-s), around what
# the plugin gets wrong on its own.

# Writes the session of every running nvim, which persistence.nvim otherwise only
# does on quitting. The require loads it where lazy.nvim has not. The autocmd is
# the one it runs on quitting, so it skips an nvim with no file open instead of
# overwriting a session with nothing. The timeout is for an nvim stuck on a
# prompt, which would block the save.
for socket in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*.0; do
    [ -S "$socket" ] || continue
    timeout 2 nvim --server "$socket" \
        --remote-expr 'execute(["lua require(\"persistence\")", "doautocmd persistence VimLeavePre"])' >/dev/null 2>&1
done

# The plugin reads its dump with a tab as the separator, so an empty pane title,
# as an nvim opened from yazi leaves, collapses and shifts the fields after it:
# the pane lost its directory and its command.
tmux list-panes -a -f '#{==:#{pane_title},}' -F '#{pane_id}' |
    xargs -r -I{} tmux select-pane -t {} -T untitled

~/.tmux/plugins/tmux-resurrect/scripts/save.sh

# In a pane showing nvim, yazi or claude the plugin captures that screen, and
# restores it as dead text above a plain shell. Those panes start empty instead.
contents="$(tmux show -gv @resurrect-dir)/pane_contents.tar.gz"
alternate=$(tmux list-panes -a -f '#{alternate_on}' -F './pane_contents/pane-#S:#I.#P')
[ -n "$alternate" ] || exit 0
archive=$(mktemp)
gzip -d <"$contents" >"$archive"
printf '%s\n' "$alternate" | xargs -r -d '\n' tar --delete -f "$archive" 2>/dev/null
gzip <"$archive" >"$contents"
rm "$archive"
