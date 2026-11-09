# ty in VS Code: the filter script and the type stubs

How Python completion is set up in VS Code in this repository, how to get the
same thing on another machine, and what to do when VS Code says the stubs are
out of date.

## What is installed

| File in `modules/dev/` | Linked to | Role |
|---|---|---|
| `.config/Code/User/settings.json` | `~/.config/Code/User/` | `"ty.path"` points to the script below |
| `.config/Code/User/ty-filter.py` | `~/.config/Code/User/` | Starts ty and tidies its suggestion lists. Its header says how |
| `.config/Code/User/pyrefly-filter.py` | `~/.config/Code/User/` | The same script under another name, for pyrefly |
| `.config/Code/User/ty-filter-sklearn.json` | `~/.config/Code/User/` | Which scikit-learn class really has which `set_*_request` method |
| `.config/ty/ty.toml` | `~/.config/ty/` | Gives ty the folder of type stubs |

One folder is not in the repository: `~/.local/share/ty-stubs/`, the stubs
themselves. The script writes it from files of the Pylance extension, so it is
made again on each machine instead of being copied around.

VS Code extensions, profiles, and which extension is enabled are not managed by
`dot` either.

## On a new machine

Arch or Ubuntu, the steps are the same. They need VS Code as Microsoft ships it
(the `.deb`, the snap, or `visual-studio-code-bin` on Arch), because Pylance
cannot be installed in VSCodium or Code OSS, and `/usr/bin/python3` 3.9 or
newer. Nothing else: the script only uses the standard library.

1. `dot link` creates the links of the table above.
2. In VS Code, install the extensions **ty** (`astral-sh.ty`) and **Pylance**
   (`ms-python.vscode-pylance`). Disable Pylance, and pyrefly if it is there.
   Pylance only has to be installed, the stubs are read from its folder.
3. Write the stubs:

   ```sh
   ~/.config/Code/User/ty-filter.py --make-stubs
   ```

4. In VS Code, run **ty: Restart server** from the command palette
   (`Ctrl+Shift+P`), or reload the window.

If step 3 is forgotten, ty works as it does without stubs, and VS Code shows a
warning that gives the command each time ty starts.

## What the stubs are for

Without stubs ty reads the code of pandas and scikit-learn. Much of it has no
type annotations, so ty does not know what many calls return.

| Typed in the editor | Without the stubs | With them |
|---|---|---|
| `df["a"].` | nothing | 194 names |
| `df["a"].str.` | nothing | 57 names |
| `cross_val_score(clf, X, y).` | nothing | 70 names |
| `clf.fit(X, y).predict(X).` | nothing | 70 names |
| `clf.fit` in the details panel | `fit: Unknown` | signature with types, and its doc |
| `accuracy_score` in the details panel | `Unknown` | signature with types, and its doc |
| `skf.split` in the details panel | `def split(X, y, groups=None)` | every parameter with its type, and what it returns |
| `skf.n_splits`, `clf.C` | suggested | suggested, with their type |

The stubs of scikit-learn only declare methods. Given to ty as they are, they
make `skf.n_splits` and every other constructor parameter disappear from the
list. So the script adds one line per parameter of `__init__` to each class,
with the type the parameter has there: 2545 attributes in 149 of its 292
files. The pandas stubs are copied unchanged.

## When VS Code says the stubs are out of date

The script compares the Pylance that is installed with the one the stubs were
copied from, each time ty starts. It costs two small file reads. When they
differ, a warning pops up at the bottom right of VS Code, signed `Source: ty`:

> Pylance was updated: the stubs of ty come from
> ms-python.vscode-pylance-2026.4.1, ms-python.vscode-pylance-2026.5.0 is
> installed. Run /home/you/.config/Code/User/ty-filter.py --make-stubs in a
> terminal, then restart ty.

Do what it says:

```sh
~/.config/Code/User/ty-filter.py --make-stubs
```

then **ty: Restart server** in the command palette. The command takes less than
a second and can be run at any time. It deletes `~/.local/share/ty-stubs/` and
writes it again.

Nothing breaks while the warning is ignored. ty keeps using the stubs it has,
which only miss what the newer Pylance changed.

### The same thing by hand

This is all the command does, should it ever need to be done or checked
without it:

1. Find the newest Pylance:
   `ls -d ~/.vscode/extensions/ms-python.vscode-pylance-*/dist/bundled/stubs`.
2. Delete `~/.local/share/ty-stubs/`, then copy the folders `pandas` and
   `sklearn` from step 1 into it.
3. In every `.pyi` file under `sklearn`, above each `__init__`, add a line
   `name: type` for each of its parameters that the class does not declare
   yet. Parameters without a type get `_Any`, with
   `from typing import Any as _Any` at the top of the file.
4. Write the name of the Pylance folder
   (`ms-python.vscode-pylance-2026.4.1`) in
   `~/.local/share/ty-stubs/SOURCE`. The script reads that file to know
   whether the stubs are current.

Step 3 is the function `with_attributes` in the script. Without it, steps 1, 2
and 4 are enough for working stubs, at the price of the missing attributes.

## What the stubs cost

Measured on 2026-10-12 with ty 0.0.86 and the stubs of Pylance 2026.4.1, ty
alone in a VS Code with nothing else enabled, twice without the stubs and twice
with them. Times are from the keystroke to the list, medians in milliseconds.
The machine is noisy, so a difference under 30 ms means nothing.

| | Without | With |
|---|---|---|
| Memory of ty at the end of the session | 343 and 351 MB | 364 and 382 MB |
| Ready after opening a file | 1.8 and 2.2 s | 2.3 and 2.4 s |
| `skf.` | 58 and 19 | 22 and 20 |
| `clf.` | 43 and 24 | 24 and 28 |
| `df.` | 114 and 117 | 122 and 121 |
| `np.` | 353 and 223 | 222 and 229 |
| `pd.` | 68 and 75 | 115 and 116 |
| `metrics.` (`from sklearn import metrics`) | 21 and 33 | 106 and 113 |
| `df["a"].` | 13, an empty list | 134 and 150, 194 names |
| `cross_val_score(...).` | 12, an empty list | 51 and 55, 70 names |

Two lists are slower for good: `pd.` and `metrics.`. Without the stubs
`metrics.` is 84 names of which one has a signature. With them 75 have one, and
their documentation, which is what takes the time. Notebooks of 19 to 221 code
cells show no steady difference.

Known losses, all small:

- `skf.get_metadata_routing` is no longer suggested. The stubs do not declare
  it.
- `df.` lists 202 names where it listed 212.
- Number types are long. `n_splits` reads
  `int | signedinteger[_8Bit] | signedinteger[_16Bit] | ...` because the stubs
  accept numpy integers too.
- A few pandas methods change their documentation. `df.head` loses it,
  `df.merge` gains one. Over the whole of `df.`, more methods have one than
  before.

Not changed by the stubs:

- ty suggests nothing useful below a top-level `raise NotImplementedError()`,
  which it reads as the end of the program.
- ty answers nothing when the cursor is in the middle of a word.

## Going back

Comment out the `extra-paths` line of `~/.config/ty/ty.toml` and restart ty.
ty then reads the code of the libraries again, and the script stops checking
the stubs. The folder can stay or be deleted.

The file applies to every project of the user, and to `ty check` in a terminal
as well. A project that sets its own `extra-paths` in its `ty.toml` or
`pyproject.toml` adds to this one, it does not replace it. pyrefly does not
read the file, so nvim, which uses pyrefly, is not affected.

## Checking

```sh
~/.config/Code/User/ty-filter.py --self-test
```

prints `ok` when the script still edits lists, adds attributes to a stub and
words its warning as expected. It starts no server.
