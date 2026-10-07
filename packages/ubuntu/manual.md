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

## 1. neovim comes from its own release

The archive has neovim 0.11.6 and the config needs 0.12. `dot install` runs
`scripts/ubuntu-install-neovim.sh`, which downloads the official release, checks
its SHA256 against the sum pinned in the script and unpacks it under
`~/.local/opt`, with a link in `~/.local/bin`. No sudo, nothing outside `$HOME`.
To move to a newer release, change the version and the two sums in the script.

## 1b. Two renamed binaries

Debian renames two commands, and `.zshrc` calls them by their upstream name.
`dot install` links them in `~/.local/bin` right after apt: `bat` to `batcat`,
`fd` to `fdfind`. Without these links, `alias cat=bat` fails.

`diff-so-fancy` has no package either. `git-delta` is installed instead and does
the same job, but the binary is `delta`, so `alias diffu` (`.zshrc:65`) needs
adapting.

`vimpager` and `git-graph` are not packaged. `.zshrc` checks for both: without
`vimpager`, `$PAGER` is `less`, and without `git-graph`, `git glog` is the plain
`log --graph --oneline` alias of `.gitconfig`. To get the originals back,
`cargo install git-graph`, and `make install` from the vimpager repository.

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

The Nerd Fonts are not packaged. `dot fonts` downloads two of them into
`~/.local/share/fonts`:

- **RobotoMono Nerd Font**, the font alacritty, kitty and ghostty ask for.
  `dot gnome-settings` makes its Mono variant the system monospace font, which
  the GNOME terminal follows unless its profile sets a font of its own. The Mono
  variant keeps every icon inside one cell, the only width that terminal draws
  without running into the next letter.
- **Symbols Nerd Font**, which `.config/fontconfig/fonts.conf` appends to every
  family as a fallback, so the icons show in the other fonts as well.

Emoji come from `fonts-noto-color-emoji`. `fonts-firacode`, `fonts-hack` and
`fonts-jetbrains-mono` in `fonts.txt` are the unpatched upstream families, they
do not carry the icons.

## 6. Toolchains

`clang`, `llvm` and `compiler-rt` are versioned packages here (`clang-18`,
`llvm-18`). The Arch list pins 14 and 16, which no longer exist in this archive.
Install the version your projects need, or `clang` and `llvm` for the default.

`paru` and `yay` are AUR helpers, they have no meaning here.

## 7. rclone, for `sync-gdrive-enseirb`

The archive ships rclone 1.60, where `bisync` is still experimental: no
`--resilient`, no `--recover`, no `--conflict-resolve`, and one interrupted run
demands a manual `--resync`. `sync-gdrive-enseirb` refuses anything older than 1.66, so
install the upstream package instead of the one from apt.

```sh
curl -fsSLO https://downloads.rclone.org/rclone-current-linux-amd64.deb
sudo apt install ./rclone-current-linux-amd64.deb
rclone config          # create a remote named gdrive-enseirb, the same account as the other machines
```

apt leaves it alone afterwards, its version being higher than the archive's.

On a machine other people administer, give the remote the `drive.file` scope
rather than full access: the token then only reaches what rclone itself created
with this client_id, which is `sync-enseirb` and nothing else on the Drive.

```sh
rclone config update gdrive-enseirb scope=drive.file
rclone config reconnect gdrive-enseirb:
rclone lsd gdrive-enseirb:     # must list sync-enseirb only
```

The backup has its own remote, `gdrive`, which keeps the full `drive` scope:
its folder predates the client_id.
