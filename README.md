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
| `desktop` | Tower running dwm. No battery, backlight, touchpad or lid. | x11-dwm, peripherals |
| `laptop` | Laptop running dwm. | laptop, x11-dwm, peripherals |
| `full` | Everything: development, XFCE, Hyprland, virtualisation. | laptop, x11-dwm, peripherals |

`common` and the detected distribution are always added, so no profile repeats
them.

A profile may also carry `steps:` to override the `dot bootstrap` chain. That is
how `minimal` drops `build-suckless` and `fonts` from its own.

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

Steps the repo does not replay by itself. `system/state.md` records the reference
state of the original machine.

```sh
chsh -s /bin/zsh                                   # default shell
sudo usermod -aG docker,vboxusers "$USER"          # groups, compare with system/state.md

sudo systemctl enable --now ly NetworkManager acpid docker cups auto-cpufreq
systemctl --user enable --now pipewire pipewire-pulse wireplumber \
                              ssh-agent.socket lock.service backup_gdrive.timer

sudo udevadm control --reload && sudo udevadm trigger   # reload what system-apply installed
sudo systemctl daemon-reload
nvim --headless "+Lazy! sync" +qa                       # nvim plugins
```

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
  `fdfind`, while `.zshrc` calls them by their upstream name. Two symlinks fix it.
- `clipster`, `libinput-gestures` and `xidlehook` are called by `.xinitrc` and are
  not packaged. The session starts without them, minus clipboard and gestures.
- `ly` is not packaged either. Use `lightdm`, or build ly from source.

### 3. Bootstrap

```sh
./dot status      # expect "distro ubuntu" and "profile desktop (from chassis)"
./dot bootstrap
```

### 4. After the bootstrap

```sh
chsh -s /bin/zsh
sudo usermod -aG docker "$USER"

sudo systemctl enable --now lightdm NetworkManager acpid    # adapt to what you installed
systemctl --user enable --now pipewire pipewire-pulse wireplumber ssh-agent.socket

sudo udevadm control --reload && sudo udevadm trigger
sudo systemctl daemon-reload
nvim --headless "+Lazy! sync" +qa
```

Then see [Machine specific settings](#machine-specific-settings).

`packages/ubuntu/` has no `dev.txt` nor `extra.txt` yet, so the `full` profile
installs only partially there, silently.

---

## Machine specific settings

Four files, and that is all that stays machine specific.

| File | What it holds | Template |
|---|---|---|
| `machine.d/<hostname>.conf` | One line, the profile this machine defaults to. Optional, the chassis is used otherwise, but it turns a guess into a decision. Not versioned. | [`machine.d/README.md`](machine.d/README.md) |
| `~/.gitconfig-local` | Git identity and per account routing. Without it git has no author and refuses to commit. | [`examples/gitconfig-local`](examples/gitconfig-local) |
| `~/.zshrc.local` | Project paths and local variables. Sourced at the end of `.zshrc`. | [`examples/zshrc.local`](examples/zshrc.local) |
| `modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh` | xinput identifiers. Names like `"ELAN2204:00 04F3:3109 Touchpad"` hold for one laptop only. | copy `archlinux.sh`, then `xinput list` |

The two `~/.*local` files live in `$HOME`, neither linked nor versioned. Without
the xinput file nothing is loaded and the session still starts.

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

**One repository, not one per machine.** `shell`, `git`, `nvim` and `terminal` are
identical everywhere and are most of the value here. Splitting them would guarantee
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
`sed -i` silently replaces one. `~/Suckless` is a single directory symlink into the
repository, so old habits land in the right tree.

**Scripts run by root are user agnostic.** Those called by udev, acpid or systemd
source `/usr/local/bin/desktop-env.sh`, which finds the active session instead of
hardcoding a home directory. It cannot carry the logind session, which is why
suspending from acpid needs a polkit rule.

**The nvim plugins are not patched.** Customisations go through the API each plugin
provides. Patches against third party code rot silently at the first update.

**`codediff` is a separate repo.** It is a real project (C and Lua, CMake, tests),
not a configuration file, so it is a submodule with a relative URL.

**No binaries.** The suckless executables are rebuilt by `dot build-suckless`, the
fonts come from the package lists or from `dot fonts`. Around 10 MB instead of the
36 MB of the previous version.
