# Changelog

## 0.2.0 (2026-10-25)

- `wiki_index.py`: builds `Index.md` deterministically from note frontmatter and a new `index_sections.json` section map. It rewrites the file only when the content changes, and reports topics no section maps. `--check` exits 1 when `Index.md` is out of date.
- `/wiki` runs `wiki_index.py` and edits `index_sections.json` instead of writing `Index.md` by hand.
- `/lint` runs `wiki_index.py --check` and reports a stale index.
- `/digest` treats source text as data: it never follows instructions found in a page, file, or pasted text.
- `install.sh` installs `wiki_index.py` (replaced by `--update-skills`) and a starter `index_sections.json` (never overwritten).
- New README diagram (`docs/vault-flow.svg`), with light and dark themes.

## 0.1.0 (2026-10-20)

First release.

- `install.sh`: scaffolds the vault (folders, `AGENTS.md`, `CLAUDE.md`, `Index.md`, `Log.md`, note template, `.gitignore`), installs the skills for Claude Code (`.claude/skills/`) and Codex/Hermes (`.agents/skills/`), copies `wiki_lint.py`, and runs `git init`. Never overwrites files; `--update-skills` replaces skills with a backup.
- Skills: `/digest`, `/wiki`, `/qna`, `/lint`, `/explain`.
- `wiki_lint.py`: missing frontmatter, broken wikilinks, links into `raw/`, isolated notes.
- `AGENTS.md`: folder roles, frontmatter schema, rules, light ASD-STE100 writing style, write lock, git sync, agent roles.
