# machine.d

The default profile of each machine, in `machine.d/<hostname>.conf`.

Without this file, `dot` falls back to the `laptop` profile. With it, `dot status`,
`dot link`, `dot system-apply` etc. no longer need the profile named
on the command line.

The file holds a single line: the profile name.

```sh
echo desktop > machine.d/$(hostname).conf
```

The `*.conf` files here are **not versioned**: the repository is public and a hostname
has no business in it. Only this README is.

Not to be confused with `modules/x11-dwm/.config/dwm/machine.d/<hostname>.sh`, which
holds the xinput ids of each machine and belongs to the dwm config.
