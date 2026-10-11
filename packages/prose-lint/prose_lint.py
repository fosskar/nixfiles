"""Flag LLM writing tells in markdown prose and in nix, shell and python comments.

usage: prose-lint FILE...

Prints `path:line:col: rule-id: message: match` per hit. Exits 1 on any hit
and 2 when a file cannot be read or scanned.
"""

import bisect
import io
import re
import sys
import tokenize
from dataclasses import dataclass
from pathlib import Path

import tomllib

RULES_PATH = Path(__file__).with_name("rules.toml")
RULE_KINDS = ("words", "phrases", "regex")

# BREAK replaces text outside the scanned region; nothing may match across it.
# MASK replaces code spans, quotes and URLs inside prose; a sentence-level
# regex may run across it, but words and phrases cannot match inside it.
BREAK = "\x01"
MASK = "\x00"

SEGMENT_SEP = re.compile(r"\n[ \t]*\n|" + BREAK + "+")

INLINE_MASKS = [
    re.compile(r"(?<!`)(`+)(?!`)(.+?)(?<!`)\1(?!`)", re.DOTALL),
    re.compile(r"\]\([^)]*\)"),
    re.compile(r"^[ \t]*\[[^\]\n]+\]:[ \t]*\S+", re.MULTILINE),
    re.compile(r"\b[a-z][a-z0-9+.-]*://\S+", re.IGNORECASE),
    re.compile(r"\bwww\.\S+", re.IGNORECASE),
    re.compile(r"</?[a-z!][^<>]*>", re.IGNORECASE),
    re.compile(r'"[^"]*"'),
]

MD_FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
MD_HTML_COMMENT = re.compile(r"<!--.*?(?:-->|\Z)", re.DOTALL)
SH_HEREDOC = re.compile(r"<<(-?)[ \t]*\\?(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")
SH_WORD_START = " \t\n;|&()<>"


class ScanError(Exception):
    pass


@dataclass(frozen=True)
class Rule:
    id: str
    message: str
    kind: str
    pattern: re.Pattern
    raw: bool
    examples: tuple


@dataclass(frozen=True, order=True)
class Hit:
    line: int
    col: int
    rule: str
    message: str
    text: str


def _literal(s):
    return re.escape(s).replace("'", "['\u2019]")


def _bounded(body, first, last):
    left = r"(?<![\w./-])" if re.match(r"\w", first) else ""
    right = r"(?![\w/-]|\.\w)" if re.match(r"\w", last) else ""
    return left + body + right


def _compile(kind, items):
    if kind == "regex":
        return re.compile("|".join(f"(?:{r})" for r in items), re.IGNORECASE)
    items = sorted(items, key=len, reverse=True)
    if kind == "words":
        alts = [_bounded(_literal(w), w[0], w[-1]) for w in items]
    else:
        alts = [
            _bounded(r"\s+".join(_literal(t) for t in p.split()), p[0], p[-1])
            for p in items
        ]
    return re.compile("|".join(alts), re.IGNORECASE)


def load_rules(path=RULES_PATH):
    with open(path, "rb") as f:
        data = tomllib.load(f)
    rules = []
    for entry in data["rule"]:
        kinds = [k for k in RULE_KINDS if k in entry]
        if len(kinds) != 1:
            raise ValueError(f"rule {entry['id']}: needs exactly one of {RULE_KINDS}")
        kind = kinds[0]
        rules.append(
            Rule(
                id=entry["id"],
                message=entry["message"],
                kind=kind,
                pattern=_compile(kind, entry[kind]),
                raw=entry.get("raw", False),
                examples=tuple(entry.get("examples", ())),
            )
        )
    return rules


class Region:
    """A same-length copy of the text where everything outside the scanned
    region is BREAK, so offsets map straight back to line and column."""

    def __init__(self, text, keep_all):
        self.text = text
        self.chars = list(text) if keep_all else [_break(c) for c in text]

    def keep(self, start, end):
        self.chars[start:end] = self.text[start:end]

    def drop(self, start, end):
        self.chars[start:end] = [_break(c) for c in self.text[start:end]]

    def blank(self, start, end):
        self.chars[start:end] = " " * len(self.text[start:end])

    def __str__(self):
        return "".join(self.chars)


def _break(c):
    return c if c.isspace() else BREAK


def _line_comment(text, region, i):
    end = text.find("\n", i)
    end = len(text) if end < 0 else end
    region.blank(i, i + 1)
    region.keep(i + 1, end)
    return end


def scan_md(text):
    region = Region(text, keep_all=True)
    fence = None
    pos = 0
    for line in text.split("\n"):
        end = pos + len(line)
        m = MD_FENCE.match(line)
        if fence:
            region.drop(pos, end)
            if (
                m
                and m.group(1)[0] == fence[0]
                and len(m.group(1)) >= len(fence)
                and not m.group(2).strip()
            ):
                fence = None
        elif m and not (m.group(1)[0] == "`" and "`" in m.group(2)):
            region.drop(pos, end)
            fence = m.group(1)
        pos = end + 1
    for m in MD_HTML_COMMENT.finditer(text):
        region.drop(m.start(), m.end())
    return region


def scan_nix(text):
    region = Region(text, keep_all=False)
    n = len(text)
    # each frame is "str", "istr", or a code frame holding its open-brace depth
    stack = [0]
    i = 0
    while i < n:
        top = stack[-1]
        c = text[i]
        if top == "str":
            if c == "\\":
                i += 2
            elif c == '"':
                stack.pop()
                i += 1
            elif text.startswith("$$", i):
                i += 2
            elif text.startswith("${", i):
                stack.append(0)
                i += 2
            else:
                i += 1
        elif top == "istr":
            if text.startswith("'''", i) or text.startswith("''$", i):
                i += 3
            elif text.startswith("''\\", i):
                i += 4
            elif text.startswith("''", i):
                stack.pop()
                i += 2
            elif text.startswith("$$", i):
                i += 2
            elif text.startswith("${", i):
                stack.append(0)
                i += 2
            else:
                i += 1
        elif c == "#":
            i = _line_comment(text, region, i)
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            end = n if end < 0 else end
            region.blank(i, i + 2)
            region.keep(i + 2, end)
            region.blank(end, end + 2)
            i = end + 2
        elif c == '"':
            stack.append("str")
            i += 1
        elif text.startswith("''", i):
            stack.append("istr")
            i += 2
        elif c.isalpha() or c == "_":
            i += 1
            while i < n and (text[i].isalnum() or text[i] in "_'-"):
                i += 1
        elif c == "{":
            stack[-1] += 1
            i += 1
        elif c == "}":
            if top == 0 and len(stack) > 1:
                stack.pop()
            else:
                stack[-1] -= 1
            i += 1
        else:
            i += 1
    return region


def _skip_quoted(text, i, quote):
    n = len(text)
    i += 1
    while i < n and text[i] != quote:
        i += 2 if text[i] == "\\" else 1
    return i + 1


def scan_sh(text):
    region = Region(text, keep_all=False)
    n = len(text)
    i = text.find("\n") if text.startswith("#!") else 0
    i = n if i < 0 else i
    heredocs = []
    while i < n:
        c = text[i]
        if c == "\n":
            i += 1
            for delim, strip in heredocs:
                while i < n:
                    end = text.find("\n", i)
                    end = n if end < 0 else end
                    line = text[i:end]
                    i = end + 1
                    if (line.lstrip("\t") if strip else line) == delim:
                        break
            heredocs = []
        elif c == "\\":
            i += 2
        elif c == "'":
            i = text.find("'", i + 1)
            i = n if i < 0 else i + 1
        elif c in '"`':
            i = _skip_quoted(text, i, c)
        elif text.startswith("$'", i):
            i = _skip_quoted(text, i + 1, "'")
        elif text.startswith("${", i):
            depth = 0
            i += 1
            while i < n:
                depth += {"{": 1, "}": -1}.get(text[i], 0)
                i += 1
                if depth == 0:
                    break
        elif text.startswith("$#", i):
            i += 2
        elif c == "#" and (i == 0 or text[i - 1] in SH_WORD_START):
            i = _line_comment(text, region, i)
        elif text.startswith("<<<", i):
            i += 3
        elif m := SH_HEREDOC.match(text, i):
            heredocs.append((m.group(3), m.group(1) == "-"))
            i = m.end()
        else:
            i += 1
    return region


def scan_py(text):
    region = Region(text, keep_all=False)
    starts = [0]
    for line in text.split("\n"):
        starts.append(starts[-1] + len(line) + 1)
    try:
        tokens = list(tokenize.generate_tokens(io.StringIO(text).readline))
    except (tokenize.TokenError, SyntaxError) as e:
        raise ScanError(f"cannot tokenize: {e}") from e
    for tok in tokens:
        if tok.type != tokenize.COMMENT:
            continue
        (row, col) = tok.start
        if row == 1 and tok.string.startswith("#!"):
            continue
        start = starts[row - 1] + col
        _line_comment(text, region, start)
    return region


SCANNERS = {"md": scan_md, "nix": scan_nix, "sh": scan_sh, "py": scan_py}


def _mask_inline(segment):
    chars = list(segment)
    for pattern in INLINE_MASKS:
        for m in pattern.finditer("".join(chars)):
            for k in range(m.start(), m.end()):
                if chars[k] != "\n":
                    chars[k] = MASK
    return "".join(chars)


def _segments(region):
    pos = 0
    for m in SEGMENT_SEP.finditer(region + BREAK):
        if m.start() > pos and not region[pos : m.start()].isspace():
            yield pos, m.start()
        pos = m.end()


def lint(text, kind, rules):
    region = str(SCANNERS[kind](text))
    segments = list(_segments(region))
    prose = list(region)
    for start, end in segments:
        prose[start:end] = _mask_inline(region[start:end])
    prose = "".join(prose)

    line_starts = [0] + [m.end() for m in re.finditer("\n", text)]
    hits = set()
    for rule in rules:
        source = region if rule.raw else prose
        for start, end in segments:
            for m in rule.pattern.finditer(source, start, end):
                line = bisect.bisect_right(line_starts, m.start())
                col = m.start() - line_starts[line - 1] + 1
                matched = " ".join(text[m.start() : m.end()].split())
                hits.add(Hit(line, col, rule.id, rule.message, matched))
    return sorted(hits)


def main(argv):
    rules = load_rules()
    status = 0
    for name in argv:
        kind = Path(name).suffix[1:]
        if kind not in SCANNERS:
            print(f"{name}: unsupported file type", file=sys.stderr)
            status = 2
            continue
        try:
            hits = lint(Path(name).read_text(encoding="utf-8"), kind, rules)
        except (OSError, UnicodeDecodeError, ScanError) as e:
            print(f"{name}: {e}", file=sys.stderr)
            status = 2
            continue
        for h in hits:
            print(f"{name}:{h.line}:{h.col}: {h.rule}: {h.message}: {h.text}")
        if hits and status == 0:
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
