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

One repository, several machines. Three things are detected rather than declared:
**the distribution** from `/etc/os-release`, which picks the package lists and one
`system/` scope, **the machine** from its chassis, which picks the profile, and
**the graphical environment**, a module plus a scope, so several can coexist and be
chosen at login.

Tested on Arch with dwm. Ubuntu 26.04 LTS is supported, its package lists checked
name by name against the official archive.

> **`man dot`** is the reference: every command, and how to read every line of
> `dot status`. This README covers installing and the reasoning.

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

| Directory | Contents | Deployed as |
|---|---|---|
| `modules/` | What goes into `$HOME`. `modules/shell/.zshrc` maps to `~/.zshrc`. | symlinks |
| `system/<scope>/root/` | What goes outside it. `system/common/root/etc/x` maps to `/etc/x`. | copies |
| `packages/<distro>/` | Package lists per group. | installed |
| `suckless/` | Patched sources of dwm, st, dmenu, slock, dwmblocks. | compiled in place |

Plus `profiles/` (which of the above go together), `machine.d/` (the profile a
machine defaults to, not versioned), `examples/` (templates for local files that
are never versioned) and `scripts/`.

A **scope** is a reason to deploy a file: `common`, the distribution, the hardware,
the graphical environment. Splitting them keeps a tower from receiving the touchpad
and backlight rules of a laptop. A **profile** picks modules, scopes and package
groups, and never names a distribution, so the same `laptop` profile holds on Arch
and on Ubuntu.

| Profile | For what | `system:` scopes |
|---|---|---|
| `minimal` | Server, VM, machine you pass through. No graphical session. | none |
| `desktop` | Tower running dwm. No battery, backlight, touchpad or lid. | x11-dwm, peripherals |
| `laptop` | Laptop running dwm. | laptop, x11-dwm, peripherals |
| `full` | Everything: development, XFCE, Hyprland, virtualisation. | laptop, x11-dwm, peripherals |

`common` and the detected distribution are always added. A profile may carry
`steps:` to override the `dot bootstrap` chain, which is how `minimal` drops
`build-suckless` and `fonts`.

---

## Everyday use

| Situation | What to run |
|---|---|
| Editing a file the repo already tracks | **Nothing.** The path in `$HOME` is a link into the repo, so your editor writes straight into it. Commit when done. |
| A new config file worth keeping | `dot adopt <path> [module]`. It moves the file into the module and links it back, so nothing else is needed. Without the module it asks. |
| Picking up what lives outside `$HOME` | `dot sync`. Pulls `/etc` into `system/`, refreshes the AUR list and `system/state.md`, then `git add -A`. The commit stays yours. |
| After a `git pull`, or anything `dot status` calls missing, blocked or broken | `dot link`. Backs up whatever it replaces as `.bak-<date>`. |
| A brand new machine | `dot bootstrap`. See the install sections below. |

`dot status` reports drift of links, `system/` against the root filesystem,
uncatalogued packages, and it rejects any sensitive file that reaches the index.
Each section prints the direction it compares in. `dot help` lists every command,
`man dot` explains them and every verdict `dot status` can print.

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

Five files, and that is all that stays machine specific.

| File | What it holds | Template |
|---|---|---|
| `machine.d/<hostname>.conf` | One line, the profile this machine defaults to. Optional, the chassis is used otherwise, but it turns a guess into a decision. Not versioned. | [`machine.d/README.md`](machine.d/README.md) |
| `~/.dmrc` | Which session the display manager starts by default. | [`examples/dmrc`](examples/dmrc) |
| `~/.gitconfig-local` | Git identity and per account routing. Without it git has no author and refuses to commit. | [`examples/gitconfig-local`](examples/gitconfig-local) |
| `~/.zshrc.local` | Project paths and local variables. Sourced at the end of `.zshrc`. | [`examples/zshrc.local`](examples/zshrc.local) |
| `modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh` | xinput identifiers. Names like `"ELAN2204:00 04F3:3109 Touchpad"` hold for one laptop only. | copy `archlinux.sh`, then `xinput list` |

The middle three live in `$HOME`, neither linked nor versioned. Without the xinput
file nothing is loaded and the session still starts.

---

## Adding a graphical environment

Nothing in `dot` knows the list of window managers, so adding sway, Hyprland or
XFCE is data, not code:

1. `modules/<wm>/` for what goes into `$HOME`.
2. `system/<wm>/root/` if it needs anything outside it, such as a session entry in
   `/usr/share/xsessions`. Optional.
3. Name both in a profile: the module on its own line, the scope on `system:`.

Several environments can be installed side by side and picked at login, with
`~/.dmrc` recording the default. Three traps:

- Anything shared with another X11 environment (`.Xresources`, `.Xmodmap`,
  `.xserverrc`) already lives in `modules/x11-common/`. Depend on it rather than
  copying, or `dot link` refuses both modules for claiming the same path.
- `.config/xfce4/xfconf/` is refused by `NEVER_LINK`, because xfconfd rewrites it
  and watches it through inotify.
- `.xinitrc` belongs to the environment it starts, so it stays in `modules/x11-dwm/`.

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
