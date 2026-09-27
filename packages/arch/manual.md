# Installs that do not come from pacman

These tools are referenced by the configs but do not come from the Arch
repositories. `dot install` does not handle them. Do this once, in this order.

## 1. AUR helper (do this first)

`dot install` needs it as soon as the profile declares `aur: yes`.

```sh
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si
```

## 2. Rust

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

`~/.zshenv` loads `~/.cargo/env` when it exists. yazi itself comes from pacman
(`shell.txt`).

## 3. Starship (shell prompt)

```sh
curl -sS https://starship.rs/install/install.sh | sh   # installs into /usr/local/bin
```

Configured by `~/.config/starship/customstarship.toml` (the `STARSHIP_CONFIG` variable in `.zshrc`).

## 4. Atuin (shell history)

```sh
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
```

`~/.config/atuin/config.toml` is **not versioned**, because it holds the sync key.
After installing: `atuin login`, then `atuin sync`.

## 5. The zsh-autosuggestions plugin

`.zshrc` sources it from `~/.zsh/zsh-autosuggestions/`:

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
```

## 6. auto-cpufreq (laptop only)

Not packaged in the official repositories, installed with its own installer.
`power-profiles-daemon` (in `laptop.txt`) must then stay out of the way, it is
masked on the reference machine: `sudo systemctl mask power-profiles-daemon`.

```sh
git clone https://github.com/AdnanHodzic/auto-cpufreq.git /tmp/auto-cpufreq
cd /tmp/auto-cpufreq && sudo ./auto-cpufreq-installer
sudo auto-cpufreq --install    # creates and enables auto-cpufreq.service
```

## 7. opam (OCaml)

```sh
opam init    # opam itself comes from dev.txt
```

`.zshrc` sources `~/.opam/opam-init/init.zsh`, already guarded by an existence test.

## 8. suckless

Built from `suckless/` by `dot build-suckless`. Nothing to download, the patched
sources are in the repo.

## 9. Fonts

`dot fonts` fetches UnifontExMono and icons-in-terminal. Everything else is in
`packages/arch/fonts.txt`.
