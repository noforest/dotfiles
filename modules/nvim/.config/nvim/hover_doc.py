#!/usr/bin/env python3
"""Print the docstring of a Python expression as Markdown, for the nvim hover float.

usage: hover_doc.py EXPR < buffer    the buffer's import lines are replayed to resolve EXPR
       hover_doc.py --check          run the self-check
"""
import inspect
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
    print("ok")


def main():
    if sys.argv[1:] == ["--check"]:
        return check()
    sys.path[0] = ""  # resolve the buffer's local imports from the cwd, not from this script's folder
    ns = {}
    for line in sys.stdin.read().splitlines():
        if line.startswith(("import ", "from ")):
            try:
                exec(line, ns)
            except Exception:
                pass
    print(to_markdown(inspect.getdoc(eval(sys.argv[1], ns)) or ""))


if __name__ == "__main__":
    main()
