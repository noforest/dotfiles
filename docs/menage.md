# Faire le ménage avant de répliquer

Le but : ne pas traîner sur les futures machines ce qui ne sert déjà plus ici.

Lance `dot audit` pour régénérer les données. Ce document en est la lecture commentée,
faite le 2026-08-04 sur un historique de 88 578 commandes.

---

## Comment lire l'audit (à lire avant d'effacer quoi que ce soit)

`dot audit` croise deux signaux :

- **l'historique atuin** — fiable pour tout ce qui se tape dans un terminal, et
  désormais conscient des alias (`alias du="dust -r"` fait bien compter `dust`) ;
- **le mtime de `~/.config`, `~/.cache`, `~/.local/share`** — le seul indice pour les
  applis graphiques, qui sont lancées par dmenu et n'apparaissent donc jamais dans
  l'historique du shell.

**Ce que l'audit ne sait pas voir :**

| Cas | Exemple |
|---|---|
| Services et démons | `ly`, `pipewire`, `grub` ne se lancent jamais à la main |
| Programmes appelés par un script | `brightnessctl` (via `dunst_brightness.sh`), `maim` (via le raccourci capture) |
| Programmes appelés au démarrage du shell | `vivid` tourne à chaque ouverture de terminal, via `.zshrc` |
| Le shell lui-même | `zsh` apparaît « 1 lancement il y a 566 j » — c'est ton shell de connexion |
| Bibliothèques et dépendances | aucune commande à invoquer |
| Configs hors du nom du paquet | `firefox` → `~/.mozilla`, `bitwarden` → `~/.config/Bitwarden` |

L'audit exclut déjà une liste d'infrastructure connue, mais elle n'est pas exhaustive.
**Une ligne dans l'audit est une question, pas un verdict.**

---

## 1. Ce qu'on peut retirer sans hésiter

Ce sont des ensembles cohérents, abandonnés d'un bloc — pas des paquets isolés.
C'est ce qui rend la décision sûre.

### Wayland / Hyprland — 16 paquets, ~76 Mio

`hyprland hyprlock hyprpicker hyprshot waybar wofi swaync grim slurp wl-clipboard
uwsm ydotool xdg-desktop-portal-hyprland awww python-pywal wlogout`

Tous utilisés pour la dernière fois il y a **~420 jours**, en bloc : c'est ta bascule
Hyprland → dwm. Tu es sous X11 aujourd'hui, rien de tout ça ne peut servir.
Les configs correspondantes (`.config/hypr`, `waybar`, `wofi`, `swaync`, `wlogout`)
ne sont d'ailleurs **pas** reprises dans le nouveau dépôt.

### XFCE — 39 paquets, ~42 Mio

Tout `xfce4-*`, `xfdesktop`, `xfwm4`. Une trentaine de greffons de panneau
(`xfce4-eyes-plugin`, `xfce4-mailwatch-plugin`, `xfce4-smartbookmark-plugin`…)
sans la moindre trace d'usage. Tu es sous dwm.

**Deux exceptions à garder :** `thunar` (lié à une touche dwm) et ses greffons,
plus `exo`, `garcon`, `tumbler`, `xfconf` dont Thunar dépend.

### lightdm — 3 paquets

`lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings`. Ton gestionnaire de
connexion est **ly** (`/etc/ly/config.ini` est versionné, `ly.service` est actif).
Deux gestionnaires installés, un seul utilisé.

### Outils remplacés par un autre que tu utilises

| À retirer | Remplacé par |
|---|---|
| `emacs` (~264 Mio) | `neovim` |
| `oh-my-posh` | `starship` (activé dans `.zshrc`) |
| `nano` | `neovim` (`EDITOR=nvim`) |
| `most` | `vimpager` (`PAGER`/`MANPAGER` dans `.zshrc`) |
| `ranger`, `nnn` | `yazi` (fonction `y()` du `.zshrc`) |
| `arandr`, `lxappearance` | tes scripts `screen_mode` / `screen_menu` |

**Total tier 1 : ~65 paquets, ~430 Mio.**

---

## 2. Ce que toi seul peux trancher — et oui, en testant

Ta question « il vaut mieux que ce soit moi qui teste un par un ? » : **oui, mais
seulement pour cette catégorie**, pas pour la première. Une quinzaine de paquets,
pas 377.

Applis graphiques sans aucune trace, sur lesquelles je n'ai pas d'avis fondé :

`bitwarden` `filezilla` `parole` `mousepad` `xfburn` `qbittorrent` `freedoom`
`dolphin-emu` `fontforge` `handbrake` `duckdb-bin` `librewolf-bin` `qutebrowser`
`torbrowser-launcher` `proton-vpn-gtk-app` `forticlient-vpn` `snake` `neohtop`

Et les gros morceaux, à garder ou non selon tes cours :

| Paquet | Poids | Question |
|---|---|---|
| `texlive-*` (3 paquets) | ~2 Gio | tu écris encore du LaTeX ? |
| `virtualbox` + guest-iso | ~267 Mio | dernière VM lancée quand ? |
| `postgresql`, `sqls`, `rainfrog` | — | projets BD terminés ? |
| `nikto`, `gobuster`, `nmap` | — | un cours de sécu qui reviendra ? |

### La méthode pour tester sans rien casser

`pacman -Rsu` est réversible : le paquet se réinstalle depuis les dépôts.

```sh
# 1. Photographier l'état actuel (filet de sécurité)
pacman -Qqe > ~/paquets-avant-menage.txt

# 2. Retirer un lot, avec ses dépendances devenues inutiles
sudo pacman -Rsu emacs nano most ranger nnn

# 3. Vivre avec pendant une semaine.
#    Si quelque chose manque :  sudo pacman -S <paquet>

# 4. Quand c'est validé, mettre les listes à jour
dot sync && git commit -m "chore: retire les paquets inutilisés"
```

Ne retire **pas** tout d'un coup : lot par lot, dans l'ordre du tier 1, en gardant
une semaine entre chaque. Un `pacman -Rsu` sur 65 paquets d'un coup rend le
diagnostic impossible si quelque chose casse.

---

## 3. À ne PAS retirer, malgré ce qu'affiche l'audit

Vérifié un par un — ces paquets **paraissent** inutilisés mais ne le sont pas :

| Paquet | Pourquoi il ne laisse pas de trace |
|---|---|
| `zsh` | ton shell de connexion, tu ne le tapes jamais |
| `vivid` | appelé par `.zshrc` à chaque ouverture de terminal (`LS_COLORS`) |
| `acpilight` | fournit `xbacklight`, lié à une touche dwm |
| `brightnessctl` | appelé par `dunst_brightness.sh` et par ly |
| `maim`, `swappy` | appelés par `maim_swappy_screenshot.sh` (touche capture) |
| `flameshot-git` | lié à une touche dwm |
| `pavucontrol` | lié à une touche dwm |
| `libinput-gestures` | démon lancé par `.xinitrc` |
| `fd`, `ripgrep` | appelés par fzf, telescope et le picker de snacks |
| `numlockx`, `xss-lock` | lancés par `.xinitrc` |
| `dust`, `duf`, `eza`, `bat` | masqués par tes alias (`du`, `l`, `cat`) — l'audit les résout désormais |
| `ly`, `grub`, `efibootmgr`, `pipewire*` | services et amorçage |

---

## 4. Les scripts de `/usr/local/bin`

`dot audit scripts` sépare trois cas : appelé par un fichier de config, lancé à la
main, ou orphelin.

### Orphelins jamais lancés — ✅ déjà retirés du dépôt (7)

`black_screen` · `former_screen_dual_focus_on_big_one` ·
`former_screen_dual_focus_on_big_one_force` · `former_screen_duplicate_force` ·
`former_screen_multi` · `former_screen_multi_force` · `former_screen_stop`

Aucune référence nulle part, **zéro lancement** sur 88 578 commandes. Le préfixe
`former_` dit déjà qu'ils sont périmés : ils ont été remplacés par `screen_mode` et
`screen_menu` (respectivement 7 et 1 références dans tes configs).

Ils ne sont plus dans le dépôt, donc plus déployés sur une nouvelle machine.
Ils restent présents dans `/usr/local/bin` sur ce PC — à supprimer quand tu veux :

```sh
sudo rm /usr/local/bin/{black_screen,former_screen_*}
```

### Orphelins avec un usage résiduel — à toi de voir (5)

| Script | Usage | Remarque |
|---|---|---|
| `on_ducky_plugged.sh` | 5×, 2025-08 | **aucune règle udev ne l'appelle** malgré son nom |
| `wallpaper_hyprland.sh` | 13×, 2025-08 | Hyprland — même bascule que ci-dessus |
| `resetcolor` | 1×, 2025-08 | une seule fois en deux ans |
| `fix-keyrepeat.sh` | 1×, 2025-10 | remplacé par `xset r rate` dans `.xinitrc` |
| `xautolock-start.sh` | 4×, 2026-03 | `.xinitrc` lance `xidlehook-start.sh` à la place |

### À garder — lancés à la main régulièrement

`stopwatch` (106×, dernier 2026-03) et `connect_server_parma` (21×, dernier
2026-07) ne sont référencés nulle part, mais tu les tapes. L'absence de référence
ne veut pas dire inutile.

---

## 5. Autre chose repéré au passage

`/etc/acpi/events/autolock-power` contient `action=/bin/su for -c …` — le nom
d'utilisateur `for` est codé en dur, comme l'était `dwm.desktop`. À corriger sur le
même principe que `desktop-env.sh` si tu comptes utiliser un autre nom de compte
sur la prochaine machine.
