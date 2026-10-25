#!/usr/bin/env python3
"""
wiki_index.py: deterministic Index.md builder for /wiki (llm-wiki-vault).

Usage: python3 path/to/wiki_index.py [vault-path] [--check]   (standard library only)

Reads frontmatter (type, created, updated, last_activity, tags, topic, project,
status, phase) from Fleeting/Literature/Permanent Notes and groups notes into the
sections in index_sections.json, next to this script. Same notes in, same
Index.md out: the file is rewritten only when its content changes.

  --check   write nothing; exit 1 when Index.md is out of date

After writing, prints topic/project targets and tags that no section maps, so
/wiki can extend index_sections.json. Choosing sections stays a judgment call;
applying them does not.
"""

import json
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path

NOTE_DIRS = ["Fleeting Notes", "Literature Notes", "Permanent Notes"]
TYPE_LABEL = {"literature": "Literature", "permanent": "Permanent"}
RECENT = 15
FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.S)
KEY = re.compile(r"^([A-Za-z_][\w-]*):\s*(.*)$")
ITEM = re.compile(r"^\s*-\s+(.*)$")
LINK = re.compile(r"\[\[([^\]|#]+)")
DATE = re.compile(r"\d{4}-\d{2}-\d{2}")
UPDATED = re.compile(r"^updated:.*$", re.M)


def unquote(v: str) -> str:
    v = v.strip()
    return v[1:-1] if len(v) > 1 and v[0] == v[-1] and v[0] in "\"'" else v


def frontmatter(text: str) -> dict:
    """Top-level keys only. Values are a string or a list of strings."""
    m = FRONTMATTER.match(text)
    if not m:
        return {}
    out, key, block = {}, None, False
    for line in m.group(1).splitlines():
        km = KEY.match(line)
        if km:
            key, value = km.group(1), km.group(2).strip()
            block = value in ("|", ">", "|-", ">-")
            if value.startswith("["):
                inner = value.strip("[]")
                out[key] = [unquote(x) for x in re.findall(r'"[^"]*"|\'[^\']*\'|[^,]+', inner) if x.strip()]
            else:
                out[key] = "" if block else unquote(value)
        elif key and not block and ITEM.match(line):
            prev = out.get(key)
            out[key] = (prev if isinstance(prev, list) else []) + [unquote(ITEM.match(line).group(1))]
    return out


def values(fm: dict, key: str) -> list[str]:
    v = fm.get(key) or []
    return v if isinstance(v, list) else [v]


def first_date(v) -> str:
    m = DATE.search(" ".join(v) if isinstance(v, list) else (v or ""))
    return m.group(0) if m else ""


class Note:
    def __init__(self, path: Path, rel: Path):
        fm = frontmatter(path.read_text(encoding="utf-8"))
        self.stem, self.rel = path.stem, rel
        t = fm.get("type")
        self.type = t if isinstance(t, str) and t else "fleeting"
        self.targets = {t.strip().split("/")[-1].lower()
                        for k in ("topic", "project") for v in values(fm, k) for t in LINK.findall(v)}
        self.tags = {"#" + t.lstrip("#").lower() for t in values(fm, "tags") if t.strip("# ")}
        self.is_project = "#project" in self.tags
        self.status = " ".join(values(fm, "status")).strip()
        self.phase = " ".join(values(fm, "phase")).strip()
        self.created = first_date(fm.get("created"))
        self.active = max(self.created, first_date(fm.get("updated")), first_date(fm.get("last_activity")))


def main(root: Path, check: bool) -> int:
    config = json.loads((Path(__file__).parent / "index_sections.json").read_text(encoding="utf-8"))
    notes = sorted((Note(p, p.relative_to(root)) for d in NOTE_DIRS for p in (root / d).rglob("*.md")),
                   key=lambda n: n.stem.lower())
    # a stem that exists twice anywhere (e.g. a Zotero copy in raw/) needs a path link
    stems = Counter(p.stem.lower() for p in root.rglob("*.md")
                    if not any(part.startswith(".") for part in p.relative_to(root).parts))
    notes_cfg = config.get("notes", {})

    def link(n: Note) -> str:
        if stems[n.stem.lower()] > 1:
            return f"[[{n.rel.with_suffix('').as_posix()}|{n.stem}]]"
        return f"[[{n.stem}]]"

    def label(n: Note, hub: bool) -> str:
        parts = []
        if n.is_project:
            parts.append("project hub" + (f", {n.status}" if n.status else ""))
        elif hub:
            parts.append("hub note")
        if n.type in TYPE_LABEL:
            parts.append(TYPE_LABEL[n.type])
        if n.phase and n.is_project:
            parts.append(n.phase)
        if n.stem in notes_cfg:
            parts.append(notes_cfg[n.stem])
        return f" *({'; '.join(parts)})*" if parts else ""

    mapped, placed, out = set(), set(), []
    for sec in config["sections"]:
        keys = {k.lower() for k in sec["match"]}
        mapped |= keys
        types = set(sec.get("types", []))
        members = [n for n in notes if (not types or n.type in types)
                   and (n.stem.lower() in keys or keys & (n.targets | n.tags))]
        if not members:
            continue
        placed.update(n.stem for n in members)
        hubs = [n for n in members if n.stem.lower() in keys or n.is_project]
        rest = [n for n in members if n not in hubs]
        out += [f"## {sec['title']}", ""]
        out += [f"- {link(n)}{label(n, True)}" for n in hubs]
        for t in ("literature", "permanent"):
            out += [f"- {link(n)}{label(n, False)}" for n in rest if n.type == t]
        fleeting = [n for n in rest if n.type not in TYPE_LABEL]
        if fleeting:
            out.append("- Fleeting: " + ", ".join(link(n) + label(n, False) for n in fleeting))
        out.append("")

    loose = [n for n in notes if n.stem not in placed]
    if loose:
        out += ["## Uncategorized", "",
                "*No `topic:`/`project:` target or tag that `index_sections.json` maps.*", "",
                ", ".join(link(n) + label(n, False) for n in loose), ""]

    recent = sorted((n for n in notes if n.active), key=lambda n: (n.active, n.stem.lower()), reverse=True)
    out += ["---", "", "## Recently Active", "",
            "*By latest of `created:`/`updated:`/`last_activity:` (most recent first).*", ""]
    out += [f"- {n.active}: {link(n)}{label(n, n.is_project)}" for n in recent[:RECENT]]

    by_type = Counter(n.type for n in notes)
    counts = ", ".join(f"{by_type[t]} {t.capitalize()}" for t in ("fleeting", "literature", "permanent", "daily") if by_type[t])
    here = Path(__file__).resolve().parent
    tool = (here.relative_to(root) if root in here.parents or here == root else here) / "wiki_index.py"
    head = ["---", 'title: "Index"', "type: index", f"updated: {date.today().isoformat()}", "---", "",
            "# Vault Index", "",
            f"Master catalog of this vault. Generated by `{tool.as_posix()}` from note frontmatter and "
            "`index_sections.json`; edit those, not this file. A note can appear in more than one section.", "",
            f"**{len(notes)} notes**: {counts}.", "", "---", ""]
    text = "\n".join(head + out) + "\n"

    index = root / "Index.md"
    old = index.read_text(encoding="utf-8") if index.exists() else ""
    same = UPDATED.sub("", old) == UPDATED.sub("", text)
    if check:
        print("Index.md is current" if same else "Index.md is out of date")
        return 0 if same else 1
    if same:
        print("Index.md unchanged")
    else:
        index.write_text(text, encoding="utf-8")
        print(f"Index.md written: {len(notes)} notes, {len(notes) - len(loose)} in sections, {len(loose)} uncategorized")

    unmapped = Counter(t for n in notes for t in n.targets if t not in mapped and t != n.stem.lower())
    if unmapped:
        print("\ntopic/project targets no section maps (count, target):")
        for t, c in sorted(unmapped.items(), key=lambda kv: (-kv[1], kv[0])):
            print(f"  {c:>3}  [[{t}]]")
    if loose:
        print("\nuncategorized notes:")
        for n in loose:
            print(f"  {n.rel.as_posix()}  tags: {', '.join(sorted(n.tags)) or '-'}")
    return 0


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--check"]
    sys.exit(main(Path(args[0] if args else ".").resolve(), "--check" in sys.argv))
