# packages/ubuntu

Squelette. À remplir avec la machine Ubuntu sous la main, groupe par groupe.

Les groupes doivent porter **les mêmes noms** que dans `packages/arch/` : un
profil déclare `packages: core shell fonts x11-dwm …` sans savoir sur quelle
distribution il tourne, et `dot install` lit le dossier de la distribution
détectée. Un groupe absent ici est ignoré silencieusement, ce qui est voulu
pendant le remplissage, mais veut dire qu'un oubli ne se signale pas tout seul.

## La traduction n'est pas mécanique

| Arch | Ubuntu |
|---|---|
| `base-devel` | `build-essential` |
| `xorg-xrandr`, `xorg-xset`, … | `x11-xserver-utils` (un seul paquet pour plusieurs) |
| `xorg-server` | `xserver-xorg` |
| `7zip` | `p7zip-full` |
| `exfatprogs` | `exfatprogs` (identique) |

## Ce qui ne doit pas être repris

`packages/arch/core.txt` contient `base`, `linux`, `linux-firmware`, `grub`,
`efibootmgr`, `pacman-contrib`, `reflector` : c'est un manifeste de réinstallation
d'Arch. Sur une Ubuntu déjà installée, ces lignes n'ont pas d'équivalent utile,
car le noyau et le bootloader sont déjà là et gérés par la distribution.

`aur.txt` n'a pas d'équivalent : `dot install` ignore le réglage `aur:` hors Arch.
Ce qui venait de l'AUR se trouve ici dans un PPA, un snap, un flatpak ou une
installation manuelle, à documenter dans `manual.md` au fur et à mesure.
