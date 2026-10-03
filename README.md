# dotfiles

My Linux environment as one repository: configs, scripts, suckless patches,
package lists. Reinstall a machine and get the same setup back without redoing it
by hand.

```sh
dot status                                  # what drifted?
dot adopt ~/.config/mpv/mpv.conf desktop    # bring a file under control
dot sync                                    # regenerate, then git add -A
dotgit commit -m "mpv: initial config"
```

One repository, several machines.

Three things are detected rather than declared:

- **the distribution**, read from `/etc/os-release`.
  <br>It picks the package lists and one `system/` scope.
- **the machine**, read from its chassis.
  <br>It picks the profile.
- **the graphical environment**, a module plus a scope.
  <br>Several can coexist and be chosen at login.

Tested on Arch with dwm. Ubuntu 26.04 LTS is supported, its package lists checked
name by name against the official archive.

> **`man dot`** is the reference: every command, and how to read every line of
> `dot status`. It is also printed section by section on demand, by
> `dot help commands`, `dot help status` and `dot help examples`. This README
> covers installing and the reasoning.

**Contents** ·
[How it works](#how-it-works) ·
[Everyday use](#everyday-use) ·
[Arch](#install-on-arch) ·
[Ubuntu](#install-on-ubuntu) ·
[Machine settings](#machine-specific-settings) ·
[Shared folder](#shared-folder) ·
[Another WM](#adding-a-graphical-environment) ·
[Design](#design-choices)

---

## How it works

Everything goes through the `dot` CLI, which deploys the repository in four ways.

| Directory | What it holds | Deployed as |
|---|---|---|
| `modules/` | What goes into `$HOME`.<br><br>`modules/shell/.zshrc` maps to `~/.zshrc`. | symlinks |
| `system/<scope>/root/` | What goes outside `$HOME`.<br><br>`system/common/root/etc/x` maps to `/etc/x`. | copies |
| `packages/<distro>/` | Package lists.<br><br>One file per group: `core.txt`, `dev.txt`. | installed |
| `suckless/` | Patched sources.<br><br>dwm, st, dmenu, slock, dwmblocks. | compiled in place |

Four more directories carry the settings rather than the content:

| Directory | What it holds |
|---|---|
| `profiles/` | Which of the four above go together. |
| `machine.d/` | The profile a machine defaults to. Not versioned. |
| `examples/` | Templates for local files that are never versioned. |
| `scripts/` | One-off tools. |

### Scopes

A **scope** is a reason to deploy a file: `common`, the distribution, the
hardware, the graphical environment.

Splitting them is what keeps a tower from receiving the touchpad and backlight
rules of a laptop.

### Profiles

A **profile** picks modules, scopes and package groups.

It never names a distribution, so the same `laptop` profile holds on Arch and on
Ubuntu. Only the directory the package lists are read from changes.

| Profile | For what | `system:` scopes |
|---|---|---|
| `minimal` | Server, VM, machine you pass through. No graphical session. | none |
| `desktop` | Tower running dwm. No battery, backlight, touchpad or lid. | x11-dwm, peripherals, backup, sync |
| `gnome` | Tower on the desktop its distribution ships (GNOME on Ubuntu). No dwm. | peripherals, sync |
| `laptop` | Laptop running dwm. | laptop, x11-dwm, peripherals, backup, sync |
| `full` | Everything: development, XFCE, Hyprland, virtualisation. | laptop, x11-dwm, peripherals, backup, sync |

`common` and the detected distribution are always added, so no profile repeats
them.

A profile may also carry `steps:` to override the `dot bootstrap` chain. That is
how `minimal` drops `build-suckless` and `fonts` from its own.

`services:` lists the systemd units the profile needs, `ly@tty2` and
`NetworkManager` first, so a new machine reboots to a login screen with the
network up. `dot services` enables them one by one and skips any that is not
installed, since ly for instance does not exist on Ubuntu.

---

## Everyday use

Three commands cover almost everything.

- **`dot adopt <path> [module]`** brings a new file under control. It moves the
  file into the module and links it back, so there is nothing to run afterwards.
  Without the module it asks.
- **`dot sync`** picks up what lives outside `$HOME`, `/etc` into `system/`, the
  AUR list, `system/state.md`, then `git add -A`. The commit stays yours.
- **`dot link`** repairs. Run it after a `git pull` and for anything `dot status`
  calls missing, blocked or broken. It backs up whatever it replaces.

Editing a file the repo already tracks needs **no command at all**: the path in
`$HOME` is a link into the repo, so your editor writes straight into it.

`dot status` reports drift of links, `system/` against the root filesystem,
uncatalogued packages, and it rejects any sensitive file that reaches the index.

> **`man dot`**, section **EXAMPLES**, has the situation to command table.
> Section **READING DOT STATUS** explains every verdict and its fix.

---

## Install on Arch

From a base Arch install, with a user created and the network working.

### 1. Prerequisites

```sh
sudo pacman -S --needed git base-devel
```

Then the AUR helper and the tools outside pacman, see
**[packages/arch/manual.md](packages/arch/manual.md)**. Install `paru` at minimum,
otherwise `dot install` skips the 53 AUR packages.

### 2. Clone and bootstrap

```sh
git clone --recursive git@github.com:noforest/dotfiles.git \
    ~/Documents/programming/github-noforest/dotfiles
cd ~/Documents/programming/github-noforest/dotfiles

./dot status      # check what it takes this machine to be
./dot bootstrap   # it prints the profile and asks before touching anything
```

`--recursive` matters, the nvim `codediff` plugin is a submodule. If you forgot
it: `git submodule update --init --recursive`.

### 3. After the bootstrap

The bootstrap already made zsh the login shell, enabled the system services of the profile (`ly@tty2`,
`NetworkManager`…) and installed the nvim plugins. What is left needs you.
`system/state.md` records the reference state of the original machine.

```sh
sudo usermod -aG docker "$USER"                    # plus vboxusers on the full profile
pyenv install 3.11.11                              # the Python .zshrc puts on the PATH

rclone config                                      # create the gdrive: remote, backup_gdrive.timer needs it
systemctl --user enable --now pipewire pipewire-pulse wireplumber \
                              ssh-agent.socket backup_gdrive.timer

reboot                                             # ly, udev rules and groups take effect
```

On a laptop, also install auto-cpufreq, see
[packages/arch/manual.md](packages/arch/manual.md).

To share `~/sync-enseirb` with the other machines, see [Shared folder](#shared-folder).

Then see [Machine specific settings](#machine-specific-settings).

---

## Install on Ubuntu

From a fresh Ubuntu 26.04 LTS, with a user created and the network working.

### 1. Get rid of snap and the adverts

Do this first, before you need a browser. No package in `packages/ubuntu/`
installs a snap, every name was checked against the archive index and the
transitional packages that only pull a snap (`firefox`, `chromium-browser`,
`thunderbird`) are left out on purpose. But Ubuntu ships snapd already installed.

```sh
sudo apt install -y git build-essential
git clone --recursive git@github.com:noforest/dotfiles.git \
    ~/Documents/programming/github-noforest/dotfiles
cd ~/Documents/programming/github-noforest/dotfiles

./scripts/ubuntu-remove-snap.sh --list    # what you would lose, with replacements
./scripts/ubuntu-install-firefox-deb.sh   # real Firefox deb from Mozilla
./scripts/ubuntu-remove-snap.sh           # purges snapd, blocks it in apt
./scripts/ubuntu-no-ads-no-telemetry.sh   # Ubuntu Pro adverts, APT News, MOTD, reporting
```

`--list` removes nothing. It prints every installed snap with a suggested non-snap
replacement, so you can install what you need before losing it.

### 2. Read what apt cannot give you

**[packages/ubuntu/manual.md](packages/ubuntu/manual.md)**, before the bootstrap.
Three things matter:

- Debian renames two binaries. `bat` installs `batcat` and `fd-find` installs
  `fdfind`, while `.zshrc` calls them by their upstream name. `dot install` links them in `~/.local/bin`.
- `clipster`, `libinput-gestures` and `xidlehook` are called by `.xinitrc` and are
  not packaged. The session starts without them, minus clipboard and gestures.
- `ly` is not packaged either. Use `lightdm`, or build ly from source.

### 3. Bootstrap

```sh
echo gnome > machine.d/$(hostname).conf   # GNOME stays, no dwm
./dot status      # expect "distro ubuntu" and "profile gnome"
./dot bootstrap
```

### 4. After the bootstrap

The bootstrap already made zsh the login shell (`dot login-shell`).

```sh
systemctl --user enable --now pipewire pipewire-pulse wireplumber ssh-agent.socket
reboot
```

The bootstrap enables NetworkManager and skips ly, which Ubuntu does not package.
The display manager Ubuntu installed (gdm3, or lightdm) stays in charge.

To share `~/sync-enseirb` with the other machines, see [Shared folder](#shared-folder).
It needs a newer rclone than apt provides, see
[packages/ubuntu/manual.md](packages/ubuntu/manual.md).

Then see [Machine specific settings](#machine-specific-settings).

`packages/ubuntu/` has no `dev.txt` nor `extra.txt` yet, so the `full` profile
installs only partially there, silently.

---

## Machine specific settings

Five files, and that is all that stays machine specific.

| File | What it holds | Template |
|---|---|---|
| `machine.d/<hostname>.conf` | One line, the profile this machine defaults to. Optional, the chassis is used otherwise, but it turns a guess into a decision. Not versioned. | [`machine.d/README.md`](machine.d/README.md) |
| `~/.gitconfig-local` | Git identity and per account routing. Without it git has no author and refuses to commit. | [`examples/gitconfig-local`](examples/gitconfig-local) |
| `~/.zshrc.local` | Project paths and local variables. Sourced at the end of `.zshrc`. | [`examples/zshrc.local`](examples/zshrc.local) |
| `~/.config/atuin/config.toml` | Shell history settings. Kept out of git because it can hold sync credentials. | [`examples/atuin-config.toml`](examples/atuin-config.toml) |
| `modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh` | xinput identifiers. Names like `"ELAN2204:00 04F3:3109 Touchpad"` hold for one laptop only. | copy `archlinux.sh`, then `xinput list` |

The two `~/.*local` files live in `$HOME`, neither linked nor versioned. Without
the xinput file nothing is loaded and the session still starts.

---

## Shared folder

`~/sync-enseirb` is the same folder on every machine, kept in step through Google Drive
by `sync-gdrive-enseirb` (`rclone bisync`). Drive is only the meeting point, so the
machines never need to be switched on together.

```sh
rclone config                      # once per machine: a remote named gdrive-enseirb
sync-gdrive-enseirb --dry-run      # what the first run would do
sync-gdrive-enseirb                # the first run merges both sides, it deletes nothing
systemctl --user enable --now sync-gdrive-enseirb.timer sync-gdrive-enseirb-logout.service
```

It then runs at login, every ten minutes and at logout. Run `sync-gdrive-enseirb` by hand
before leaving a machine if the last edit is less than ten minutes old.

- **Only a whitelist of extensions travels**, each file capped at 20 MB: code,
  notebooks, documents, configuration, small csv and figures. Virtual
  environments, model weights, datasets and build output stay where they are.
  The list is `/etc/sync-gdrive-enseirb/filters`.
- **A file edited on two machines between two runs** is kept twice: the newer one
  under its name, the other one as `notes.conflict1.md`.
- **What a sync deletes or overwrites locally** goes to
  `~/.local/share/sync-gdrive-enseirb/trash`, and to the Google bin on the Drive side.
  A run that would delete more than half of a side stops and asks for
  `sync-gdrive-enseirb --force`.
- **This is not the backup.** `backup-to-gdrive.sh` mirrors `~/Documents` one way
  into `gdrive:_BackupsLinux/<host>`. The two share no folder, local or remote.

[`examples/sync-gdrive-enseirb.config`](examples/sync-gdrive-enseirb.config) lists the overrides.

---

## Adding a graphical environment

Several environments can be installed side by side and picked at login. `dot` has
no built-in list of window managers, so adding one is a matter of creating
directories, not of editing code.

Adding sway, for example:

1. **`modules/sway/`** holds what goes into `$HOME`.
   `modules/sway/.config/sway/config` will be linked to `~/.config/sway/config`.
2. **`system/sway/root/`** holds what goes outside it, usually just a session
   entry such as `/usr/share/wayland-sessions/sway.desktop` so the login screen
   offers the choice. Skip this directory if the package already ships one.
3. **Name both in a profile**: `sway` on a line of its own for the module, and
   `sway` appended to the `system:` line for the scope.

Then `dot link` and `dot system-apply`. The login manager does the rest: ly scans
`/usr/share/xsessions` and `/usr/share/wayland-sessions`, lists what it finds, and
records your last choice in `/etc/ly/save.txt`. Nothing in this repository needs
to know which one you picked.

Three traps:

- **Two modules may not claim the same path.** `.Xresources`, `.Xmodmap` and
  `.xserverrc` are shared by every X11 environment, so they live in
  `modules/x11-common/`, which both dwm and the newcomer list as a dependency.
  Copy them into your new module instead and `dot link` refuses to run at all,
  naming both culprits.
- **`.xinitrc` belongs to one environment, not to all of them.** It ends with
  `exec dwm`, so it stays in `modules/x11-dwm/`. A Wayland compositor never reads
  it at all.
- **XFCE cannot be fully versioned.** `.config/xfce4/xfconf/` is a store that
  xfconfd rewrites and watches through inotify, so `NEVER_LINK` refuses it and
  `dot link` says so rather than corrupting it.

---

## Design choices

**One repository, not one per machine.** `shell`, `git`, `nvim`, `vim` and
`terminal` are identical everywhere and are most of the value here. Splitting them would guarantee
they drift apart and mean maintaining `dot` twice.

**`system/` is split by scope, not by distribution.** The distribution is one axis
among several, and not the one that hurt first: a tower used to receive the
touchpad, backlight and lid rules of a laptop.

**The machine is detected, the profile is declared.** A machine knows what it runs,
so a second source of truth would eventually disagree. The profile is a choice, so
it is declared, and `dot status` always says where it came from.

**Modules may not overlap.** `dot link` refuses before writing anything and names
both culprits, because the alternative is linking the last one silently and
reporting `link points elsewhere` forever afterwards.

**Symlinks for `$HOME`, copies for the root filesystem.** `/etc/udev/rules.d` and
`/etc/ly/config.ini` are read at boot before `/home` is necessarily mounted, so a
link into the repository would break the boot.

**Sources are linked, build trees are not.** `suckless/` is compiled in place
rather than linked file by file, because `patch` refuses to touch a symlink and
`sed -i` silently replaces one.

**Scripts run by root are user agnostic.** Those called by udev, acpid or systemd
source `/usr/local/bin/desktop-env.sh`, which finds the active session instead of
hardcoding a home directory. It cannot carry the logind session, which is why
suspending from acpid needs a polkit rule.

**The nvim plugins are patched only where their API cannot reach.** Customisations
go through the API each plugin provides, because patches against third party code
rot at the first update. One line of snacks.nvim is the exception, its patch header
says why, and `dot nvim-patch` reports when upstream moved.

**`codediff` is a separate repo.** It is a real project (C and Lua, CMake, tests),
not a configuration file, so it is a submodule with a relative URL.

**No binaries.** The suckless executables are rebuilt by `dot build-suckless`, the
fonts come from the package lists or from `dot fonts`. Around 10 MB instead of the
36 MB of the previous version.
