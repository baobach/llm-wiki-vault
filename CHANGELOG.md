# Changelog

## 0.1.0 (2026-10-20)

First release.

- `install.sh`: scaffolds the vault (folders, `AGENTS.md`, `CLAUDE.md`, `Index.md`, `Log.md`, note template, `.gitignore`), installs the skills for Claude Code (`.claude/skills/`) and Codex/Hermes (`.agents/skills/`), copies `wiki_lint.py`, and runs `git init`. Never overwrites files; `--update-skills` replaces skills with a backup.
- Skills: `/digest`, `/wiki`, `/qna`, `/lint`, `/explain`.
- `wiki_lint.py`: missing frontmatter, broken wikilinks, links into `raw/`, isolated notes.
- `AGENTS.md`: folder roles, frontmatter schema, rules, light ASD-STE100 writing style, write lock, git sync, agent roles.
