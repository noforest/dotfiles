#!/usr/bin/env python3
"""Print the docstring of a Python expression as Markdown, for the nvim hover float.

usage: hover_doc.py EXPR < buffer    the buffer's imports are replayed to resolve EXPR
       hover_doc.py --check          run the self-check

A hover must not run the code of the file under the cursor. Only its import
statements are replayed, taken from the syntax tree so that nothing else on
their line comes along, and only against the packages installed for the
interpreter: the directory of the project is taken off the import path.
"""
import ast
import inspect
import os
import re
import sys


def inline(text):
    text = re.sub(r":\w+:`~?([^`]+)`", r"`\1`", text)  # :ref:`x`, :func:`~a.b`
    text = re.sub(r"``([^`]+)``", r"`\1`", text)
    return text.replace("`~", "`")  # `~numpy.random.Generator` displays as its last component in Sphinx


# ponytail: numpy/RST docstrings only, anything else passes through untouched.
# Swap for the docstring-to-markdown package if Google style ever matters.
def to_markdown(doc):
    lines = doc.splitlines()
    # numpy repeats the signature on the first line, the hover already shows it
    if lines and re.fullmatch(r"[\w.]+\(.*\)", lines[0].strip()):
        lines = lines[1:]
    out, in_code, i = [], False, 0
    while i < len(lines):
        line, text = lines[i], lines[i].strip()
        below = lines[i + 1].strip() if i + 1 < len(lines) else ""
        if in_code:
            if text:
                out.append(text)
            else:
                out += ["```", ""]
                in_code = False
        elif text.startswith(">>>"):
            out += ["```python", text]
            in_code = True
        elif text and len(below) >= 3 and below in (len(below) * "-", len(below) * "="):
            out.append("### " + text)
            i += 1  # skip the underline
        elif m := re.fullmatch(r"\.\. ([\w-]+)::\s*(.*)", text):
            out.append(f"***{m[1]}*** {inline(m[2])}".rstrip())
        elif m := re.fullmatch(r"(\*{0,2}\w[\w, ]*?) : (.+)", line):
            if out and out[-1] and not out[-1].startswith("### "):
                out.append("")  # set each parameter apart from the previous one
            out.append("**{}** : *{}*".format(m[1].replace("*", r"\*"), m[2]))
        else:
            # keep what was indented under its entry, with 2 spaces: 4 would render as a code block
            out.append(("  " if line[:1].isspace() else "") + inline(text))
        i += 1
    if in_code:
        out.append("```")
    return re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip()


def check():
    md = to_markdown(
        "choice(a, size=None)\n\nGenerates a sample\n\n"
        ".. versionadded:: 1.7.0\n\n.. note::\n    Use :ref:`random-quick-start` and ``rng``.\n\n"
        "Parameters\n----------\na : 1-D array-like or int\n    If an ndarray, a sample.\n"
        "*args : tuple\n    Extra.\n\n"
        "Examples\n--------\n>>> np.random.choice(5, 3)\narray([0, 3, 4]) # random\n\nDone."
    )
    assert md.startswith("Generates a sample"), md
    assert "***versionadded*** 1.7.0" in md, md
    assert "***note***\n  Use `random-quick-start` and `rng`." in md, md
    assert "### Parameters\n**a** : *1-D array-like or int*\n  If an ndarray, a sample.\n\n" in md, md
    assert "\n\n" + r"**\*args** : *tuple*" + "\n  Extra." in md, md
    assert "```python\n>>> np.random.choice(5, 3)\narray([0, 3, 4]) # random\n```\n\nDone." in md, md
    assert "----" not in md and "::" not in md, md
    assert to_markdown("plain text\n    kept") == "plain text\n  kept"

    # only imports are replayed: what shares their line, or sits elsewhere, never runs
    marker = "hover_doc_check_marker"
    source = (
        f"import sys; sys.modules['{marker}'] = 1\n"
        "from os import (\n    path,\n    sep,\n)\n"
        f"sys.modules['{marker}'] = 2\n"
        "from . import sibling\n"
    )
    ns = replay_imports(source)
    assert marker not in sys.modules, "code next to an import was executed"
    assert set(ns) - {"__builtins__"} == {"sys", "path", "sep"}, sorted(ns)
    # a buffer that does not parse still gives its one-line imports
    ns = replay_imports(f"import os; sys.modules['{marker}'] = 3\ndef broken(:\n")
    assert marker not in sys.modules and "os" in ns, sorted(ns)
    print("ok")


def import_nodes(source):
    """The top-level import statements of `source`, as syntax nodes.

    A buffer being edited often does not parse as a whole. Its lines are then
    read one by one, which still finds every import written on a single line.
    """
    try:
        body = ast.parse(source).body
    except SyntaxError:
        body = []
        for line in source.splitlines():
            if line.startswith(("import ", "from ")):
                try:
                    body += ast.parse(line).body
                except SyntaxError:
                    pass
    # level > 0 is a relative import, which has no meaning outside its package
    return [n for n in body if isinstance(n, ast.Import) or (isinstance(n, ast.ImportFrom) and n.level == 0)]


def replay_imports(source):
    """Runs the imports of `source`, and only them. Returns the resulting namespace."""
    ns = {}
    for node in import_nodes(source):
        try:
            exec(compile(ast.Module(body=[node], type_ignores=[]), "<imports>", "exec"), ns)
        except Exception:
            pass
    return ns


def main():
    if sys.argv[1:] == ["--check"]:
        return check()
    expr = sys.argv[1]
    if not re.fullmatch(r"[A-Za-z_][\w.]*", expr):
        return  # a dotted name and nothing else is evaluated
    # no code of the project: neither the cwd nor this script's folder on the import path
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path[:] = [p for p in sys.path if p and os.path.abspath(p) not in (here, os.getcwd())]
    print(to_markdown(inspect.getdoc(eval(expr, replay_imports(sys.stdin.read()))) or ""))


if __name__ == "__main__":
    main()
