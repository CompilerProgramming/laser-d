#!/usr/bin/env python3
"""Generate Markdown mirrors of reviewed Laser-D Ddoc specification chapters."""

from __future__ import annotations

import html
import re
import shutil
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "spec"
OUTPUT_DIR = ROOT / "spec-markdown"
STATUS_FILE = ROOT / "FEATURE_STATUS.md"

ROW_RE = re.compile(
    r"^\| (?P<title>.+?) \(`(?P<file>[^`]+\.dd)`\) "
    r"\| (?P<status>Supported|Restricted|Rejected) \|"
)


def split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    index = 0
    while index < len(text):
        if text.startswith("$(", index):
            depth += 1
            index += 2
            continue
        if text[index] == "(":
            depth += 1
        elif text[index] == ")" and depth:
            depth -= 1
        elif text[index] == "," and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
        index += 1
    parts.append(text[start:].strip())
    return parts


def macro_parts(body: str) -> tuple[str, list[str]]:
    match = re.match(r"\s*([^\s,]+)(?:\s+([\s\S]*))?$", body)
    if not match:
        return "", []
    name = match.group(1)
    remainder = match.group(2) or ""
    return name, split_top_level(remainder)


def find_macro_end(text: str, start: int) -> int:
    depth = 1
    index = start + 2
    while index < len(text):
        if text.startswith("$(", index):
            depth += 1
            index += 2
            continue
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
            if depth == 0:
                return index
        index += 1
    raise ValueError(f"unclosed Ddoc macro at character {start}")


def clean_inline(text: str) -> str:
    text = html.unescape(text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" *\n *", " ", text)
    return text.strip()


class Converter:
    def __init__(self) -> None:
        self.unknown: set[str] = set()

    def convert(self, text: str) -> str:
        output: list[str] = []
        index = 0
        while index < len(text):
            start = text.find("$(", index)
            if start < 0:
                output.append(text[index:])
                break
            output.append(text[index:start])
            end = find_macro_end(text, start)
            output.append(self.render_macro(text[start + 2 : end]))
            index = end + 1
        return "".join(output)

    def render_args(self, args: list[str]) -> list[str]:
        return [self.convert(arg).strip() for arg in args]

    def render_macro(self, body: str) -> str:
        name, raw_args = macro_parts(body)
        args = self.render_args(raw_args)
        upper = name.upper()

        if upper in {"COMMENT", "HEADERNAV_TOC", "SPEC_FOOTER"}:
            return ""
        if upper in {"LPAREN"}:
            return "("
        if upper in {"RPAREN"}:
            return ")"
        if upper in {"AMP"}:
            return "&"
        if upper in {"PERCENT"}:
            return "%"
        if upper in {"TIMES"}:
            return "×"
        if upper in {"NDASH"}:
            return "–"
        if upper in {"SINGLEQUOTE"}:
            return "'"
        symbol_macros = {
            "BACKTICK": "`",
            "CODE_AMP": "&",
            "CODE_LCURL": "{",
            "CODE_RCURL": "}",
            "COMMA": ",",
            "GAMMA": "γ",
            "GT": ">",
            "HASH": "#",
            "LT": "<",
            "UNDERSCORE": "_",
            "ROOT_DIR": "../",
        }
        if upper in symbol_macros:
            return symbol_macros[upper]
        grammar_symbols = {
            "ASSIGNEXPRESSION": "AssignExpression",
            "EXPRESSION": "Expression",
            "IDENTIFIER": "Identifier",
            "PSSCOPE": "scope statement",
            "PSSEMI_PSCURLYSCOPE": "statement",
            "PSSEMI_PSCURLYSCOPE_LIST": "statement list",
        }
        if upper in grammar_symbols:
            return grammar_symbols[upper]
        if upper in {"GSELF", "GDEPRECATED", "GRESERVED"}:
            return clean_inline(" ".join(args)) or name
        if upper == "D]":
            return "]"

        if upper in {"SPEC_S", "D_S"}:
            title = clean_inline(args[0]) if args else "Untitled"
            body_text = ", ".join(args[1:]) if len(args) > 1 else ""
            return f"# {title}\n\n{body_text}\n"

        if upper in {"H1", "H2", "H3", "H4", "H5", "H6"}:
            level = int(upper[1])
            return f"\n\n{'#' * level} {clean_inline(' '.join(args))}\n\n"

        if upper in {"SECTION2", "SECTION3"}:
            level = 2 if upper == "SECTION2" else 3
            title = clean_inline(args[0]) if args else ""
            body_text = "\n\n".join(args[1:])
            return f"\n\n{'#' * level} {title}\n\n{body_text}\n\n"

        if upper in {
            "LNAME2",
            "LEGACY_LNAME2",
            "LNAME",
            "GNAME",
        }:
            anchor = clean_inline(args[0]) if args else ""
            label = clean_inline(args[-1]) if args else anchor
            return f'<a id="{anchor}"></a>{label}'

        if upper in {"P", "P_LASER_D"}:
            content = ", ".join(arg for arg in args if arg)
            if upper == "P_LASER_D":
                return self.callout("Laser-D", content)
            return f"\n\n{content}\n\n"

        callout_labels = {
            "LASER_NORMATIVE": "Laser-D normative",
            "LASER_SUPPORTED": "Supported in Laser-D",
            "LASER_REJECTED": "Rejected in Laser-D",
            "LASER_EXCLUDED": "Excluded from Laser-D",
            "LASER_UNDER_REVIEW": "Under review",
            "NOTE": "Note",
            "RATIONALE": "Rationale",
            "BEST_PRACTICE": "Best practice",
            "IMPLEMENTATION_DEFINED": "Implementation-defined",
            "UNDEFINED_BEHAVIOR": "Undefined behavior",
        }
        if upper in callout_labels:
            return self.callout(callout_labels[upper], ", ".join(args))

        if upper in {"D", "CODE", "CODE_HIGHLIGHT", "TT", "I", "B", "EM", "STRONG", "RED"}:
            content = clean_inline(", ".join(args))
            if upper in {"D", "CODE", "CODE_HIGHLIGHT", "TT"}:
                content = content.replace("`", "\\`")
                return f"`{content}`"
            marker = "**" if upper in {"B", "STRONG"} else "*"
            return f"{marker}{content}{marker}"

        if upper in {"D_CODE", "CODE2"}:
            return self.code_block("\n".join(args), "d")
        if upper in {"CCODE"}:
            return self.code_block("\n".join(args), "c")
        if upper in {"CONSOLE"}:
            return self.code_block("\n".join(args), "console")
        if upper in {"GRAMMAR", "GRAMMAR_LEX", "GRAMMAR_INLINE"}:
            return self.code_block("\n".join(args), "text")
        if upper in {"RUNNABLE_EXAMPLE"}:
            return self.code_block("\n".join(args), "d")
        if upper in {"CPPLISTING"}:
            return self.code_block("\n".join(args), "cpp")

        if upper in {"UL", "OL", "LIST"}:
            return self.render_list(raw_args, ordered=upper == "OL")
        if upper == "LI":
            return clean_inline(", ".join(args))

        if upper in {
            "TABLE",
            "TABLE2",
            "TABLE_2COLS",
            "TABLE_3COLS",
            "LONGTABLE_2COLS",
            "TABLE_SPECIAL",
        }:
            return self.render_table(raw_args)
        if upper in {"THEAD", "TROW", "TROW_EXPLANATORY"}:
            return " | ".join(clean_inline(arg) for arg in args)
        if upper == "MULTICOLS":
            return self.render_list(raw_args[1:] if len(raw_args) > 1 else raw_args, False)
        if upper == "MIDRULE":
            return ""
        if upper == "DL":
            return "\n\n" + "\n".join(args) + "\n\n"
        if upper == "DT":
            return f"\n**{clean_inline(', '.join(args))}**\n"
        if upper == "DD":
            return f": {clean_inline(', '.join(args))}\n"
        if upper == "BLOCKQUOTE_BY":
            attribution = clean_inline(args[0]) if args else ""
            quotation = clean_inline(" ".join(args[1:]))
            return f"\n\n> {quotation}\n>\n> — {attribution}\n\n"

        if upper in {
            "LINK",
            "LINK2",
            "RELATIVE_LINK2",
            "DDSUBLINK",
            "DDLINK",
            "REF",
            "REF1",
            "GLINK",
            "GLINK2",
            "GLINK_LEX",
            "LEGACY_LINK2",
            "MREF",
        }:
            return self.render_link(name, args)

        if upper in {
            "ARGS",
            "ARG",
            "METACODE",
            "IOTA",
            "OPT",
            "SUBSCRIPT",
            "SUPERSCRIPT",
            "BR",
            "BR2",
            "DDOC_BLANKLINE",
        }:
            if upper == "SUBSCRIPT":
                return f"<sub>{clean_inline(', '.join(args))}</sub>"
            if upper == "SUPERSCRIPT":
                return f"<sup>{clean_inline(', '.join(args))}</sup>"
            if upper in {"BR", "BR2", "DDOC_BLANKLINE"}:
                return "\n"
            if upper == "OPT":
                return f"[{clean_inline(' '.join(args))}]"
            return clean_inline(", ".join(args))

        if upper.startswith("SPEC_RUNNABLE_EXAMPLE"):
            return self.code_block("\n".join(args), "d")
        if upper.startswith("SPEC_SUBNAV"):
            return ""

        if upper in {"HTMLTAG", "HTMLTAG2", "HTMLTAG3", "HTMLTAG3V", "DIVC"}:
            return args[-1] if args else ""

        if upper == "CODE::OPERATOR":
            content = "::operator " + clean_inline(" ".join(args))
            return f"`{content}`"

        if name and name[0].islower():
            return f"$({body})"

        self.unknown.add(name)
        return " ".join(arg for arg in args if arg)

    @staticmethod
    def code_block(content: str, language: str) -> str:
        content = content.strip()
        content = re.sub(r"^-{3,}\s*$", "", content, flags=re.MULTILINE).strip()
        content = re.sub(r'<a id="[^"]+"></a>', "", content)
        content = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", content)
        content = content.replace("**", "")
        content = content.replace("`", "")
        return f"\n\n```{language}\n{content}\n```\n\n"

    @staticmethod
    def callout(label: str, content: str) -> str:
        content = content.strip()
        if "\n" not in content:
            return f"\n\n> **{label}:** {clean_inline(content)}\n\n"
        lines = [f"> **{label}:**", ">"]
        for line in content.splitlines():
            lines.append(f"> {line}" if line else ">")
        return "\n\n" + "\n".join(lines) + "\n\n"

    def render_list(self, raw_args: list[str], ordered: bool) -> str:
        source = ",".join(raw_args)
        items: list[str] = []
        index = 0
        while True:
            start = source.find("$(LI", index)
            if start < 0:
                break
            end = find_macro_end(source, start)
            _, item_args = macro_parts(source[start + 2 : end])
            item = clean_inline(self.convert(", ".join(item_args)))
            items.append(item)
            index = end + 1
        if not items:
            items = [clean_inline(arg) for arg in self.render_args(raw_args) if arg]
        lines = []
        for number, item in enumerate(items, start=1):
            prefix = f"{number}." if ordered else "-"
            lines.append(f"{prefix} {item}")
        return "\n\n" + "\n".join(lines) + "\n\n"

    def render_table(self, raw_args: list[str]) -> str:
        rows: list[list[str]] = []
        source = ",".join(raw_args[1:] if len(raw_args) > 1 else raw_args)
        index = 0
        while index < len(source):
            matches = [
                (source.find("$(THEAD", index), "THEAD"),
                (source.find("$(TROW", index), "TROW"),
            ]
            matches = [(position, kind) for position, kind in matches if position >= 0]
            if not matches:
                break
            start, _ = min(matches)
            end = find_macro_end(source, start)
            _, cell_args = macro_parts(source[start + 2 : end])
            rows.append(
                [
                    clean_inline(self.convert(cell)).replace("|", "\\|")
                    for cell in cell_args
                ]
            )
            index = end + 1
        if not rows:
            return "\n\n" + clean_inline(self.convert(source)) + "\n\n"
        width = max(len(row) for row in rows)
        rows = [row + [""] * (width - len(row)) for row in rows]
        header = rows[0]
        body = rows[1:]
        lines = [
            "| " + " | ".join(header) + " |",
            "| " + " | ".join("---" for _ in range(width)) + " |",
        ]
        lines.extend("| " + " | ".join(row) + " |" for row in body)
        return "\n\n" + "\n".join(lines) + "\n\n"

    @staticmethod
    def render_link(name: str, args: list[str]) -> str:
        if not args:
            return ""
        label = clean_inline(args[-1])
        target = clean_inline(args[0])
        if name.upper() in {"GLINK", "GLINK2", "GLINK_LEX", "REF", "REF1"}:
            return label
        if name.upper() == "MREF":
            return ".".join(clean_inline(arg) for arg in args)
        target = target.replace("$(ROOT_DIR)", "../")
        target = re.sub(r"^(?:spec/)?([^#]+)\.html", r"\1.md", target)
        if name.upper() == "RELATIVE_LINK2":
            target = f"#{target}"
        elif name.upper() == "DDSUBLINK" and len(args) >= 3:
            target = f"{clean_inline(args[0])}.md#{clean_inline(args[1])}"
            label = clean_inline(args[-1])
        elif name.upper() == "DDLINK":
            target = f"{target}.md" if not target.endswith(".md") else target
        if not target or target == label:
            return label
        return f"[{label}]({target})"


def preprocess(source: str) -> str:
    source = source.lstrip("\ufeff")
    if source.startswith("Ddoc"):
        source = source[4:]
    source = re.sub(r"\nMacros:\s*[\s\S]*$", "", source)
    source = re.sub(
        r"(?ms)^[ \t]*-{3,}[ \t]*\r?\n(.*?)^[ \t]*-{3,}[ \t]*$",
        lambda match: f"\n$(D_CODE {match.group(1).strip()})\n",
        source,
    )
    return source


def normalize(markdown: str) -> str:
    markdown = markdown.replace("\r\n", "\n")
    markdown = re.sub(r"[ \t]+\n", "\n", markdown)
    markdown = re.sub(r"\n{3,}", "\n\n", markdown)
    markdown = re.sub(r"\]\(([^)]+)\.dd([)#])", r"](\1.md\2", markdown)
    return markdown.strip() + "\n"


def reviewed_chapters() -> list[tuple[str, str, str]]:
    chapters: list[tuple[str, str, str]] = []
    for line in STATUS_FILE.read_text(encoding="utf-8").splitlines():
        match = ROW_RE.match(line)
        if match:
            chapters.append(
                (match.group("title"), match.group("file"), match.group("status"))
            )
    return chapters


def make_index(chapters: list[tuple[str, str, str]]) -> str:
    lines = [
        "# Laser-D language specification",
        "",
        "This directory is the Markdown mirror of reviewed Laser-D specification "
        "chapters. The existing Ddoc sources remain in `spec/` during migration.",
        "",
        "Files are generated by `tools/ddoc_to_markdown.py`. Edit the normative "
        "Ddoc source until Markdown becomes authoritative, then regenerate.",
        "",
        "| Chapter | Status | Source |",
        "| --- | --- | --- |",
    ]
    for title, filename, status in chapters:
        md_name = Path(filename).with_suffix(".md").name
        lines.append(
            f"| [{title}]({md_name}) | {status} | "
            f"[`spec/{filename}`](../spec/{filename}) |"
        )
    lines.extend(
        [
            "",
            "Chapters marked Undecided in `FEATURE_STATUS.md` are intentionally "
            "not mirrored yet.",
            "",
        ]
    )
    return "\n".join(lines)


def redirect_unmigrated_links() -> None:
    available = {path.name for path in OUTPUT_DIR.glob("*.md")}
    link_re = re.compile(r"\]\((?P<target>[^)#\s]+\.md)(?P<anchor>#[^)]+)?\)")
    for path in OUTPUT_DIR.glob("*.md"):
        text = path.read_text(encoding="utf-8")

        def replace(match: re.Match[str]) -> str:
            target = match.group("target")
            anchor = match.group("anchor") or ""
            basename = Path(target).name
            if target.startswith(("http://", "https://")):
                return match.group(0)
            if basename in available:
                return f"]({basename}{anchor})"
            source = SOURCE_DIR / Path(basename).with_suffix(".dd")
            if source.exists():
                return f"](../spec/{source.name})"
            web_target = target.removeprefix("../")
            if web_target.startswith("articles/") or basename.startswith("dmd"):
                web_target = str(Path(web_target).with_suffix(".html")).replace("\\", "/")
                return f"](https://dlang.org/{web_target}{anchor})"
            return match.group(0)

        path.write_text(link_re.sub(replace, text), encoding="utf-8", newline="\n")


def main() -> int:
    chapters = reviewed_chapters()
    if not chapters:
        print("no reviewed chapters found", file=sys.stderr)
        return 1

    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)
    OUTPUT_DIR.mkdir()

    all_unknown: dict[str, list[str]] = {}
    for title, filename, status in chapters:
        source_path = SOURCE_DIR / filename
        converter = Converter()
        converted = normalize(converter.convert(preprocess(source_path.read_text(encoding="utf-8"))))
        frontmatter = (
            "---\n"
            f"title: {title}\n"
            f"status: {status.lower()}\n"
            f"source: ../spec/{filename}\n"
            "---\n\n"
        )
        destination = OUTPUT_DIR / Path(filename).with_suffix(".md").name
        destination.write_text(frontmatter + converted, encoding="utf-8", newline="\n")
        if converter.unknown:
            all_unknown[filename] = sorted(converter.unknown)

    (OUTPUT_DIR / "README.md").write_text(
        make_index(chapters), encoding="utf-8", newline="\n"
    )
    redirect_unmigrated_links()

    unresolved: list[str] = []
    for path in OUTPUT_DIR.glob("*.md"):
        if re.search(r"\$\([A-Z_][A-Za-z0-9_]*", path.read_text(encoding="utf-8")):
            unresolved.append(path.name)

    if all_unknown:
        for filename, names in all_unknown.items():
            print(f"{filename}: unknown macros: {', '.join(names)}", file=sys.stderr)
    if unresolved:
        print(
            "unresolved Ddoc macro syntax in: " + ", ".join(sorted(unresolved)),
            file=sys.stderr,
        )
    if all_unknown or unresolved:
        return 1

    print(f"generated {len(chapters)} chapters in {OUTPUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
