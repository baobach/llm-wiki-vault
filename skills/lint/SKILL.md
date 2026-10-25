---
name: lint
description: Health-check the vault for broken links, links into raw/, orphan notes, malformed frontmatter, contradictions, and missing concept notes. Use when the user asks to lint, audit, or clean up the vault.
---

# /lint

Hermes Agent: do not run this skill. Tell the user it belongs to Claude Code
or Codex (see the roles in `AGENTS.md`).

1. Run `python3 wiki_lint.py .` in the vault root for the mechanical checks.
   If the script is missing, check the same things with grep.
   Then run `python3 wiki_index.py . --check`. It writes nothing. Exit 1
   means `Index.md` is out of date: report it first and suggest `/wiki`.
2. Read pairs of notes on the same subject and look for contradicting claims.
3. Look for concepts mentioned in several notes that have no note of their own.
4. Take the write lock before the first write.
5. Auto-fix only mechanical problems with one obvious answer (a link that is a
   typo of an existing note, broken YAML syntax). Report everything else.
6. Write `outputs/lint-<date>.md`: fixes applied first, then findings by
   category, then anything you skipped or sampled instead of checking fully.
7. Log one line, then release the lock.
