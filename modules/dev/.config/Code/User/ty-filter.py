#!/usr/bin/python3
"""ty for VS Code with a tidier suggestion list. Set as "ty.path" in settings.json.

Runs the ty bundled with the VS Code extension and edits one kind of message
on its way back, the completion lists:
  - the type shown at the right of each row becomes a short word, as in the
    nvim config: the kind of a callable, class or module, and for a value its
    type without the generic arguments, cut to MAX_TYPE characters (the full
    type stays in the details panel);
  - scikit-learn's `set_*_request` methods are dropped: the library declares
    all ten of them for type checkers only, on every estimator. To keep them,
    add `"tyFilter.dropSetRequests": false` to settings.json. The file is read
    again for every list, so saving it is enough.

Everything else is passed through untouched, and what VS Code sends goes to
ty directly. If a list cannot be edited it is passed through as it came.

`ty-filter.py --self-test` checks the editing without starting ty.
"""
import glob
import json
import os
import re
import signal
import subprocess
import sys

MAX_TYPE = 20
PHANTOM = re.compile(r"set_\w+_request")
WORDS = {2: "method", 3: "function", 7: "class", 9: "module"}  # CompletionItemKind
GENERIC = re.compile(r"\[[^\[\]]*\]")
# Not a setting VS Code knows, hence read here, from the settings.json next to this script.
SETTINGS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "settings.json")
KEEP_PHANTOMS = re.compile(r'^\s*"tyFilter\.dropSetRequests"\s*:\s*false\b', re.M)


def drop_phantoms():
    try:
        with open(SETTINGS) as settings:
            return not KEEP_PHANTOMS.search(settings.read())
    except OSError:
        return True


def short(kind, text):
    if kind in WORDS:
        return WORDS[kind]
    while "[" in text and (bare := GENERIC.sub("", text)) != text:  # innermost first
        text = bare
    return text if len(text) <= MAX_TYPE else text[: MAX_TYPE - 1] + "…"


def tidy(body, drop=True):
    try:
        message = json.loads(body)
        result = message["result"]
        items = result["items"] if isinstance(result, dict) else result
        kept = []
        for item in items:
            if drop and PHANTOM.fullmatch(item["label"]):
                continue
            details = item.get("labelDetails")
            if details and details.get("description"):
                details["description"] = short(item.get("kind"), details["description"])
            kept.append(item)
        if isinstance(result, dict):
            result["items"] = kept
        else:
            message["result"] = kept
        return json.dumps(message, separators=(",", ":")).encode()
    except Exception:
        return body


if sys.argv[1:] == ["--self-test"]:
    rows = [("split", 2, "bound method StratifiedKFold.split(X, y, groups=None) -> Unknown", "method"),
            ("set_fit_request", 2, "bound method A.set_fit_request(**kwargs) -> Unknown", None),
            ("set_params", 2, "bound method A.set_params(**params) -> Unknown", "method"),
            ("n_splits", 22, "int", "int"),
            ("coef_", 22, "Unknown | ndarray[tuple[Any, ...], dtype[Unknown]] | csr_matrix", "Unknown | ndarray |…"),
            ("KFold", 7, "<class 'KFold'>", "class")]
    items = [{"label": name, "kind": kind, "labelDetails": {"description": kind_text}} for name, kind, kind_text, _ in rows]
    got = json.loads(tidy(json.dumps({"id": 1, "result": {"items": items}}).encode()))["result"]["items"]
    want = [(name, expected) for name, _, _, expected in rows if expected]
    assert [(i["label"], i["labelDetails"]["description"]) for i in got] == want, got
    kept = json.loads(tidy(json.dumps({"id": 1, "result": {"items": items}}).encode(), drop=False))["result"]["items"]
    assert [i["label"] for i in kept] == [name for name, *_ in rows], kept
    assert KEEP_PHANTOMS.search('{\n    "tyFilter.dropSetRequests": false,\n}')
    assert not KEEP_PHANTOMS.search('{\n    // "tyFilter.dropSetRequests": false,\n    "tyFilter.dropSetRequests": true\n}')
    assert tidy(b"not json") == b"not json"
    sys.exit(print("ok"))

# The newest installed extension, so that an update of ty is picked up by itself.
REAL = max(glob.glob(os.path.expanduser("~/.vscode/extensions/astral-sh.ty-*/bundled/libs/bin/ty")), key=os.path.getmtime)
if sys.argv[1:2] != ["server"]:
    os.execv(REAL, [REAL] + sys.argv[1:])

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
        body = tidy(body, drop_phantoms())
    out.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
    out.flush()
sys.exit(server.wait())
