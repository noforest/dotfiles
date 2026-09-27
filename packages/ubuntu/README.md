# packages/ubuntu

Lists for **Ubuntu 26.04 LTS (resolute)**, derived from `packages/arch/`.

Every name was checked against the official index of the Ubuntu archive (main,
restricted, universe, multiverse), on two criteria: the package exists in this
release, and it is not a redirect to a snap. Transitional packages such as
`firefox`, `chromium-browser` or `thunderbird` are therefore left out, they only
install the matching snap.

The groups have the same names as in `packages/arch/`, since a profile
declares `packages: core shell fonts x11-dwm ...` without knowing which
distribution it runs on. `dot install` reads the folder of the detected distribution.

## What differs from Arch

One Ubuntu package can bundle what Arch splits up. `x11-xserver-utils` alone
replaces `xorg-xrandr`, `xorg-xset`, `xorg-xsetroot`, `xorg-xmodmap`, `xorg-xrdb`,
`xorg-xhost` and `xorg-iceauth`. The total count is therefore lower without
anything missing.

Three functional substitutions, since the original tool is not packaged:

| Arch | Ubuntu | Note |
|---|---|---|
| `diff-so-fancy` | `git-delta` | same role, `delta` binary |
| `tldr` | `tealdeer` | same `tldr` command |
| `neofetch` | `fastfetch` | neofetch is no longer maintained |

`x11-dwm.txt` adds the X11 development headers (`libx11-dev`,
`libxft-dev`, `libxinerama-dev`...) that `dot build-suckless` needs to
build dwm, st, dmenu, slock and dwmblocks. On Arch, `base-devel` and the xorg
groups already provide them.

## What is not carried over

`packages/arch/core.txt` holds `base`, `linux`, `linux-firmware`, `grub`,
`efibootmgr`, `pacman-contrib`, `reflector`: it is a manifest for reinstalling
Arch. On an Ubuntu that is already installed, the kernel and the bootloader belong
to the distribution.

`aur.txt` has no equivalent, `dot install` ignores the `aur:` setting outside Arch.
What came from the AUR and is still useful is spread over the relevant groups
(`flameshot` and `qimgv` in `desktop.txt`, `fastfetch` in `shell.txt`). The
rest, plus the tools `.xinitrc` calls that are not packaged, is
documented in [manual.md](manual.md), to read before the first `dot bootstrap`.

## Groups still missing

`dev.txt` and `extra.txt`, which only the `full` profile declares. A missing group is
skipped silently, so `full` installs partially on Ubuntu without reporting
anything.
