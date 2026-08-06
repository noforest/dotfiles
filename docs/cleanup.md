# Cleaning up before replicating

The point is to avoid dragging onto future machines what already serves no purpose here.

Run `dot audit` to regenerate the data. This document is the commented reading of it,
done on 2026-08-04 against a history of 88,578 commands.

**Scope:** a snapshot of the Arch laptop, kept as it was written. The package half
is Arch only — `dot audit` needs `pacman -Ql` to map a package to the binaries it
ships, and refuses to run elsewhere. The reasoning transfers to another
distribution, the `pacman -Rsu` commands do not.

---

## How to read the audit (read this before deleting anything)

`dot audit` crosses two signals:

- **the atuin history**, reliable for anything typed in a terminal, and now aware of
  aliases (`alias du="dust -r"` does count as a run of `dust`)
- **the mtime of `~/.config`, `~/.cache`, `~/.local/share`**, the only clue for graphical
  apps, which are started from dmenu and never show up in the shell history

**What the audit cannot see:**

| Case | Example |
|---|---|
| Services and daemons | `ly`, `pipewire`, `grub` are never launched by hand |
| Programs called by a script | `brightnessctl` (through `dunst_brightness.sh`), `maim` (through the screenshot binding) |
| Programs called at shell startup | `vivid` runs every time a terminal opens, from `.zshrc` |
| The shell itself | `zsh` shows up as "1 run, 566 days ago", because it is your login shell |
| Libraries and dependencies | no command to invoke |
| Configs that do not match the package name | `firefox` uses `~/.mozilla`, `bitwarden` uses `~/.config/Bitwarden` |

The audit already excludes a list of known infrastructure, but that list is not
exhaustive. **A line in the audit is a question, not a verdict.**

---

## 1. What can go without hesitation

These are coherent sets, abandoned as a block, not isolated packages. That is what
makes the decision safe.

### Wayland and Hyprland, 16 packages, around 76 MiB

`hyprland hyprlock hyprpicker hyprshot waybar wofi swaync grim slurp wl-clipboard
uwsm ydotool xdg-desktop-portal-hyprland awww python-pywal wlogout`

All last used around **420 days ago**, as one block, which is the Hyprland to dwm
switch. X11 is what runs today, so none of this can be of use. The matching configs
(`.config/hypr`, `waybar`, `wofi`, `swaync`, `wlogout`) were **not** carried over into
the new repo either.

### XFCE, 39 packages, around 42 MiB

Everything `xfce4-*`, plus `xfdesktop` and `xfwm4`. Around thirty panel plugins
(`xfce4-eyes-plugin`, `xfce4-mailwatch-plugin`, `xfce4-smartbookmark-plugin` and so on)
without a single trace of use. dwm is what runs here.

**Two exceptions worth keeping:** `thunar` (bound to a dwm key) and its plugins, plus
`exo`, `garcon`, `tumbler` and `xfconf`, which Thunar depends on.

### lightdm, 3 packages

`lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings`. The login manager in use is
**ly** (`/etc/ly/config.ini` is versioned, `ly.service` is active). Two managers
installed, only one of them used.

### Tools replaced by something else you use

| To remove | Replaced by |
|---|---|
| `emacs` (around 264 MiB) | `neovim` |
| `oh-my-posh` | `starship` (enabled in `.zshrc`) |
| `nano` | `neovim` (`EDITOR=nvim`) |
| `most` | `vimpager` (`PAGER` and `MANPAGER` in `.zshrc`) |
| `ranger`, `nnn` | `yazi` (the `y()` function in `.zshrc`) |
| `arandr`, `lxappearance` | your own `screen_mode` and `screen_menu` scripts |

**Tier 1 total: around 65 packages, around 430 MiB.**

---

## 2. What only you can decide, by testing

Testing one by one is the right approach **for this category only**, not for the first
one. Around fifteen packages, not 377.

Graphical apps without any trace, where there is no informed opinion to give:

`bitwarden` `filezilla` `parole` `mousepad` `xfburn` `qbittorrent` `freedoom`
`dolphin-emu` `fontforge` `handbrake` `duckdb-bin` `librewolf-bin` `qutebrowser`
`torbrowser-launcher` `proton-vpn-gtk-app` `forticlient-vpn` `snake` `neohtop`

And the heavy ones, to keep or not depending on your courses:

| Package | Weight | Question |
|---|---|---|
| `texlive-*` (3 packages) | around 2 GiB | do you still write LaTeX? |
| `virtualbox` and guest-iso | around 267 MiB | when did you last start a VM? |
| `postgresql`, `sqls`, `rainfrog` | n/a | are the database projects over? |
| `nikto`, `gobuster`, `nmap` | n/a | a security course that will come back? |

### How to test without breaking anything

`pacman -Rsu` is reversible, since the package reinstalls from the repositories.

```sh
# 1. Snapshot the current state (safety net)
pacman -Qqe > ~/packages-before-cleanup.txt

# 2. Remove one batch, along with dependencies that became useless
sudo pacman -Rsu emacs nano most ranger nnn

# 3. Live with it for a week.
#    If something is missing:  sudo pacman -S <package>

# 4. Once it holds, update the lists
dot sync && git commit -m "chore: drop unused packages"
```

Do **not** remove everything at once. Go batch by batch, in tier 1 order, leaving a week
between each. A single `pacman -Rsu` across 65 packages makes diagnosis impossible if
something breaks.

---

## 3. What NOT to remove, whatever the audit shows

Checked one by one. These packages **look** unused but are not:

| Package | Why it leaves no trace |
|---|---|
| `zsh` | your login shell, you never type it |
| `vivid` | called by `.zshrc` on every terminal open (`LS_COLORS`) |
| `acpilight` | provides `xbacklight`, bound to a dwm key |
| `brightnessctl` | called by `dunst_brightness.sh` and by ly |
| `maim`, `swappy` | called by `maim_swappy_screenshot.sh` (screenshot key) |
| `flameshot-git` | bound to a dwm key |
| `pavucontrol` | bound to a dwm key |
| `libinput-gestures` | daemon started by `.xinitrc` |
| `fd`, `ripgrep` | called by fzf, telescope and the snacks picker |
| `numlockx`, `xss-lock` | started by `.xinitrc` |
| `dust`, `duf`, `eza`, `bat` | hidden behind your aliases (`du`, `l`, `cat`), which the audit now resolves |
| `ly`, `grub`, `efibootmgr`, `pipewire*` | services and boot |

---

## 4. The scripts in `/usr/local/bin`

`dot audit scripts` splits them three ways: called by a config file, launched by hand,
or orphan.

### Orphans never launched, already dropped from the repo (7)

`black_screen` · `former_screen_dual_focus_on_big_one` ·
`former_screen_dual_focus_on_big_one_force` · `former_screen_duplicate_force` ·
`former_screen_multi` · `former_screen_multi_force` · `former_screen_stop`

No reference anywhere, **zero runs** across 88,578 commands. The `former_` prefix already
says they are stale. `screen_mode` and `screen_menu` replaced them (7 and 1 references in
your configs respectively).

They are gone from the repo, so they are no longer deployed on a new machine. They are
still present in `/usr/local/bin` on this PC, and can go whenever you want:

```sh
sudo rm /usr/local/bin/{black_screen,former_screen_*}
```

### Orphans with residual use, your call (5)

| Script | Use | Note |
|---|---|---|
| `on_ducky_plugged.sh` | 5x, 2025-08 | **no udev rule calls it**, despite the name |
| `wallpaper_hyprland.sh` | 13x, 2025-08 | Hyprland, same switch as above |
| `resetcolor` | 1x, 2025-08 | once in two years |
| `fix-keyrepeat.sh` | 1x, 2025-10 | replaced by `xset r rate` in `.xinitrc` |
| `xautolock-start.sh` | 4x, 2026-03 | `.xinitrc` starts `xidlehook-start.sh` instead |

### To keep, launched by hand regularly

`stopwatch` (106 runs, last one 2026-03) and the `connect_*` remote access script
(21 runs, last one 2026-07) are referenced nowhere, yet you type them. No reference does
not mean useless.

---

## 5. Something else spotted along the way

`/etc/acpi/events/autolock-power` runs `action=/bin/su <user> -c ...` with the account
name hardcoded, the way `dwm.desktop` used to. Fix it on the same principle as
`desktop-env.sh` if you plan to use another account name on the next machine.
