#!/usr/bin/python3
"""ty or pyrefly for VS Code with the suggestion list of Pylance.

Set as "ty.path" in settings.json, and under its other name, pyrefly-filter.py,
as "pyrefly.lspPath". It runs the server bundled with the VS Code extension
and edits one kind of message on its way back, the completion lists:
  - a row is its icon and its name, nothing at its right. ty writes whole
    signatures there, which truncates the names, and pyrefly writes one on
    the selected row;
  - the details panel opens on that signature, written as Python source in a
    code block, hence in colours: `def split(` with a parameter per line,
    `n_splits: int`, `class KFold`. Both servers send it as plain text, which
    VS Code prints in grey, and ty words it `bound method A.split(X, y)`.
    The docstring follows;
  - a value has the icon of a variable, the one Pylance gives an attribute.
    pyrefly has another for a field, and ty picks from the type: bars for an
    instance and, having no kind for it, a wrench for `Unknown`;
  - for ty, a value loses its documentation: ty puts the one of its type
    there, so an `int` attribute came with the manual of `int`. pyrefly gives
    the attribute's own docstring, which is kept;
  - scikit-learn's `set_*_request` methods are dropped where the class does
    not have them. The library declares all ten for type checkers only, on
    every estimator, and creates the real ones when it is imported. Which
    class really has which is in ty-filter-sklearn.json, next to this script.
    A class missing from it keeps all ten, so that no method that exists is
    ever hidden;
  - for ty, the list is declared complete. ty flags every list as incomplete,
    so VS Code asks for a new one at each key, and ty answers nothing when the
    cursor is no longer at the end of the word, which is where a request sent
    one key earlier points. The popup then flickers or closes while a key is
    held. A complete list is narrowed by VS Code itself, as with pyrefly.
    Lists near ty's limit of a thousand entries are left as they are.

The last two can be turned off in settings.json, `"tyFilter.dropSetRequests":
false` and `"tyFilter.completeLists": false`. The file is read again for
every list, so saving it is enough. For the plain server, without this script
at all, comment out its "ty.path" or "pyrefly.lspPath" line.

Everything else is passed through untouched, and what VS Code sends goes to
the server directly. If a list cannot be edited it is passed through as it came.

`ty-filter.py --self-test` checks the editing without starting a server.
`<python that has scikit-learn> ty-filter.py --make-table > ty-filter-sklearn.json`
writes the table again, after scikit-learn gained classes. A stale table only
leaves the ten methods on the classes it does not know.
"""
import glob
import json
import os
import re
import signal
import subprocess
import sys

# The ten scikit-learn declares, and no other name: `set_user_request` may be yours.
PHANTOM = re.compile(r"set_(fit|partial_fit|predict|predict_proba|predict_log_proba|decision_function|score|split"
                     r"|transform|inverse_transform)_request")
# The class a method is shown on, as ty writes it, then as pyrefly does.
OWNER = re.compile(r"^bound method (\w+)\.|^def \w+\(\s*self\s*:\s*(\w+)")
BOUND = re.compile(r"^bound method .*?\.(?=\w+[\[(])")
# A string, skipped as a whole, or what opens, closes and separates the parameters of a signature.
TOKEN = re.compile(r""""[^"]*"|'[^']*'|[()\[\]{},]""")
# CompletionItemKind of a value: Field and Variable from pyrefly, Value and Struct from ty, which has none for Unknown.
VALUES = {5, 6, 12, 22, None}
HERE = os.path.dirname(os.path.abspath(__file__))
# Not settings VS Code knows, hence read here, from the settings.json next to this script.
SETTINGS = os.path.join(HERE, "settings.json")
LIMIT = 900  # with auto-import ty stops near a thousand entries: such a list really is incomplete
TABLE = os.path.join(HERE, "ty-filter-sklearn.json")
PYREFLY = os.path.basename(sys.argv[0]).startswith("pyrefly")
BUNDLED = "meta.pyrefly-*/bin/pyrefly" if PYREFLY else "astral-sh.ty-*/bundled/libs/bin/ty"


def turned_off(name, text):
    return bool(re.search(rf'^\s*"tyFilter\.{name}"\s*:\s*false\b', text, re.M))


def options():
    try:
        with open(SETTINGS) as settings:
            text = settings.read()
    except OSError:
        text = ""
    return {"drop": not turned_off("dropSetRequests", text),
            "complete": not PYREFLY and not turned_off("completeLists", text)}


def real_setters():
    try:
        with open(TABLE) as table:
            return {name: {f"set_{method}_request" for method in methods.split()}
                    for name, methods in json.load(table)["classes"].items()}
    except (OSError, ValueError, KeyError):
        return {}


def one_per_line(text):
    """`def f(a, b) -> c` with each parameter on its own line, as Pylance and pyrefly lay it out."""
    start = text.find("(")
    depth, commas = 0, []
    for found in TOKEN.finditer(text, start):
        char, at = found[0], found.start()
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
            if not depth:
                break
        elif char == "," and depth == 1:
            commas.append(at)
    if depth or not commas:
        return text
    params = [text[a + 1:b].strip() for a, b in zip([start] + commas, commas + [at])]
    return text[:start + 1] + "\n    " + ",\n    ".join(params) + "\n" + text[at:]


def signature(label, kind, text):
    """What the server tells of a completion, as the Python source Pylance shows for it."""
    text = text.strip()
    if kind in VALUES:
        return f"{label}: {text}"
    text = re.sub(r"^<class '(.+)'>$", r"class \1", BOUND.sub("def ", text))  # the wording of ty
    if text.startswith("("):  # pyrefly, for a function of which it has the type only
        text = f"def {label}{text}"
    return one_per_line(text) if text.startswith("def ") and "\n" not in text else text


def tidy(body, drop=True, real={}, complete=True):
    try:
        message = json.loads(body)
        result = message["result"]
        items = result["items"] if isinstance(result, dict) else result
        kept = []
        for item in items:
            described = (item.get("labelDetails") or {}).pop("description", None)
            text = item.pop("detail", None) or described or ""
            if drop and PHANTOM.fullmatch(item["label"]):
                owner = OWNER.match(text)
                owner = owner and (owner[1] or owner[2])
                if owner in real and item["label"] not in real[owner]:
                    continue
            kind = item.get("kind")
            if kind in VALUES:
                item["kind"] = 6  # Variable
                if not PYREFLY:
                    item.pop("documentation", None)
            if text:
                doc = item.get("documentation")
                doc = doc.get("value") if isinstance(doc, dict) else doc
                item["documentation"] = {"kind": "markdown", "value": f"```python\n{signature(item['label'], kind, text)}\n```"
                                                                      + (f"\n---\n{doc}" if doc else "")}
            kept.append(item)
        if isinstance(result, dict):
            result["items"] = kept
            if complete and len(items) < LIMIT:
                result["isIncomplete"] = False
        else:
            message["result"] = kept
        return json.dumps(message, separators=(",", ":")).encode()
    except Exception:
        return body


if sys.argv[1:] == ["--self-test"]:
    def row(name, kind, text, doc=None, pyrefly=False):
        return {"label": name, "kind": kind, **({"detail": text} if pyrefly else {"detail": text, "labelDetails": {"description": text}}),
                **({"documentation": {"kind": "markdown", "value": doc}} if doc else {})}

    predict = "def predict(\n    self: A,\n    X: ndarray\n) -> ndarray: ..."
    rows = [(row("split", 2, "bound method StratifiedKFold.split(X, y, groups=None) -> Unknown", doc="Generate indices."),
             "def split(\n    X,\n    y,\n    groups=None\n) -> Unknown\n```\n---\nGenerate indices."),
            (row("set_fit_request", 2, "bound method A.set_fit_request(**kwargs) -> Unknown"), "def set_fit_request(**kwargs) -> Unknown"),
            (row("set_score_request", 2, "bound method A.set_score_request(**kwargs) -> Unknown"), None),
            (row("set_user_request", 2, "bound method A.set_user_request(user) -> None"), "def set_user_request(user) -> None"),
            (row("merge", 2, 'bound method DataFrame.merge(how: Literal["a, b", "c"] = "a, b", on: tuple[int, int] = (1, 2)) -> DataFrame'),
             'def merge(\n    how: Literal["a, b", "c"] = "a, b",\n    on: tuple[int, int] = (1, 2)\n) -> DataFrame'),
            (row("len", 3, "def len(obj: Sized, /) -> int"), "def len(\n    obj: Sized,\n    /\n) -> int"),
            (row("n_splits", 22, "int", doc="int([x]) -> integer"), "n_splits: int" + ("\n```\n---\nint([x]) -> integer" if PYREFLY else "")),
            (row("w", None, "Unknown"), "w: Unknown"),
            (row("KFold", 7, "<class 'KFold'>"), "class KFold"),
            (row("predict", 2, predict, pyrefly=True), predict),
            (row("set_predict_request", 2, "def set_predict_request(\n    self: A,\n    **kwargs: Unknown\n) -> Unknown: ...", pyrefly=True), None),
            (row("classes_", 5, "ndarray[Any, dtype[Any]]", pyrefly=True), "classes_: ndarray[Any, dtype[Any]]"),
            (row("cross_val_score", 3, "(estimator: BaseEstimator) -> ndarray", pyrefly=True), "def cross_val_score(estimator: BaseEstimator) -> ndarray"),
            ({"label": "for", "kind": 14}, "")]
    body = json.dumps({"id": 1, "result": {"isIncomplete": True, "items": [item for item, _ in rows]}}).encode()

    def shown(**options):
        items = json.loads(tidy(body, **options))["result"]["items"]
        assert not any("detail" in i or (i.get("labelDetails") or {}).get("description") for i in items), "a right-hand column is left"
        return [(i["label"], i.get("documentation", {}).get("value", "").removeprefix("```python\n").removesuffix("\n```")) for i in items]

    want = [(item["label"], expected) for item, expected in rows if expected is not None]
    assert shown(real={"A": {"set_fit_request"}}) == want, shown(real={"A": {"set_fit_request"}})
    assert [name for name, _ in shown()] == [item["label"] for item, _ in rows], shown()  # a class the table lacks
    assert [name for name, _ in shown(drop=False, real={"A": set()})] == [item["label"] for item, _ in rows]
    kinds = {i["label"]: i.get("kind") for i in json.loads(tidy(body))["result"]["items"]}
    assert (kinds["n_splits"], kinds["w"], kinds["classes_"], kinds["split"], kinds["for"]) == (6, 6, 6, 2, 14), kinds
    assert json.loads(tidy(body))["result"]["isIncomplete"] is False
    assert json.loads(tidy(body, complete=False))["result"]["isIncomplete"] is True
    many = json.dumps({"id": 1, "result": {"isIncomplete": True, "items": [{"label": str(n)} for n in range(LIMIT)]}}).encode()
    assert json.loads(tidy(many))["result"]["isIncomplete"] is True
    assert turned_off("dropSetRequests", '{\n    "tyFilter.dropSetRequests": false,\n}')
    assert not turned_off("dropSetRequests", '{\n    // "tyFilter.dropSetRequests": false,\n    "tyFilter.dropSetRequests": true\n}')
    resolved = b'{"id":2,"result":{"label":"fit","kind":2,"sortText":"0"}}'  # pyrefly echoes the row VS Code asks about
    assert tidy(resolved) == resolved and tidy(b"not json") == b"not json"
    assert real_setters().get("LogisticRegression") == {"set_fit_request", "set_score_request"}, "ty-filter-sklearn.json"
    sys.exit(print("ok"))

if sys.argv[1:] == ["--make-table"]:
    import importlib
    import inspect
    import pkgutil
    import warnings

    import sklearn

    warnings.simplefilter("ignore")
    classes = {}
    for found in pkgutil.walk_packages(sklearn.__path__, "sklearn."):
        if re.search(r"\.tests(\.|$)|conftest|_build_utils|externals", found.name):
            continue
        try:
            module = importlib.import_module(found.name)
        except Exception:
            continue
        for name, cls in vars(module).items():
            if inspect.isclass(cls) and cls.__module__.startswith("sklearn.") and hasattr(cls, "get_metadata_routing"):
                classes.setdefault(name, set()).update(a[4:-8] for a in dir(cls) if PHANTOM.fullmatch(a))
    json.dump({"scikit-learn": sklearn.__version__, "classes": {k: " ".join(sorted(v)) for k, v in sorted(classes.items())}},
              sys.stdout, indent=0)
    sys.exit()

# The extension installed last, so that an update of the server is picked up by itself.
REAL = max(glob.glob(os.path.expanduser("~/.vscode/extensions/" + BUNDLED)), key=os.path.getctime)
if sys.argv[1:2] != ["lsp" if PYREFLY else "server"]:
    os.execv(REAL, [REAL] + sys.argv[1:])

setters = real_setters()
server = subprocess.Popen([REAL] + sys.argv[1:], stdout=subprocess.PIPE)
signal.signal(signal.SIGTERM, lambda *_: server.terminate())
out = sys.stdout.buffer
while True:
    length = 0
    while (line := server.stdout.readline()) not in (b"\r\n", b""):
        if line.lower().startswith(b"content-length"):
            length = int(line.split(b":")[1])
    if not length:
        break
    body = server.stdout.read(length)
    if b'"sortText"' in body:
        body = tidy(body, real=setters, **options())
    out.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
    out.flush()
sys.exit(server.wait())
