# packages/ubuntu

Listes pour **Ubuntu 26.04 LTS (resolute)**, dérivées de `packages/arch/`.

Chaque nom a été vérifié contre l'index officiel de l'archive Ubuntu (main,
restricted, universe, multiverse), sur deux critères : le paquet existe dans cette
version, et ce n'est pas une redirection vers un snap. Les paquets de transition
comme `firefox`, `chromium-browser` ou `thunderbird` sont donc écartés, ils
n'installent que le snap correspondant.

Les groupes portent les mêmes noms que dans `packages/arch/`, puisqu'un profil
déclare `packages: core shell fonts x11-dwm ...` sans savoir sur quelle
distribution il tourne. `dot install` lit le dossier de la distribution détectée.

## Ce qui diffère d'Arch

Un paquet Ubuntu peut regrouper ce qu'Arch découpe. `x11-xserver-utils` remplace à
lui seul `xorg-xrandr`, `xorg-xset`, `xorg-xsetroot`, `xorg-xmodmap`, `xorg-xrdb`,
`xorg-xhost` et `xorg-iceauth`. Le compte total est donc plus bas sans que rien ne
manque.

Trois substitutions fonctionnelles, l'outil d'origine n'étant pas packagé :

| Arch | Ubuntu | Note |
|---|---|---|
| `diff-so-fancy` | `git-delta` | même rôle, binaire `delta` |
| `tldr` | `tealdeer` | même commande `tldr` |
| `neofetch` | `fastfetch` | neofetch n'est plus maintenu |

`x11-dwm.txt` ajoute les en-têtes de développement X11 (`libx11-dev`,
`libxft-dev`, `libxinerama-dev`...) dont `dot build-suckless` a besoin pour
compiler dwm, st, dmenu, slock et dwmblocks. Sur Arch, `base-devel` et les groupes
xorg les fournissent déjà.

## Ce qui n'est pas repris

`packages/arch/core.txt` contient `base`, `linux`, `linux-firmware`, `grub`,
`efibootmgr`, `pacman-contrib`, `reflector`, c'est un manifeste de réinstallation
d'Arch. Sur une Ubuntu déjà installée, le noyau et le bootloader appartiennent à la
distribution.

`aur.txt` n'a pas d'équivalent, `dot install` ignore le réglage `aur:` hors Arch.
Ce qui venait de l'AUR et reste utile est reventilé dans les groupes concernés
(`flameshot` et `qimgv` dans `desktop.txt`, `fastfetch` dans `shell.txt`). Le
reste, plus les outils appelés par `.xinitrc` qui ne sont pas packagés, est
documenté dans [manual.md](manual.md), à lire avant le premier `dot bootstrap`.

## Groupes encore absents

`dev.txt` et `extra.txt`, que seul le profil `full` déclare. Un groupe absent est
ignoré silencieusement, donc `full` s'installe partiellement sur Ubuntu sans rien
signaler.
