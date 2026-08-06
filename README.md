# dotfiles

My Linux environment: configs, scripts, suckless patches, package lists. The goal
is to install a bare machine and get the same experience back without doing it all
by hand.

One repository for several machines. What varies is expressed as **data**, never as
a fork:

- **the distribution** is detected from `/etc/os-release` and selects the package
  lists (`packages/arch/`, `packages/ubuntu/`) and one of the `system/` scopes,
- **the machine** (tower or laptop) comes from its chassis and picks the profile,
- **the graphical environment** is a module plus a scope, so several of them can be
  installed side by side and chosen at login.

Reference machine: Arch Linux with dwm. Ubuntu 26.04 LTS is supported, its package
lists checked against the official archive.

```
git clone --recursive git@github.com:noforest/dotfiles.git \
    ~/Documents/programming/github-noforest/dotfiles
cd ~/Documents/programming/github-noforest/dotfiles
./dot bootstrap          # the profile comes from the chassis, or name it: ./dot bootstrap laptop
```

---

## Layout

| Directory | Contents |
|---|---|
| `dot` | The CLI. Everything goes through it. |
| `modules/` | What goes into `$HOME`, grouped by theme. `modules/shell/.zshrc` maps to `~/.zshrc`. |
| `system/<scope>/root/` | What goes outside `$HOME`. Mirrors the root tree: `system/common/root/etc/x` maps to `/etc/x`. A scope is a reason to deploy a file (`common`, the distribution `arch` or `ubuntu`, the hardware `laptop` or `peripherals`, the graphical environment `x11-dwm` or `hyprland`), and a profile declares the ones it wants on its `system:` line. |
| `machine.d/` | Which profile each machine defaults to. Not versioned, see its README. |
| `suckless/` | Patched sources of dwm, st, dmenu, slock, dwmblocks. **No binaries.** |
| `packages/<distro>/` | Package lists per group, one directory per distribution, plus `manual.md` for what the package manager does not carry. |
| `profiles/` | Combinations of modules, `system/` scopes and package groups. |
| `examples/` | Templates for local files that are never versioned. |

### Profiles

A profile answers three questions on three lines: which **modules** go into
`$HOME` (one name per line), which **`system:` scopes** go outside it, and which
**`packages:` groups** to install. It never names a distribution. The same
`laptop` profile is meant to hold on Arch and on Ubuntu, only the directory the
groups are read from changes.

| Profile | For what | `system:` scopes | Extra modules |
|---|---|---|---|
| `minimal` | Server, VM, machine you pass through. Terminal and editor, no graphical session. | none | shell, git, nvim |
| `desktop` | **Tower running dwm.** Like `laptop` without battery, backlight, touchpad, gestures or lid suspend. | x11-dwm, peripherals | + terminal, x11-common, x11-dwm, desktop |
| `laptop` | **Laptop running dwm**, the profile of this machine. | laptop, x11-dwm, peripherals | + laptop |
| `full` | Everything: development, XFCE, Hyprland, security, virtualisation. | laptop, x11-dwm, peripherals | + dev |

`common` and the detected distribution are always added to the `system:` line, so
no profile has to repeat them.

A profile may also carry `steps:`, the chain `dot bootstrap` runs. Without it the
default chain applies, which compiles the suckless tools. That is why `minimal`
cuts `build-suckless` and `fonts` out of its own.

`full` is not meant to be installed on a fresh machine. It is the safety net that
guarantees nothing present here gets lost. For a real machine, take `desktop` or
`laptop`. Run `dot audit` to see what a machine actually uses before replicating it.

---

## Everyday use

```sh
dot status              # what moved?
dot adopt ~/.config/mpv/mpv.conf desktop   # bring a file into the repo
dot adopt ~/.config/mpv           # a whole directory, module picked from a menu
dot sync                # regenerate lists, patches and state, then git add -A
git commit -m "..."
```

`dot adopt` is the one command to remember. It moves the file into the module and
replaces it with a symlink. Once adopted, editing `~/.config/mpv/mpv.conf` edits the
repo directly. There is nothing left to copy.

Given a directory, it adopts every file inside it one at a time, leaving the directory
itself a real directory in `$HOME` holding the symlinks. That is on purpose: a module is
linked file by file, so a directory-wide symlink would make the next `dot link` collide
with itself. Nested git repositories, symlinks and daemon state are skipped and reported.

Leave the module out and `dot adopt` asks, showing which profiles each module reaches:

```
      MODULE     PROFILES
  1)  desktop    desktop laptop full
  2)  dev        full
  3)  git        minimal desktop laptop full
  ...
```

A file lives in exactly one module, and the module is what decides which profiles carry
it. To reach `minimal` as well as `laptop`, pick a module that both profiles list.

`dot status` opens by stating what it takes the machine to be: host, distribution,
chassis, and **where the profile comes from**, since everything below is scoped by
it. A profile that was guessed rather than chosen is reported as such:

```
== machine =====================================================
  host    archlinux, chassis laptop
  distro  arch
  profile laptop (from chassis)
```

It then reports broken links, unlinked files, divergences between `system/` and the
root filesystem, packages installed but not catalogued, and it **rejects any
sensitive file** that reaches the index. A divergence names both paths, the system
one and the repository one, because several scopes deploy into the same tree.

### All the commands

| Command | Effect |
|---|---|
| `dot link [profile]` | Create the links. Backs up what was there as `.bak-<date>`. Idempotent. |
| `dot unlink [profile]` | Remove the links it created, keeping the `.bak` files. |
| `dot list [profile]` | List the managed paths. |
| `dot adopt <path> [module]` | Bring a file or a directory from `$HOME` into a module. Asks for the module if omitted. |
| `dot status [profile]` | Full drift report. |
| `dot sync` | Regenerate everything that is generated, then `git add -A`. |
| `dot install [profile]` | Install the profile packages with the package manager of the detected distribution (`pacman` then `paru` on Arch, `apt-get` on Ubuntu). |
| `dot system-apply [profile]` | Copy the scopes of `system/` that the profile declares to the root filesystem (sudo). |
| `dot system-pull [profile]` | Pull back into the repo whatever changed on the system. |
| `dot build-suckless` | Build and install the five suckless projects. |
| `dot fonts` | Fetch the two fonts that live outside the repositories. |
| `dot audit [packages\|scripts]` | What this machine actually uses (shell history plus disk traces). |
| `dot state` | Regenerate `system/state.md`. |
| `dot bootstrap [profile]` | Chain everything, from bare machine to full environment. |

---

## Full reinstall

Starting from a base install, with a user created and the network working.

### 1. Prerequisites

```sh
sudo pacman -S --needed git base-devel     # Arch
sudo apt install git build-essential       # Ubuntu
```

On Arch, then the AUR helper and the tools outside pacman: see
**[packages/arch/manual.md](packages/arch/manual.md)**. At minimum install `paru`
before going further, otherwise `dot install` skips the 53 AUR packages.

On Ubuntu, read **[packages/ubuntu/manual.md](packages/ubuntu/manual.md)** first.
The lists are filled in for 26.04 LTS, but a few tools called by `.xinitrc` have no
package in the archive, and Debian renames the `bat` and `fd` binaries.

Two scripts to run once on a fresh Ubuntu, before the rest:

```sh
./scripts/ubuntu-remove-snap.sh --list    # what you would lose, with replacements
./scripts/ubuntu-install-firefox-deb.sh   # real Firefox deb from Mozilla
./scripts/ubuntu-remove-snap.sh           # purges snapd, blocks it in apt
./scripts/ubuntu-no-ads-no-telemetry.sh   # Ubuntu Pro adverts, APT News, MOTD news, reporting
```

No package in `packages/ubuntu/` installs a snap. Every name was checked against
the archive index, and the transitional packages whose only job is to pull a snap
(`firefox`, `chromium-browser`, `thunderbird`) are left out on purpose. The first
script deals with the snapd that ships with the distribution itself.

### 2. Clone and bootstrap

```sh
git clone --recursive git@github.com:noforest/dotfiles.git \
    ~/Documents/programming/github-noforest/dotfiles
cd ~/Documents/programming/github-noforest/dotfiles
./dot status             # check what it takes this machine to be, before writing anything
./dot bootstrap
```

`--recursive` matters, because the nvim `codediff` plugin is a submodule.
If you forgot it: `git submodule update --init --recursive`.

Run `dot status` first: it prints the distribution and the profile it inferred.
`bootstrap` writes into `/etc` as root according to that profile, so it is worth
one look. Running `echo <profile> > machine.d/$(hostname).conf` settles it for good.

By default `bootstrap` chains `install`, `link`, `system-apply`, `fonts`,
`build-suckless` and `nvim-patch`. A profile carrying a `steps:` line runs that
chain instead.

### 3. After the bootstrap

These steps touch system state that the repo does not replay automatically.
`system/state.md` records the reference state of the original machine.

```sh
# Default shell
chsh -s /bin/zsh

# Groups (docker, virtualbox and so on, compare with system/state.md)
sudo usermod -aG docker,vboxusers "$USER"

# System services (ly and auto-cpufreq are Arch here, adapt the display manager
# to the distribution, Ubuntu ships gdm3 or lightdm)
sudo systemctl enable --now ly NetworkManager acpid docker cups auto-cpufreq

# User services
systemctl --user enable --now pipewire pipewire-pulse wireplumber \
                              ssh-agent.socket lock.service backup_gdrive.timer

# Reload what system-apply installed
sudo udevadm control --reload && sudo udevadm trigger
sudo systemctl daemon-reload

# nvim plugins
nvim --headless "+Lazy! sync" +qa
```

### 4. Machine specific settings

Five files to adapt. That is all that stays machine specific.

- **`machine.d/<hostname>.conf`**, one line: the profile this machine defaults to.
  Optional, since without it the profile is inferred from the chassis, but it is
  what turns a guess into a decision. Not versioned, see
  [`machine.d/README.md`](machine.d/README.md).

- **`~/.dmrc`**, which session the display manager starts by default. Template:
  [`examples/dmrc`](examples/dmrc). Machine specific by nature once several
  graphical environments are installed side by side.

- **`~/.gitconfig-local`**, the git identity (name, address) and per account routing.
  Template: [`examples/gitconfig-local`](examples/gitconfig-local). It sits outside the
  repo, neither linked nor versioned, and lives in `$HOME`. `~/.gitconfig` includes it.
  Without it, git has no author and refuses to commit.

- **`~/.zshrc.local`**, project paths, local variables, `TD_AUTO_DIRS`.
  Template: [`examples/zshrc.local`](examples/zshrc.local). Not versioned, sourced at the
  end of `.zshrc` if it exists.

- **`modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh`**, xinput identifiers.
  Device names such as `"ELAN2204:00 04F3:3109 Touchpad"` only hold for one given laptop.
  On a new machine, copy `archlinux.sh` under the new hostname and replace the identifiers
  with those from `xinput list`. If the file does not exist, nothing is loaded and the
  session still starts.

---

## Adding a graphical environment

Nothing in `dot` knows the list of window managers, so adding sway, Hyprland or
XFCE is data, not code:

1. `modules/<wm>/` for what goes into `$HOME`. Anything shared with another X11
   environment (`.Xresources`, `.Xmodmap`, `.xserverrc`, `.xprofile_autostart.sh`)
   already lives in `modules/x11-common/`. Depend on it rather than copying, or
   `dot link` will refuse both modules for claiming the same path.
2. `system/<wm>/root/` if it needs anything outside `$HOME` (a session entry in
   `/usr/share/xsessions`, a udev rule). Optional.
3. Name both in a profile: the module on its own line, the scope on the `system:`
   line.

Several environments can be installed side by side and picked at login: their
modules are linked together, and it is `~/.dmrc`, a local file (see
[`examples/dmrc`](examples/dmrc)), that records the default session of a machine.

Two things to know before writing an XFCE module: `.config/xfce4/xfconf/` is
refused by `NEVER_LINK` (xfconfd rewrites it and watches it through inotify, see
*Things to watch*), and `.xinitrc` belongs to the environment it starts, so it
stays in `modules/x11-dwm/` rather than in `x11-common`.

## Design choices

**One repository, not one per machine.** `shell`, `git`, `nvim` and `terminal`
(zsh, p10k, tmux, nvim) are identical everywhere and are most of the value here.
Splitting them across two repositories would guarantee they drift apart, and would
mean maintaining `dot` twice. What actually differs is narrow: package names, a
handful of files under `/etc`.

**`system/` is split by scope, not by distribution.** A scope is a *reason* to
deploy a file: `common`, the distribution (`arch`, `ubuntu`), the hardware
(`laptop`, `peripherals`), the graphical environment (`x11-dwm`, `hyprland`). The
distribution is only one axis among them, and not the one that hurt first. A
tower used to receive the touchpad, backlight and lid rules of a laptop because
`system/root/` was deployed whole. Scope names are free: `dot` never enumerates
them, so adding `sway` is a directory plus a line in a profile.

**The machine is detected, the profile is declared.** The distribution comes from
`/etc/os-release` and is never written in a profile: a machine knows what it runs,
and a second source of truth would eventually disagree with the first. The profile
is the opposite, being a choice (`laptop`, `full`, `minimal`), so it is read from
`machine.d/<hostname>.conf`, falls back to the chassis, and `dot status` always
says which of the two it used.

**Modules may not overlap.** Several graphical environments are linked side by
side, so nothing structurally stops two of them from shipping the same
`~/.something`. `dot link` refuses before writing anything and names both modules,
because the alternative is linking the last one silently and reporting `link points
elsewhere` forever afterwards.

**Symlinks for `$HOME`, copies for the root filesystem.** `/etc/udev/rules.d` and
`/etc/ly/config.ini` are read very early at boot, before `/home` is necessarily mounted,
so a link into the repo would break the boot. Hence `system-apply` and `system-pull`,
plus the divergence report in `dot status`.

**The nvim plugins are not patched.** Customisations live in `lazy.lua`, through the
API each plugin provides:

- `snacks`, where the `explorer_cd`, `explorer_up_and_cd`, `select` and `unselect_all`
  actions go through `picker.opts.actions`, which snacks reads **before** its own
  actions. Image preview through chafa overrides `snacks.picker.preview.image` from
  the config.
- `zincoxide`, where the directory notification is a `DirChanged` autocmd (pattern
  `tabpage`, which matches the `tcd` of `behaviour = "tabs"`).
- `catppuccin`, where nothing is left. The change touched the `bufferline` integration,
  a plugin that is **not** installed (`barbar` is the one in use), and a commented line.
  It had no effect at all.

A dotfiles repo should not carry patches against third party code. They rot silently at
the first upstream update. Here, `:Lazy update` can no longer break anything.

**`codediff` is a separate repo.** It is a real project (C and Lua, CMake, tests, 289
files), not a configuration file. It is referenced as a submodule with a *relative* URL
(`../codediff.nvim.git`), which resolves automatically to the same GitHub account as this
repo.

**No binaries.** The suckless executables are rebuilt by `dot build-suckless`, and the
fonts come from pacman (`packages/fonts.txt`) or from `dot fonts`. The repo weighs around
10 MB instead of the 36 MB of the previous version.

**Scripts run by root are user agnostic.** Those called by udev, acpid or systemd source
`/usr/local/bin/desktop-env.sh`, which finds the active graphical session and derives
`USER_HOME`, `DISPLAY` and `XAUTHORITY` from it, instead of hardcoding a home directory.

---

## Things to watch

- **`~/.dotfiles`**, the old *bare* repo, is neither deleted nor modified. It stays as an
  archive, locally and on `git@github.com:noforest/.dotfiles.git`.
- **`~/.local/bin/scripts/`** is not versioned. It held stale copies of the scripts in
  `/usr/local/bin`, which is the only reference called by `.xinitrc`, dwmblocks and dwm.
- **`~/.config/systemd/user/graphical-session.target.wants/xset.service`** is an inherited
  broken link, because its target no longer exists. The setting is taken over by
  `xset-r-rate.service` at the system level, which lives in `system/common/root/`.
- **Secrets**: SSH and GPG keys, `rclone.conf`, `atuin/config.toml`, `.npmrc`,
  `gh/hosts.yml` and `solaar/config.yaml` are excluded by `.gitignore` and checked on
  every `dot status`.
