# Installs that do not come from apt

Ubuntu 26.04 LTS. These tools are referenced by the configs but have no package in
the official archive. `dot install` does not handle them.

## 0. Run these first

```sh
./scripts/ubuntu-remove-snap.sh --list    # what you would lose, with replacements
./scripts/ubuntu-install-firefox-deb.sh   # real Firefox deb, before losing the snap
./scripts/ubuntu-remove-snap.sh           # purges snapd and blocks it in apt
./scripts/ubuntu-no-ads-no-telemetry.sh   # Ubuntu Pro adverts, APT News, MOTD, reporting
```

No package in `packages/ubuntu/` pulls in a snap, every name was checked against
the archive index for that. But a fresh Ubuntu ships snapd already installed, so
removing it is a separate step.

Order matters. `--list` prints every installed snap with a suggested non-snap
replacement and removes nothing, so you can install what you need first. The
Firefox script follows Mozilla's official instructions, including the fingerprint
check and the deb822 `.sources` format that 26.04 expects.

## 1. Two renamed binaries, to fix first

Debian renames two commands, and `.zshrc` calls them by their upstream name.

```sh
mkdir -p ~/.local/bin
ln -s "$(command -v batcat)" ~/.local/bin/bat
ln -s "$(command -v fdfind)" ~/.local/bin/fd
```

Without this, `alias cat=bat` (`.zshrc:72`) fails on every prompt.

`diff-so-fancy` has no package either. `git-delta` is installed instead and does
the same job, but the binary is `delta`, so `alias diffu` (`.zshrc:65`) needs
adapting.

## 2. Called by `.xinitrc`, so the session needs them

| Tool | Where it is used | How to get it |
|---|---|---|
| `clipster` | clipboard daemon, `.xinitrc` | `pipx install clipster`, or clone the upstream repository |
| `libinput-gestures` | touchpad gestures, `.xinitrc` | clone from GitHub, `sudo ./libinput-gestures-setup install`, and add yourself to the `input` group |
| `xidlehook` | `xidlehook-start.sh` | `cargo install xidlehook`, or drop the call |

The session still starts without them, they are launched with `&` and nothing
checks the result.

## 3. Display manager

`ly` is not packaged. Either build it from source, or use the one Ubuntu ships
(`lightdm` plus `lightdm-gtk-greeter`) and drop the `arch` scope of `system/`,
which is what carries `/etc/ly/config.ini`.

The dwm session entry comes from `system/x11-dwm/root/usr/share/xsessions/dwm.desktop`
and works with any display manager.

## 4. Applications from vendor repositories

Not in the archive, or only as a snap stub. Each one has its own apt repository,
AppImage or flatpak.

| Application | Note |
|---|---|
| `firefox` | the `firefox` deb only installs the snap. Use the Mozilla apt repository for a real package. |
| `obsidian`, `bitwarden`, `discord`, `spotify`, `teams-for-linux` | vendor repository, AppImage or flatpak |
| `librewolf` | its own apt repository |
| `visual-studio-code`, `positron` | Microsoft and Posit repositories |
| `zotero` | tarball from zotero.org |
| `libdvdcss` | VideoLAN repository, legal reasons |
| `gzdoom`, `freedoom` | flatpak, or build from source |
| `masterpdfeditor`, `forticlient-vpn`, `jlink` | vendor downloads |

## 5. Fonts

The patched Nerd Fonts families are not packaged. `dot fonts` installs them, same
as on Arch. `fonts-firacode`, `fonts-hack` and `fonts-jetbrains-mono` in
`fonts.txt` are the unpatched upstream families, they do not carry the icons.

## 6. Toolchains

`clang`, `llvm` and `compiler-rt` are versioned packages here (`clang-18`,
`llvm-18`). The Arch list pins 14 and 16, which no longer exist in this archive.
Install the version your projects need, or `clang` and `llvm` for the default.

`paru` and `yay` are AUR helpers, they have no meaning here.
