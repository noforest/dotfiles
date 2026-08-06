# Installs that do not come from pacman

These tools are referenced by the configs but do not come from the Arch
repositories. `dot install` does not handle them. Do this once, in this order.

## 1. AUR helper (do this first)

`dot install` needs it as soon as the profile declares `aur: yes`.

```sh
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si
```

## 2. Rust and the tools built on it

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install yazi-fm yazi-cli
```

`~/.zshenv` runs `. "$HOME/.cargo/env"`. Without rustup the shell prints an error at startup.

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

## 5. zoxide

```sh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

## 6. The zsh-autosuggestions plugin

`.zshrc` sources it from `~/.zsh/zsh-autosuggestions/`:

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
```

## 7. pyenv

```sh
curl -fsSL https://pyenv.run | bash
pyenv install 3.11.11    # the version used in the PATH of .zshrc
```

## 8. opam (OCaml)

```sh
sudo pacman -S opam && opam init
```

`.zshrc` sources `~/.opam/opam-init/init.zsh`, already guarded by an existence test.

## 9. suckless

Built from `suckless/` by `dot build-suckless`. Nothing to download, the patched
sources are in the repo.

## 10. Fonts

`dot fonts` fetches UnifontExMono and icons-in-terminal. Everything else is in
`packages/fonts.txt`.
