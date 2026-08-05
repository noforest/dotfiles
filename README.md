# dotfiles

Mon environnement **dwm sous Arch Linux** : configs, scripts, patchs suckless, listes de
paquets. Objectif : réinstaller Arch sur une machine neuve et retrouver la même expérience,
sans être obligé de tout installer.

```
git clone --recursive git@github.com:noforest/dotfiles.git \
    ~/Documents/programming/github-noforest/dotfiles
cd ~/Documents/programming/github-noforest/dotfiles
./dot bootstrap laptop
```

---

## Organisation

| Dossier | Contenu |
|---|---|
| `dot` | La CLI. Tout passe par elle. |
| `modules/` | Ce qui va dans `$HOME`, groupé par thème. `modules/shell/.zshrc` → `~/.zshrc`. |
| `system/root/` | Ce qui va hors de `$HOME`. Reproduit la racine : `system/root/etc/x` → `/etc/x`. |
| `suckless/` | Sources patchées de dwm, st, dmenu, slock, dwmblocks. **Aucun binaire.** |
| `packages/` | Listes de paquets par groupe + `manual.md` pour ce qui n'est pas dans pacman. |
| `profiles/` | Combinaisons de modules et de groupes de paquets. |
| `examples/` | Modèles de fichiers locaux non versionnés. |

### Profils

| Profil | Pour quoi | Paquets | Modules en plus |
|---|---|---|---|
| `minimal` | Serveur, VM, machine de passage. Terminal et éditeur, pas de session graphique. | 61 | shell, git, nvim |
| `desktop` | **PC fixe sous dwm.** Comme `laptop` sans batterie, luminosité, pavé tactile, gestes ni veille sur capot. | 209 | + terminal, x11-dwm, desktop |
| `laptop` | **Portable sous dwm** — le profil de cette machine. | 224 | + laptop |
| `full` | Tout : développement, XFCE, Hyprland, sécurité, virtualisation. | 385 | + dev |

`full` n'est pas fait pour être installé sur une machine neuve — c'est le filet qui
garantit que rien de ce qui existe ici n'est perdu. Pour un vrai PC, prends `desktop`
ou `laptop`. Voir [docs/menage.md](docs/menage.md) pour dégraisser avant de répliquer.

---

## Usage quotidien

```sh
dot status              # qu'est-ce qui a bougé ?
dot adopt ~/.config/mpv/mpv.conf desktop   # faire entrer un fichier dans le dépôt
dot sync                # régénère listes + patchs + état, puis git add -A
git commit -m "..."
```

`dot adopt` est la commande à retenir : elle déplace le fichier dans le module et le remplace
par un lien symbolique. Une fois adopté, éditer `~/.config/mpv/mpv.conf` modifie directement le
dépôt — il n'y a plus rien à copier.

`dot status` signale les liens cassés, les fichiers non liés, les divergences entre `system/` et
la racine, les paquets installés mais non catalogués, et **refuse tout fichier sensible** entré
dans l'index.

### Toutes les commandes

| Commande | Effet |
|---|---|
| `dot link [profil]` | Crée les liens. Sauvegarde l'existant en `.bak-<date>`. Idempotent. |
| `dot unlink [profil]` | Retire les liens posés (garde les `.bak`). |
| `dot list [profil]` | Liste les chemins gérés. |
| `dot adopt <chemin> <module>` | Fait entrer un fichier de `$HOME` dans un module. |
| `dot status [profil]` | Rapport de dérive complet. |
| `dot sync` | Régénère tout ce qui est généré, puis `git add -A`. |
| `dot install [profil]` | `pacman -S --needed` puis `paru -S` selon le profil. |
| `dot system-apply` | Copie `system/root/` vers la racine (sudo). |
| `dot system-pull` | Récupère dans le dépôt ce qui a changé sur le système. |
| `dot build-suckless` | Compile et installe les cinq projets suckless. |
| `dot fonts` | Récupère les deux polices hors dépôts. |
| `dot audit [packages\|scripts]` | Ce qui sert vraiment sur cette machine (historique + traces disque). |
| `dot state` | Régénère `system/state.md`. |
| `dot bootstrap [profil]` | Enchaîne tout, machine neuve → environnement complet. |

---

## Réinstallation complète

À partir d'une installation Arch de base (utilisateur créé, réseau fonctionnel).

### 1. Prérequis

```sh
sudo pacman -S --needed git base-devel
```

Puis l'assistant AUR et les outils hors pacman : voir **[packages/manual.md](packages/manual.md)**.
Au minimum `paru` avant de continuer, sinon `dot install` sautera les 53 paquets AUR.

### 2. Cloner et amorcer

```sh
git clone --recursive git@github.com:noforest/dotfiles.git \
    ~/Documents/programming/github-noforest/dotfiles
cd ~/Documents/programming/github-noforest/dotfiles
./dot bootstrap laptop
```

`--recursive` est nécessaire : le plugin nvim `codediff` est un submodule.
Si tu as oublié : `git submodule update --init --recursive`.

`bootstrap` enchaîne `install` → `link` → `system-apply` → `fonts` → `build-suckless`.

### 3. Après le bootstrap

Ces étapes touchent des états système que le dépôt ne rejoue pas automatiquement.
`system/state.md` donne l'état de référence de la machine d'origine.

```sh
# Shell par défaut
chsh -s /bin/zsh

# Groupes (docker, virtualbox, etc. — comparer avec system/state.md)
sudo usermod -aG docker,vboxusers "$USER"

# Services système
sudo systemctl enable --now ly NetworkManager acpid docker cups auto-cpufreq

# Services utilisateur
systemctl --user enable --now pipewire pipewire-pulse wireplumber \
                              ssh-agent.socket lock.service backup_gdrive.timer

# Recharger ce que system-apply a posé
sudo udevadm control --reload && sudo udevadm trigger
sudo systemctl daemon-reload

# Plugins nvim
nvim --headless "+Lazy! sync" +qa
```

### 4. Réglages propres à la machine

Trois fichiers à adapter — c'est tout ce qui reste de machine-spécifique :

- **`~/.gitconfig-local`** — identité git (nom, adresse) et routage par compte.
  Modèle : [`examples/gitconfig-local`](examples/gitconfig-local). Hors dépôt : ni lié ni
  versionné, il vit dans `$HOME`. `~/.gitconfig` l'inclut ; sans lui, git refuse de committer
  faute d'auteur.

- **`~/.zshrc.local`** — chemins de projets, variables d'école, `TD_AUTO_DIRS`.
  Modèle : [`examples/zshrc.local`](examples/zshrc.local). Non versionné, sourcé en fin de
  `.zshrc` s'il existe.

- **`modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh`** — identifiants xinput.
  Les noms de périphériques (`"ELAN2204:00 04F3:3109 Touchpad"`…) ne valent que pour un
  portable donné. Sur une nouvelle machine : copier `archlinux.sh` sous le nouveau hostname et
  remplacer les identifiants par ceux de `xinput list`. Si le fichier n'existe pas, rien n'est
  chargé et la session démarre quand même.

---

## Choix de conception

**Liens symboliques pour `$HOME`, copie pour la racine.** `/etc/udev/rules.d` et
`/etc/ly/config.ini` sont lus très tôt au démarrage, avant que `/home` ne soit forcément monté :
un lien vers le dépôt casserait le boot. D'où `system-apply` / `system-pull`, et `dot status`
qui signale les divergences.

**Les plugins nvim ne sont pas patchés.** Les personnalisations vivent dans `lazy.lua`,
via les API prévues par chaque plugin :

- `snacks` — les actions `explorer_cd`, `explorer_up_and_cd`, `select` et `unselect_all`
  passent par `picker.opts.actions`, que snacks consulte **avant** ses propres actions ;
  l'aperçu d'image par chafa surcharge `snacks.picker.preview.image` depuis la config.
- `zincoxide` — la notification du répertoire est un autocmd `DirChanged` (motif `tabpage`,
  qui correspond au `tcd` de `behaviour = "tabs"`).
- `catppuccin` — plus rien : la modification portait sur l'intégration `bufferline`, un
  plugin qui n'est **pas** installé (c'est `barbar` qui est utilisé), et sur une ligne
  commentée. Elle n'avait aucun effet.

Un dépôt de dotfiles ne devrait pas contenir de patchs sur du code tiers : ils périment
silencieusement à la première mise à jour amont. Ici, `:Lazy update` ne peut plus rien casser.

**`codediff` est un dépôt séparé.** C'est un vrai projet (C + Lua, CMake, tests, 289 fichiers),
pas un fichier de configuration. Il est référencé en submodule avec une URL *relative*
(`../codediff.nvim.git`), qui se résout automatiquement vers le même compte GitHub que ce dépôt.

**Aucun binaire.** Les exécutables suckless sont recompilés par `dot build-suckless`, les
polices viennent de pacman (`packages/fonts.txt`) ou de `dot fonts`. Le dépôt fait ~10 Mo au
lieu des 36 Mo de la version précédente.

**Les scripts lancés par root sont agnostiques de l'utilisateur.** Ceux appelés par udev, acpid
ou systemd sourcent `/usr/local/bin/desktop-env.sh`, qui détermine la session graphique active
et en déduit `USER_HOME`, `DISPLAY` et `XAUTHORITY` — au lieu d'un `/home/for` en dur.

---

## Points d'attention

- **`~/.dotfiles`** (l'ancien dépôt *bare*) n'est ni supprimé ni modifié. Il reste comme archive,
  localement et sur `git@github.com:noforest/.dotfiles.git`.
- **`~/.local/bin/scripts/`** n'est pas versionné : il contenait des copies périmées des scripts
  de `/usr/local/bin`, qui est la seule référence appelée par `.xinitrc`, dwmblocks et dwm.
- **`~/.config/systemd/user/graphical-session.target.wants/xset.service`** est un lien cassé
  hérité (la cible n'existe plus) ; le réglage est repris par `xset-r-rate.service` au niveau
  système, présent dans `system/root/`.
- **Secrets** : clés SSH/GPG, `rclone.conf`, `atuin/config.toml`, `.npmrc`, `gh/hosts.yml`,
  `solaar/config.yaml` sont exclus par `.gitignore` et vérifiés à chaque `dot status`.
