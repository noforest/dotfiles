# To do

## nvim: update the plugins, one at a time

`lazy-lock.json` pins every plugin, and a blanket `:Lazy update` breaks the
config. Update one plugin with `:Lazy update <name>`, test, commit the lock.
To go back: `dotgit restore modules/nvim/.config/nvim/lazy-lock.json`, then
`dot nvim-setup`.

Known to need work:

- **blink.cmp**: pinned to v1.10.2. v2 requires `saghen/blink.lib` as a
  dependency and is a major version, so the completion config has to be
  reviewed against it.
- **matchparen.nvim**: newer versions reject the `debounce_time` option, drop
  it from the `setup()` call when updating.
- **snacks.nvim**: carries `patches/snacks.nvim.patch`, which may not apply to
  a newer version. Check with `dot nvim-patch`.
