setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history 
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify


export SUDO_EDITOR="nvim"
export TERMINAL=alacritty
export EDITOR=nvim
export LC_ALL=en_US.UTF-8
export LC_TIME=en_US.UTF-8
export VIMPAGER_VIM=vim
# export VIMPAGER_OPTIONS="--cmd 'set mouse=a'"
export PAGER="vimpager"
export MANPAGER="vimpager"
# export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export RAINFROG_CONFIG=~/.config/rainfrog


# Pour colorer eza, tree, etc... (parfait pour la couleur violet)
export LS_COLORS="$(vivid generate dracula)"



[[ -r ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh


# export PATH="/sbin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
export GOPATH="$HOME/.local/share/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.atuin/bin:$PATH"
export PATH="$HOME/.pyenv/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export TODO_DB_PATH=$HOME/.config/td/todo.json
export PATH="$HOME/.pyenv/versions/3.11.11/bin:$PATH"
export PATH="$HOME/.pyenv/shims/auto-cpufreq:$PATH"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"


alias vlc="vlc-resume"
alias pdftoimage="pdftoppm"
alias okular="pdf"  # NOTE: script localisé à /usr/local/bin/pdf
alias handbrake="ghb"
alias sudo='sudo '
alias nv='nvim'
alias sn='shutdown now'
alias rb='reboot'
alias rm="rm -i"
alias diffu='diff -u "$1" "$2" | diff-so-fancy'
alias clang14=/usr/lib/llvm14/bin/clang
alias lock='xset s activate'


alias py="python3"
alias todo="td"
alias cat=bat
# alias less="bat --paging always"
alias du="dust -r"
alias yzai="y"
alias yz="y"
# alias ya="y"
alias grep="grep --color"

alias l="eza -l --icons --git --group-directories-first"
alias ls="l"
alias ll="l"
alias la='eza -al --git --group-directories-first --icons=always'
alias lt="eza --tree --level=2 --icons --git"

# ~~~~~~~(tend à être obsolète)~~~~~~~~~~~
alias "ls -ll"="ll"
alias "ls -la"="la"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

alias lg="lazygit"

# Dotfiles : dépôt classique + CLI `dot` (voir DOTFILES_DIR/README.md)
export DOTFILES_DIR="$HOME/Documents/programming/github-noforest/dotfiles"
alias dot="$DOTFILES_DIR/dot"
alias dotfiles="git -C $DOTFILES_DIR"



bindkey "^[[3~" delete-char
bindkey "^[[1;3D" backward-word    # Alt + flèche gauche
bindkey "^[[1;3C" forward-word     # Alt + flèche droite
bindkey "^[[1;5D" backward-word    # Ctrl + flèche gauche
bindkey "^[[1;5C" forward-word     # Ctrl + flèche droite


# recherche fuzzy dans tous les dossiers, y compris cachés

fuzzy_cd() {
    local dir
    dir=$(find "$HOME" -type d ! -path '*/.*' -print 2>/dev/null \
        | fzf \
              --height=40% \
              --bind 'ctrl-h:reload(find . -type d -print 2>/dev/null)' \
              --bind 'esc:abort' \
              --header 'Ctrl-H: to include hidden folders') || return
    cd "$dir" || return
}


# pour zsh
bindkey -s '^f' 'fuzzy_cd\n'

git() {
  if [[ "$1" == "glog" ]]; then
    shift
    # command git-graph --format "$(echo "%h \033[90m%ad\033[0m \033[34m%an\033[0m →  %s")" 
    
    # avec retour à la ligne 
    # command git-graph --format "$(echo "%h \033[90m%ad\033[0m \033[34m%an\033[0m \033[31m→ \033[0m %s%n ")"    

    # sans retour à la ligne 
    command git-graph --format "$(echo "%h \033[90m%ad\033[0m \033[34m%an\033[0m \033[31m→ \033[0m %s%n")"    
  elif [[ "$1" == "modif" ]]; then
    command git diff --stat HEAD~1 HEAD
  elif [[ "$1" == "lastpull" ]]; then
      command git log @{1}..@{0} --pretty=format:'%C(yellow)%h%Creset - %C(blue)%an%Creset, %C(magenta)%ar%Creset : %s'
      #              HEAD-1..HEAD
  else
    command git "$@"
  fi
}

# NOTE: GSL_PATH, les chemins de projets enseirb et les complétions de cours
#       sont propres à cette machine → ~/.zshrc.local (non versionné, sourcé en fin de fichier)

# ========= alacritty terminal in the same directory as the last terminal used
export TERMINAL_LAST_DIR="$HOME"

update_last_dir() {
    echo "$PWD" > "$HOME/.last_dir"
}

chpwd() {
    # Les répertoires qui déclenchent `td` sont définis dans ~/.zshrc.local
    # via le tableau TD_AUTO_DIRS (vide par défaut).
    local d
    for d in ${TD_AUTO_DIRS[@]:-}; do
        [[ "$PWD" == "$d" ]] && { td; break; }
    done
    update_last_dir;
}  # Appelé automatiquement après chaque `cd`

# Charger le dernier répertoire au lancement
if [ -f "$HOME/.last_dir" ]; then
    export TERMINAL_LAST_DIR="$(cat "$HOME/.last_dir")"
fi


# setopt IGNORE_EOF

# function confirm-exit() {
#     if [[ -z $BUFFER ]]; then
#         echo -n "Are you sure you want to quit? (y/N)"
#         if read -q; then
#             echo
#             exit
#         else
#             echo
#             zle redisplay
#         fi
#     else
#         zle delete-char-or-list
#     fi
# }
#
# zle -N confirm-exit
# bindkey '^D' confirm-exit


# if [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
#     alias firefox='firefox -P default-release'
# elif [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
#     alias firefox='firefox -P hyprland'
# fi



export PS1='[\u@\h] \W :: $(git branch --show-current 2>/dev/null)> '
eval "$(zoxide init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(starship init zsh)"
# export STARSHIP_CONFIG=~/.config/starship/customstarship_purple.toml
export STARSHIP_CONFIG=~/.config/starship/customstarship.toml
# export STARSHIP_CONFIG=~/.config/starship/starship.toml
# export STARSHIP_CONFIG=~/.config/starship/templateFromInternet.toml

ZSH_AUTOSUGGEST_MANUAL_REBIND=0

# precmd() {
#   echo -ne "\033]0;Alacritty: ${PWD/#$HOME/~}\007"
# }

# if ps -p $(ps -o ppid= -p $$) | grep -q alacritty; then
#     precmd() {
#         echo -ne "\033]0;Alacritty: ${PWD/#$HOME/~}\007"
#     }
# fi

# if [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
#     nvim() {
#         echo -ne "\033]0;nvim: ${PWD/#$HOME/~}\007"
#         command nvim "$@"
#         echo -ne "\033]0;Alacritty: ${PWD/#$HOME/~}\007"
#     }
#
# precmd() {
#     echo -ne "\033]0;Alacritty: ${PWD/#$HOME/~}\007"
# }
# fi

# Vérifie si on est bien lancé depuis Alacritty (même dans tmux)
if [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
    precmd() {
        # Change le titre de la fenêtre alacritty avec le chemin courant
        echo -ne "\033]0;Alacritty: ${PWD/#$HOME/~}\007"
    }
fi


function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

image() {
    qimgv "$@" > /dev/null 2>&1 &
}

#################################################################
# config pour tmux

# export TERM="tmux-256color"
export TERM="xterm-256color"
export COLORTERM=truecolor

# sert pour tmux pour pas rentrer en mode normal notamment
set -o emacs

# if [[ -z $TMUX ]] && [[ -z $DISPLAY ]]; then
#    exec tmux
# fi


#################################################################


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null
# END opam configuration


#################################################################
# Réglages propres à CETTE machine — jamais versionnés.
# Chemins de projets, variables d'école, complétions locales, TD_AUTO_DIRS…
# Voir examples/zshrc.local dans le dépôt pour un modèle.
#################################################################
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
