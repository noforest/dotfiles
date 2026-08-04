# Installations hors pacman

Ces outils sont référencés par les configs mais ne viennent pas des dépôts Arch.
`dot install` ne les gère pas — à faire une fois, dans cet ordre.

## 1. Assistant AUR (à faire en premier)

`dot install` en a besoin dès que le profil déclare `aur: yes`.

```sh
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si
```

## 2. Rust et les outils qui en dépendent

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install yazi-fm yazi-cli
```

`~/.zshenv` fait `. "$HOME/.cargo/env"` — sans rustup, le shell affiche une erreur au démarrage.

## 3. Starship (invite de commande)

```sh
curl -sS https://starship.rs/install/install.sh | sh   # installe dans /usr/local/bin
```

Configuré par `~/.config/starship/customstarship.toml` (variable `STARSHIP_CONFIG` du `.zshrc`).

## 4. Atuin (historique de shell)

```sh
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
```

`~/.config/atuin/config.toml` **n'est pas versionné** (il contient la clé de synchronisation).
Après installation : `atuin login` puis `atuin sync`.

## 5. zoxide

```sh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

## 6. Greffon zsh-autosuggestions

`.zshrc` le source depuis `~/.zsh/zsh-autosuggestions/` :

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
```

## 7. pyenv

```sh
curl -fsSL https://pyenv.run | bash
pyenv install 3.11.11    # version utilisée dans le PATH du .zshrc
```

## 8. opam (OCaml)

```sh
sudo pacman -S opam && opam init
```

`.zshrc` source `~/.opam/opam-init/init.zsh` (déjà protégé par un test d'existence).

## 9. Suckless

Compilés depuis `suckless/` par `dot build-suckless`. Rien à télécharger : les sources
patchées sont dans le dépôt.

## 10. Polices

`dot fonts` récupère UnifontExMono et icons-in-terminal. Tout le reste est dans
`packages/fonts.txt`.
