#!/usr/bin/python3
"""ty or pyrefly for VS Code with a tidier suggestion list.

Set as "ty.path" in settings.json, and under its other name, pyrefly-filter.py,
as "pyrefly.lspPath". It runs the server bundled with the VS Code extension
and edits one kind of message on its way back, the completion lists:
  - each row gets a short word at its right, as in the nvim config: the kind
    of a callable, class or module, and for a value its type without the
    generic arguments, cut to MAX_TYPE characters (the full type stays in the
    details panel). ty writes whole signatures there, which truncates the
    names, and pyrefly writes one on the selected row only;
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
    Lists near ty's limit of a thousand entries are left as they are;
  - for ty, a value loses its documentation: ty puts the one of its type
    there, so an `int` attribute came with the manual of `int`. pyrefly gives
    the attribute's own docstring, which is kept;
  - for ty, every value gets the icon of a field, the blue cube pyrefly shows.
    ty picks the icon from the type, bars for an instance and, having no kind
    for it, a wrench for `Unknown`, which the word at the right already tells.

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

MAX_TYPE = 20
# The ten scikit-learn declares, and no other name: `set_user_request` may be yours.
PHANTOM = re.compile(r"set_(fit|partial_fit|predict|predict_proba|predict_log_proba|decision_function|score|split"
                     r"|transform|inverse_transform)_request")
# The class a method is shown on, as ty writes it, then as pyrefly does.
OWNER = re.compile(r"^bound method (\w+)\.|^def \w+\(\s*self\s*:\s*(\w+)")
WORDS = {2: "method", 3: "function", 7: "class", 9: "module"}  # CompletionItemKind
VALUES = {22, 12, None}  # the kinds ty gives a value: Struct, Value for a literal, none for Unknown
GENERIC = re.compile(r"\[[^\[\]]*\]")
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


def short(kind, text):
    if kind in WORDS:
        return WORDS[kind]
    if "\n" in text:
        return ""
    while "[" in text and (bare := GENERIC.sub("", text)) != text:  # innermost first
        text = bare
    return text if len(text) <= MAX_TYPE else text[: MAX_TYPE - 1] + "…"


def tidy(body, drop=True, real={}, complete=True):
    try:
        message = json.loads(body)
        result = message["result"]
        items = result["items"] if isinstance(result, dict) else result
        kept = []
        for item in items:
            details = item.get("labelDetails") or {}
            text = details.get("description") or item.get("detail") or ""
            if drop and PHANTOM.fullmatch(item["label"]):
                owner = OWNER.match(text)
                owner = owner and (owner[1] or owner[2])
                if owner in real and item["label"] not in real[owner]:
                    continue
            if word := short(item.get("kind"), text):
                item["labelDetails"] = {**details, "description": word}
            if not PYREFLY and item.get("kind") not in WORDS:
                item.pop("documentation", None)
                if item.get("kind") in VALUES:
                    item["kind"] = 5  # Field
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
    def row(name, kind, text, pyrefly=False):
        return {"label": name, "kind": kind, **({"detail": text} if pyrefly else {"labelDetails": {"description": text}})}

    rows = [(row("split", 2, "bound method StratifiedKFold.split(X, y, groups=None) -> Unknown"), "method"),
            (row("set_fit_request", 2, "bound method A.set_fit_request(**kwargs) -> Unknown"), "method"),
            (row("set_score_request", 2, "bound method A.set_score_request(**kwargs) -> Unknown"), None),
            (row("set_user_request", 2, "bound method A.set_user_request(user) -> None"), "method"),
            (row("set_params", 2, "bound method A.set_params(**params) -> Unknown"), "method"),
            (row("n_splits", 22, "int"), "int"),
            (row("coef_", 22, "Unknown | ndarray[tuple[Any, ...], dtype[Unknown]] | csr_matrix"), "Unknown | ndarray |…"),
            (row("KFold", 7, "<class 'KFold'>"), "class"),
            (row("predict", 2, "def predict(\n    self: A,\n    X: ndarray\n) -> ndarray: ...", pyrefly=True), "method"),
            (row("set_predict_request", 2, "def set_predict_request(\n    self: A,\n    **kwargs: Unknown\n) -> Unknown: ...", pyrefly=True), None),
            (row("classes_", 5, "ndarray[Any, dtype[Any]]", pyrefly=True), "ndarray"),
            ({"label": "for", "kind": 14}, "")]
    body = json.dumps({"id": 1, "result": {"isIncomplete": True, "items": [item for item, _ in rows]}}).encode()

    def labels(**options):
        items = json.loads(tidy(body, **options))["result"]["items"]
        return [(i["label"], (i.get("labelDetails") or {}).get("description", "")) for i in items]

    want = [(item["label"], expected) for item, expected in rows if expected is not None]
    assert labels(real={"A": {"set_fit_request"}}) == want, labels(real={"A": {"set_fit_request"}})
    assert [name for name, _ in labels()] == [item["label"] for item, _ in rows], labels()  # a class the table lacks
    assert [name for name, _ in labels(drop=False, real={"A": set()})] == [item["label"] for item, _ in rows]
    assert json.loads(tidy(body))["result"]["isIncomplete"] is False
    assert json.loads(tidy(body, complete=False))["result"]["isIncomplete"] is True
    many = json.dumps({"id": 1, "result": {"isIncomplete": True, "items": [{"label": str(n)} for n in range(LIMIT)]}}).encode()
    assert json.loads(tidy(many))["result"]["isIncomplete"] is True
    assert turned_off("dropSetRequests", '{\n    "tyFilter.dropSetRequests": false,\n}')
    assert not turned_off("dropSetRequests", '{\n    // "tyFilter.dropSetRequests": false,\n    "tyFilter.dropSetRequests": true\n}')
    documented = json.dumps({"id": 1, "result": {"items": [{"label": "n_splits", "kind": 22, "documentation": "int([x])"},
                                                           {"label": "split", "kind": 2, "documentation": "Generate"}]}}).encode()
    documented = json.loads(tidy(documented))["result"]["items"]
    assert ["documentation" in item for item in documented] == [PYREFLY, True]
    assert [item["kind"] for item in documented] == [22 if PYREFLY else 5, 2]
    assert tidy(b"not json") == b"not json"
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
