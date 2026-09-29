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
# vim's :MANPAGER, replaced by modules/vim/.vim/plugin/manpager.vim
export MANPAGER="vim +MANPAGER --not-a-term -"
# export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export RAINFROG_CONFIG=~/.config/rainfrog


# Colours for eza, tree, etc... (perfect for purple)
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
# AUR python packages must build against the system python, not pyenv's
alias paru='PATH=/usr/bin:$PATH paru'
alias yay='PATH=/usr/bin:$PATH yay'


alias vlc="vlc-resume"
alias pdftoimage="pdftoppm"
alias pdf2ocr="ocrmypdf -l fra+eng"
alias okular="pdf"  # NOTE: script located at /usr/local/bin/pdf
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

# ~~~~~~~(becoming obsolete)~~~~~~~~~~~
alias "ls -ll"="ll"
alias "ls -la"="la"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

alias lg="lazygit"

# # OLD bare repository, kept intact as an archive.
# # Still browsable: `dotfiles log`, `dotfiles show HEAD:.zshrc`…
# alias dotfiles='git --git-dir=$HOME/.dotfiles_old/ --work-tree=$HOME'

# New repository and its CLI (see $DOTFILES_DIR/README.md)
export DOTFILES_DIR="$HOME/Documents/programming/github-noforest/dotfiles"
alias dotfiles="cd $DOTFILES_DIR"
alias dot="$DOTFILES_DIR/dot"
alias dotgit="git -C $DOTFILES_DIR"



bindkey "^[[3~" delete-char
bindkey "^[[1;3D" backward-word    # Alt + left arrow
bindkey "^[[1;3C" forward-word     # Alt + right arrow
bindkey "^[[1;5D" backward-word    # Ctrl + left arrow
bindkey "^[[1;5C" forward-word     # Ctrl + right arrow


# fuzzy search in every folder, hidden ones included

# fuzzy_cd() {
#     local dir
#     dir=$(find "$HOME" -type d ! -path '*/.*' -print 2>/dev/null \
#         | fzf \
#               --height=40% \
#               --bind 'ctrl-h:reload(find . -type d -print 2>/dev/null)' \
#               --bind 'esc:abort' \
#               --header 'Ctrl-H: to include hidden folders') || return
#     cd "$dir" || return
# }


# # for zsh
# bindkey -s '^f' 'fuzzy_cd\n'

git() {
  if [[ "$1" == "glog" ]]; then
    shift
    # command git-graph --format "$(echo "%h \033[90m%ad\033[0m \033[34m%an\033[0m →  %s")" 
    
    # with a line break 
    # command git-graph --format "$(echo "%h \033[90m%ad\033[0m \033[34m%an\033[0m \033[31m→ \033[0m %s%n ")"    

    # without a line break 
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

# NOTE: GSL_PATH, the enseirb project paths and the course completions
#       are specific to this machine → ~/.zshrc.local (not versioned, sourced at the end of the file)

# ========= alacritty terminal in the same directory as the last terminal used
export TERMINAL_LAST_DIR="$HOME"

update_last_dir() {
    echo "$PWD" > "$HOME/.last_dir"
}

chpwd() {
    # The directories that trigger `td` are set in ~/.zshrc.local
    # through the TD_AUTO_DIRS array (empty by default).
    local d
    for d in ${TD_AUTO_DIRS[@]:-}; do
        [[ "$PWD" == "$d" ]] && { td; break; }
    done
    update_last_dir;
}  # Called automatically after every `cd`

# Load the last directory at startup
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

# Checks the shell was started from Alacritty (even inside tmux)
if [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
    precmd() {
        # Sets the alacritty window title to the current path
        echo -ne "\033]0;Alacritty: ${PWD/#$HOME/~}\007"
    }
fi


function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    # yazi writes a VFS url (trash:///, remote://...) when you quit from one,
    # and those are not directories the shell can cd into
    if cwd="$(command cat -- "$tmp")" && [ -d "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

image() {
    qimgv "$@" > /dev/null 2>&1 &
}

# images (any format ImageMagick can read) -> a single PDF
# the trailing .pdf is optional: without it, the first input name is reused
# knobs: IMAGETOPDF_MAXPX (long edge cap), _QUALITY, _PAGESIZE
imagetopdf() {
    local usage="usage: imagetopdf <images...> [output.pdf]"
    (( $# < 1 )) && { echo "$usage" >&2; return 1; }
    local maxpx=${IMAGETOPDF_MAXPX:-2200} q=${IMAGETOPDF_QUALITY:-88}
    local page=${IMAGETOPDF_PAGESIZE:-A4}
    local out tmp i=0 f dst
    if [[ "${@[-1]:l}" == *.pdf ]]; then
        out="${@[-1]}"
        set -- "${@[1,-2]}"
        (( $# < 1 )) && { echo "$usage" >&2; return 1; }
    else
        out="${1:r}.pdf"
        # img2pdf overwrites without asking, and this name was never typed
        [[ -e "$out" ]] && { echo "imagetopdf: $out already exists, name the output explicitly" >&2; return 1; }
    fi
    tmp=$(mktemp -d)
    for f; do
        # already a jpg/png within the cap: embed it untouched, no re-encoding
        if [[ "${f:l}" == (*.jpg|*.jpeg|*.png) ]] &&
           (( $(magick identify -format '%[fx:max(w,h)]' "$f" 2>/dev/null || echo 0) <= maxpx )); then
            cp "$f" "$tmp/$(printf %04d $i).${f:e}"
        elif [[ $(magick "$f" -format %A info: 2>/dev/null) == (True|Blend) ]]; then
            dst="$tmp/$(printf %04d $i).png"          # transparency -> lossless
            magick "$f" -auto-orient -resize "${maxpx}x${maxpx}>" "$dst" \
                || { rm -rf "$tmp"; return 1 }
        else
            dst="$tmp/$(printf %04d $i).jpg"
            magick "$f" -auto-orient -resize "${maxpx}x${maxpx}>" -quality $q "$dst" \
                || { rm -rf "$tmp"; return 1 }
        fi
        (( i++ ))
    done
    # without --pagesize, img2pdf maps 1px to 1pt and yields a 42-inch page
    command img2pdf --fit into --pagesize "$page" "$tmp"/* -o "$out" && rm -rf "$tmp"
}

# images (any format ImageMagick can read, HEIC included) -> one <name>.jpg each,
# resized to fit mail attachments
# knobs: IMAGETOJPG_MAXPX (long edge cap), _QUALITY
imagetojpg() {
    (( $# < 1 )) && { echo "usage: imagetojpg <images...>" >&2; return 1; }
    local maxpx=${IMAGETOJPG_MAXPX:-2000} q=${IMAGETOJPG_QUALITY:-85} f out
    for f; do
        out="${f:r}.jpg"
        [[ -e "$out" ]] && { echo "imagetojpg: $out already exists, skipped" >&2; continue; }
        magick "$f" -auto-orient -resize "${maxpx}x${maxpx}>" -quality $q "$out" &&
            echo "$out ($(command du -h "$out" | cut -f1))"
    done
}

# videos (any format ffmpeg can read) -> H.265 + AAC, one <name>_compressed file each
# .mkv stays .mkv to keep every audio and subtitle track, anything else becomes
# .mp4 (video + audio), which plays everywhere
# knobs: COMPRESSVIDEO_CRF (higher = smaller, 23-28 is sane), _PRESET (slower = smaller)
compressvideo() {
    (( $# < 1 )) && { echo "usage: compressvideo <videos...>" >&2; return 1; }
    local crf=${COMPRESSVIDEO_CRF:-28} preset=${COMPRESSVIDEO_PRESET:-medium}
    local f out before after
    local -a streams
    for f; do
        if [[ "${f:l}" == *.mkv ]]; then
            out="${f:r}_compressed.mkv"
            streams=(-map 0 -c copy)
        else
            out="${f:r}_compressed.mp4"
            # hvc1 tag: without it, Apple players refuse H.265 in mp4
            streams=(-map 0:v:0 -map '0:a?' -tag:v hvc1 -movflags +faststart)
        fi
        # checked here: ffmpeg -n refuses to overwrite but still exits 0
        [[ -e "$out" ]] && { echo "compressvideo: $out already exists, skipped" >&2; continue; }
        # the scale keeps sizes even, which x265 requires
        ffmpeg -hide_banner -loglevel error -stats -n -i "$f" "${streams[@]}" \
            -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2' \
            -c:v libx265 -crf "$crf" -preset "$preset" -x265-params log-level=error \
            -c:a aac -b:a 128k "$out" || { echo "compressvideo: $f failed" >&2; continue; }
        before=$(stat -c %s "$f") after=$(stat -c %s "$out")
        printf '%s: %s -> %s (%d%%)\n' "$out" "$(numfmt --to=iec "$before")" \
            "$(numfmt --to=iec "$after")" $(( after * 100 / before ))
    done
}

# shadow img2pdf in favour of imagetopdf (which calls it via "command img2pdf")
img2pdf() {
    print -u2 "img2pdf is shadowed: use \"imagetopdf <images...> <output.pdf>\"."
    print -u2 "It also handles heic/webp/avif/raw, and leaves jpg/png untouched."
    print -u2 "For the raw tool anyway: command img2pdf $*"
    return 1
}

#################################################################
# config for tmux

# export TERM="tmux-256color"
export TERM="xterm-256color"
export COLORTERM=truecolor

# used for tmux, mainly to avoid entering normal mode
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
# Settings specific to THIS machine, never versioned.
# Project paths, school variables, local completions, TD_AUTO_DIRS…
# See examples/zshrc.local in the repository for a template.
#################################################################
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
export TMPDIR="/var/tmp"
