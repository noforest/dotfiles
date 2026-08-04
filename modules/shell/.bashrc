#
# ~/.bashrc
#

source /usr/share/blesh/ble.sh
bleopt highlight_syntax=
bleopt highlight_filename=
bleopt highlight_variable=
# bleopt complete_auto_complete=
# bleopt complete_auto_delay=300
bleopt complete_auto_history=
bleopt complete_ambiguous=
bleopt complete_menu_complete=
bleopt exec_exit_mark=
ble-face -s auto_complete fg=242,bg=none


# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export LS_COLORS="$(vivid generate dracula)"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias rm="rm -i"

alias l="eza -l --icons --git --group-directories-first"
alias ls="l"
alias ll="l"
alias la='eza -al --git --group-directories-first --icons=always'
alias lt="eza --tree --level=2 --icons --git"

alias sudo='sudo '
alias nv='nvim'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# PS1='[\u@\h \W]\$ '
# PS1='\[\e[0m\][\u@\h \W]\$ '

PS1='\[\e[31m\][\u@\h \[\e[32m\]\w\[\e[31m\]]\$\[\e[0m\] '
# PS1='\[\e[34m\][\u@\h \[\e[32m\]\w\[\e[34m\]]\$\[\e[0m\] '

# export LC_MONETARY="fr_FR-UTF8"
# export LC_PAPER="fr_FR-UTF8"
# export LC_NAME="fr_FR-UTF8"
# export LC_ADRESS="fr_FR-UTF8"
# export LC_TELEPHONE="fr_FR-UTF8"
# export LC_MEASUREMENT="fr_FR-UTF8"
# export LC_IDENTIFICATION="fr_FR-UTF8"


#add Directories to PATH
export PATH="$HOME/.local/bin:$PATH"

eval "$(zoxide init bash)"

eval "$(atuin init bash --disable-up-arrow)"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
. "$HOME/.cargo/env"


[ -r "$HOME/Documents/enseirb/s8/prog_multicoeur_et_gpu/easypap-ecole/script/easypap-completion.bash" ] && \
    . "$HOME/Documents/enseirb/s8/prog_multicoeur_et_gpu/easypap-ecole/script/easypap-completion.bash"
# ExAlgo completion - ajouté automatiquement
[ -r "$HOME/Documents/enseirb/s8/pfa/ein8-proj2-pfa-27709/completion.bash" ] && \
    source "$HOME/Documents/enseirb/s8/pfa/ein8-proj2-pfa-27709/completion.bash"
