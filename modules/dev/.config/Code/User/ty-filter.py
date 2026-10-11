#!/usr/bin/python3
"""ty for VS Code with a tidier suggestion list. Set as "ty.path" in settings.json.

Runs the ty bundled with the VS Code extension and edits one kind of message
on its way back, the completion lists:
  - the type shown at the right of each row becomes a short word, as in the
    nvim config: the kind of a callable, class or module, and for a value its
    type without the generic arguments, cut to MAX_TYPE characters (the full
    type stays in the details panel);
  - scikit-learn's `set_*_request` methods are dropped where the class does
    not have them. The library declares all ten for type checkers only, on
    every estimator, and creates the real ones when it is imported. Which
    class really has which is in ty-filter-sklearn.json, next to this script.
    A class missing from it keeps all ten, so that no method that exists is
    ever hidden;
  - the list is declared complete. ty flags every list as incomplete, so VS
    Code asks for a new one at each key, and ty answers nothing when the
    cursor is no longer at the end of the word, which is where a request sent
    one key earlier points. The popup then flickers or closes while a key is
    held. A complete list is narrowed by VS Code itself, as with pyrefly.
    Lists near ty's limit of a thousand entries are left as they are.

The last two can be turned off in settings.json, `"tyFilter.dropSetRequests":
false` and `"tyFilter.completeLists": false`. The file is read again for
every list, so saving it is enough.

Everything else is passed through untouched, and what VS Code sends goes to
ty directly. If a list cannot be edited it is passed through as it came.

`ty-filter.py --self-test` checks the editing without starting ty.
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
OWNER = re.compile(r"^bound method (\w+)\.")
WORDS = {2: "method", 3: "function", 7: "class", 9: "module"}  # CompletionItemKind
GENERIC = re.compile(r"\[[^\[\]]*\]")
HERE = os.path.dirname(os.path.abspath(__file__))
# Not settings VS Code knows, hence read here, from the settings.json next to this script.
SETTINGS = os.path.join(HERE, "settings.json")
LIMIT = 900  # with auto-import ty stops near a thousand entries: such a list really is incomplete
TABLE = os.path.join(HERE, "ty-filter-sklearn.json")


def turned_off(name, text):
    return bool(re.search(rf'^\s*"tyFilter\.{name}"\s*:\s*false\b', text, re.M))


def options():
    try:
        with open(SETTINGS) as settings:
            text = settings.read()
    except OSError:
        text = ""
    return {"drop": not turned_off("dropSetRequests", text), "complete": not turned_off("completeLists", text)}


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
            if drop and PHANTOM.fullmatch(item["label"]):
                owner = OWNER.match(details.get("description") or "")
                if owner and owner[1] in real and item["label"] not in real[owner[1]]:
                    continue
            if details.get("description"):
                details["description"] = short(item.get("kind"), details["description"])
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
    rows = [("split", 2, "bound method StratifiedKFold.split(X, y, groups=None) -> Unknown", "method"),
            ("set_fit_request", 2, "bound method A.set_fit_request(**kwargs) -> Unknown", "method"),
            ("set_score_request", 2, "bound method A.set_score_request(**kwargs) -> Unknown", None),
            ("set_user_request", 2, "bound method A.set_user_request(user) -> None", "method"),
            ("set_params", 2, "bound method A.set_params(**params) -> Unknown", "method"),
            ("n_splits", 22, "int", "int"),
            ("coef_", 22, "Unknown | ndarray[tuple[Any, ...], dtype[Unknown]] | csr_matrix", "Unknown | ndarray |…"),
            ("KFold", 7, "<class 'KFold'>", "class")]
    items = [{"label": name, "kind": kind, "labelDetails": {"description": kind_text}} for name, kind, kind_text, _ in rows]
    body = json.dumps({"id": 1, "result": {"isIncomplete": True, "items": items}}).encode()

    def labels(**options):
        return [(i["label"], i["labelDetails"]["description"]) for i in json.loads(tidy(body, **options))["result"]["items"]]

    want = [(name, expected) for name, _, _, expected in rows if expected]
    assert labels(real={"A": {"set_fit_request"}}) == want, labels(real={"A": {"set_fit_request"}})
    unknown_class = [name for name, _ in labels()]
    assert unknown_class == [name for name, *_ in rows], unknown_class
    assert [name for name, _ in labels(drop=False)] == [name for name, *_ in rows], labels(drop=False)
    assert json.loads(tidy(body))["result"]["isIncomplete"] is False
    assert json.loads(tidy(body, complete=False))["result"]["isIncomplete"] is True
    many = json.dumps({"id": 1, "result": {"isIncomplete": True, "items": [{"label": str(n)} for n in range(LIMIT)]}}).encode()
    assert json.loads(tidy(many))["result"]["isIncomplete"] is True
    assert turned_off("dropSetRequests", '{\n    "tyFilter.dropSetRequests": false,\n}')
    assert not turned_off("dropSetRequests", '{\n    // "tyFilter.dropSetRequests": false,\n    "tyFilter.dropSetRequests": true\n}')
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

# The newest installed extension, so that an update of ty is picked up by itself.
REAL = max(glob.glob(os.path.expanduser("~/.vscode/extensions/astral-sh.ty-*/bundled/libs/bin/ty")), key=os.path.getmtime)
if sys.argv[1:2] != ["server"]:
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
    if b'"labelDetails"' in body:
        body = tidy(body, real=setters, **options())
    out.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
    out.flush()
sys.exit(server.wait())
