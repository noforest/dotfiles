# dotfiles

My Linux environment: configs, scripts, suckless patches, package lists. Install a
bare machine and get the same setup back without doing it all by hand.

One repository for several machines.

- **the distribution** comes from `/etc/os-release` and picks the package lists
  and one of the `system/` scopes,
- **the machine** (tower or laptop) comes from its chassis and picks the profile,
- **the graphical environment** is a module plus a scope, so several of them can
  live side by side and be chosen at login.

Tested on Arch Linux with dwm. Ubuntu 26.04 LTS is supported, its package lists
checked name by name against the official archive.

## Contents

- [How it works](#how-it-works)
- [Everyday use](#everyday-use)
- [All the commands](#all-the-commands)
- [Install on Arch](#install-on-arch)
- [Install on Ubuntu](#install-on-ubuntu)
- [Machine specific settings](#machine-specific-settings)
- [Adding a graphical environment](#adding-a-graphical-environment)
- [Design choices](#design-choices)

---

## How it works

| Directory | Contents |
|---|---|
| `dot` | The CLI. Everything goes through it. |
| `modules/` | What goes into `$HOME`, by theme. `modules/shell/.zshrc` maps to `~/.zshrc`. |
| `system/<scope>/root/` | What goes outside `$HOME`. `system/common/root/etc/x` maps to `/etc/x`. |
| `packages/<distro>/` | Package lists per group, one directory per distribution. |
| `profiles/` | Combinations of modules, scopes and package groups. |
| `machine.d/` | Which profile each machine defaults to. Not versioned. |
| `suckless/` | Patched sources of dwm, st, dmenu, slock, dwmblocks. No binaries. |
| `examples/` | Templates for local files that are never versioned. |
| `scripts/` | One-off tools, including the Ubuntu cleanup scripts. |

A **scope** is a reason to deploy a file: `common`, the distribution (`arch`,
`ubuntu`), the hardware (`laptop`, `peripherals`), the graphical environment
(`x11-dwm`, `hyprland`). Splitting them is what keeps a tower from receiving the
touchpad and backlight rules of a laptop.

A **profile** answers three questions on three lines: which modules go into
`$HOME`, which `system:` scopes go outside it, which `packages:` groups to
install. It never names a distribution, so the same `laptop` profile holds on
Arch and on Ubuntu. Only the directory the groups are read from changes.

| Profile | For what | `system:` scopes |
|---|---|---|
| `minimal` | Server, VM, machine you pass through. No graphical session. | none |
| `desktop` | Tower running dwm. No battery, backlight, touchpad or lid. | x11-dwm, peripherals |
| `laptop` | Laptop running dwm. The profile of this machine. | laptop, x11-dwm, peripherals |
| `full` | Everything: development, XFCE, Hyprland, virtualisation. | laptop, x11-dwm, peripherals |

`common` and the detected distribution are always added, so no profile repeats
them. A profile may also carry `steps:`, the chain `dot bootstrap` runs. Without
it the default chain applies, which compiles the suckless tools, so `minimal`
cuts `build-suckless` and `fonts` out of its own.

---

## Everyday use

```sh
dot status              # what moved?
dot adopt ~/.config/mpv/mpv.conf desktop   # bring a file into the repo
dot sync                # regenerate lists and state, then git add -A
git commit -m "..."
```

`dot adopt` is the one command to remember. It moves the file into the module and
replaces it with a symlink, so editing `~/.config/mpv/mpv.conf` edits the repo
directly. Given a directory it adopts every file inside one at a time, leaving the
directory itself real in `$HOME`. Nested git repositories, symlinks and daemon
state are skipped and reported.

Leave the module out and it asks, showing which profiles each module reaches. A
file lives in exactly one module, and the module decides which profiles carry it.

`dot status` opens by stating what it takes the machine to be, because everything
below is scoped by it. A profile that was guessed rather than chosen says so:

```
== machine =====================================================
  host    archlinux, chassis laptop
  distro  arch
  profile laptop (from chassis)
```

It then reports broken links, unlinked files, divergences between `system/` and
the root filesystem, packages installed but not catalogued, and it **rejects any
sensitive file** that reaches the index. SSH and GPG keys, `rclone.conf`,
`atuin/config.toml`, `.npmrc`, `gh/hosts.yml` and `solaar/config.yaml` are
excluded by `.gitignore` and checked on every run.

A divergence names both paths, the system one and the repository one, since
several scopes deploy into the same tree. Files under a directory only root may
read are reported as unverifiable rather than missing, and `sudo -v` before
`dot status` settles them.

### All the commands

| Command | Effect |
|---|---|
| `dot link [profile]` | Create the links. Backs up what was there as `.bak-<date>`. Idempotent. |
| `dot unlink [profile]` | Remove the links it created, keeping the `.bak` files. |
| `dot list [profile]` | List the managed paths. |
| `dot adopt <path> [module]` | Bring a file or directory from `$HOME` into a module. |
| `dot status [profile]` | Full drift report. `dot st` for short. |
| `dot sync` | Regenerate what is generated, then `git add -A`. |
| `dot install [profile]` | Install the packages with the detected distribution's manager. |
| `dot system-apply [profile]` | Copy the profile scopes of `system/` to the root filesystem (sudo). |
| `dot system-pull [profile]` | Pull back into the repo whatever changed on the system. |
| `dot build-suckless` | Build and install the five suckless projects. |
| `dot fonts` | Fetch the fonts that live outside the repositories. |
| `dot audit [packages\|scripts]` | What this machine actually uses. Arch only. |
| `dot state` | Regenerate `system/state.md`. |
| `dot bootstrap [profile]` | Chain everything. Asks for confirmation if nothing chose the profile. |

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

- **`machine.d/<hostname>.conf`**, one line, the profile this machine defaults to.
  Optional, since the chassis is used otherwise, but it turns a guess into a
  decision. Not versioned, see [`machine.d/README.md`](machine.d/README.md).

- **`~/.dmrc`**, which session the display manager starts by default. Template:
  [`examples/dmrc`](examples/dmrc). Machine specific by nature once several
  graphical environments are installed side by side.

- **`~/.gitconfig-local`**, the git identity and per account routing. Template:
  [`examples/gitconfig-local`](examples/gitconfig-local). Lives in `$HOME`,
  neither linked nor versioned, included by `~/.gitconfig`. Without it git has no
  author and refuses to commit.

- **`~/.zshrc.local`**, project paths and local variables. Template:
  [`examples/zshrc.local`](examples/zshrc.local). Sourced at the end of `.zshrc`.

- **`modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh`**, xinput identifiers.
  Names like `"ELAN2204:00 04F3:3109 Touchpad"` hold for one laptop only. Copy
  `archlinux.sh` under the new hostname and replace them using `xinput list`.
  Without the file nothing is loaded and the session still starts.

---

## Adding a graphical environment

Nothing in `dot` knows the list of window managers, so adding sway, Hyprland or
XFCE is data, not code:

1. `modules/<wm>/` for what goes into `$HOME`. Anything shared with another X11
   environment (`.Xresources`, `.Xmodmap`, `.xserverrc`) already lives in
   `modules/x11-common/`. Depend on it rather than copying, or `dot link` refuses
   both modules for claiming the same path.
2. `system/<wm>/root/` if it needs anything outside `$HOME`, such as a session
   entry in `/usr/share/xsessions`. Optional.
3. Name both in a profile: the module on its own line, the scope on `system:`.

Several environments can be installed side by side and picked at login. Their
modules are linked together, and `~/.dmrc` records the default session.

Two things to know before writing an XFCE module: `.config/xfce4/xfconf/` is
refused by `NEVER_LINK` because xfconfd rewrites it and watches it through
inotify, and `.xinitrc` belongs to the environment it starts, so it stays in
`modules/x11-dwm/` rather than in `x11-common`.

---

## Design choices

**One repository, not one per machine.** `shell`, `git`, `nvim` and `terminal`
(zsh, p10k, tmux, nvim) are identical everywhere and are most of the value here.
Splitting them would guarantee they drift apart and mean maintaining `dot` twice.
What actually differs is narrow: package names, a handful of files under `/etc`.

**`system/` is split by scope, not by distribution.** The distribution is only one
axis among several, and not the one that hurt first. A tower used to receive the
touchpad, backlight and lid rules of a laptop because `system/root/` was deployed
whole. Scope names are free, `dot` never enumerates them, so adding `sway` is a
directory plus a line in a profile.

**The machine is detected, the profile is declared.** The distribution comes from
`/etc/os-release` and is never written in a profile, since a machine knows what it
runs and a second source of truth would eventually disagree. The profile is the
opposite, being a choice, so it is read from `machine.d/<hostname>.conf`, falls
back to the chassis, and `dot status` always says which of the two it used.

**Modules may not overlap.** Several graphical environments are linked side by
side, so nothing stops two of them from shipping the same `~/.something`.
`dot link` refuses before writing anything and names both modules, because the
alternative is linking the last one silently and reporting `link points elsewhere`
forever afterwards.

**Symlinks for `$HOME`, copies for the root filesystem.** `/etc/udev/rules.d` and
`/etc/ly/config.ini` are read very early at boot, before `/home` is necessarily
mounted, so a link into the repo would break the boot. Hence `system-apply` and
`system-pull`, plus the divergence report in `dot status`.

**Scripts run by root are user agnostic.** Those called by udev, acpid or systemd
source `/usr/local/bin/desktop-env.sh`, which finds the active graphical session
and derives `USER_HOME`, `DISPLAY` and `XAUTHORITY` from it instead of hardcoding
a home directory. What it cannot carry is the logind session, which is why
suspending from an acpid-launched process needs a polkit rule
(`system/laptop/root/etc/polkit-1/rules.d/`).

**The nvim plugins are not patched.** Customisations go through the API each
plugin provides, in `lazy.lua`. A dotfiles repo should not carry patches against
third party code, they rot silently at the first upstream update. Here
`:Lazy update` can no longer break anything.

**`codediff` is a separate repo.** It is a real project (C and Lua, CMake, tests),
not a configuration file. It is a submodule with a relative URL
(`../codediff.nvim.git`), which resolves to the same GitHub account as this repo.

**No binaries.** The suckless executables are rebuilt by `dot build-suckless`, the
fonts come from the package lists or from `dot fonts`. The repo weighs around
10 MB instead of the 36 MB of the previous version.
