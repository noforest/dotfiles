# machine.d

Le profil par défaut de chaque machine, dans `machine.d/<hostname>.conf`.

Sans ce fichier, `dot` retombe sur le profil `laptop`. Avec lui, `dot status`,
`dot link`, `dot system-apply` etc. n'ont plus besoin qu'on leur nomme le profil
sur la ligne de commande.

Le fichier contient une seule ligne : le nom du profil.

```sh
echo desktop > machine.d/$(hostname).conf
```

Les `*.conf` d'ici ne sont **pas versionnés** : le dépôt est public et un hostname
n'a rien à y faire. Seul ce README l'est.

À ne pas confondre avec `modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh`, qui
porte les identifiants xinput de chaque machine et relève, lui, de la config dwm.
