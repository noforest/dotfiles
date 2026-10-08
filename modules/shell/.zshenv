[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

[ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"

# ghostty: drop the `cursor` shell-integration feature, which turns the block
# cursor into a bar at the prompt. `shell-integration-features = no-cursor` in
# the ghostty config is not enough: the Ubuntu package starts ghostty from its
# desktop file, D-Bus service and systemd unit with
# `--shell-integration-features=ssh-env`, and a command-line value replaces the
# config's, which puts every feature it does not name back to its default,
# cursor included. ghostty sources this file before its integration script
# reads the variable.
if [[ -n ${GHOSTTY_SHELL_FEATURES-} ]]; then
    export GHOSTTY_SHELL_FEATURES=${(j:,:)${(@)${(s:,:)GHOSTTY_SHELL_FEATURES}:#cursor*}}
fi
