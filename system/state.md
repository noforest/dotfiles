# État système

Généré par `dot state` le 2026-08-04 13:01 sur `archlinux`.
Document de **référence** pour la réinstallation — il n'est pas rejoué automatiquement.

## Services systemd (système)
```
UNIT FILE                          STATE   PRESET
cups.path                          enabled disabled
acpid.service                      enabled disabled
auto-cpufreq.service               enabled disabled
cups.service                       enabled disabled
docker.service                     enabled disabled
getty@.service                     enabled enabled
NetworkManager-dispatcher.service  enabled disabled
NetworkManager-wait-online.service enabled disabled
NetworkManager.service             enabled disabled
proton.VPN.service                 enabled disabled
systemd-timesyncd.service          enabled enabled
xset-r-rate.service                enabled disabled
cups.socket                        enabled disabled
systemd-userdbd.socket             enabled enabled
remote-fs.target                   enabled enabled

15 unit files listed.
```

## Services systemd (utilisateur)
```
UNIT FILE                   STATE   PRESET
lock.service                enabled enabled
pipewire-pulse.service      enabled enabled
pipewire.service            enabled enabled
wireplumber.service         enabled enabled
gnome-keyring-daemon.socket enabled enabled
p11-kit-server.socket       enabled enabled
pipewire-pulse.socket       enabled enabled
pipewire.socket             enabled enabled
ssh-agent.socket            enabled enabled
backup_gdrive.timer         enabled enabled

10 unit files listed.
```

## Utilisateur
```
groupes : for vboxusers docker input wheel
shell   : /usr/bin/zsh
```

## Locale, heure, machine
```
System Locale: (unset)
    VC Keymap: fr
   X11 Layout: fr
timezone : Europe/Paris
```

## Bootloader et noyau
```
noyau : 7.1.5-arch1-2
bootloader : grub
```
