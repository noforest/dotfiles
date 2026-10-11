#!/usr/bin/python3
"""ty for VS Code with a tidier suggestion list. Set as "ty.path" in settings.json.

Runs the ty bundled with the VS Code extension and edits one kind of message
on its way back, the completion lists:
  - the type shown at the right of each row is cut to MAX_TYPE characters
    (the full type stays in the details panel);
  - scikit-learn's `set_*_request` methods are dropped: the library declares
    all ten of them for type checkers only, on every estimator.

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
BOUND_METHOD = re.compile(r"^bound method [\w.]+")  # the name is already the row's label


def shorten(text):
    text = BOUND_METHOD.sub("", text)
    return text if len(text) <= MAX_TYPE else text[: MAX_TYPE - 1] + "…"


def tidy(body):
    try:
        message = json.loads(body)
        result = message["result"]
        items = result["items"] if isinstance(result, dict) else result
        kept = []
        for item in items:
            if PHANTOM.fullmatch(item["label"]):
                continue
            details = item.get("labelDetails")
            if details and details.get("description"):
                details["description"] = shorten(details["description"])
            kept.append(item)
        if isinstance(result, dict):
            result["items"] = kept
        else:
            message["result"] = kept
        return json.dumps(message, separators=(",", ":")).encode()
    except Exception:
        return body


if sys.argv[1:] == ["--self-test"]:
    def rows(*pairs):
        items = [{"label": name, "labelDetails": {"description": kind}} for name, kind in pairs]
        body = json.dumps({"id": 1, "result": {"items": items}}, separators=(",", ":")).encode()
        return [(i["label"], i["labelDetails"]["description"]) for i in json.loads(tidy(body))["result"]["items"]]

    split = ("split", "bound method StratifiedKFold.split(X, y, groups=None) -> Unknown")
    quoted = ("mode", 'Literal["a", "b"] | None | int')
    cut = [("split", "(X, y, groups=None)…"), ("mode", 'Literal["a", "b"] |…')]
    assert rows(split, quoted) == cut, rows(split, quoted)
    with_phantom = rows(split, ("set_fit_request", "bound method A.set_fit_request(**kwargs) -> Unknown"), quoted, ("set_params", "int"))
    assert with_phantom == cut + [("set_params", "int")], with_phantom
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
        body = tidy(body)
    out.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
    out.flush()
sys.exit(server.wait())
