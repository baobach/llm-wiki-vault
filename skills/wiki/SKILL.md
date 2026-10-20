---
name: wiki
description: Rebuild Index.md and propose fleeting notes ready for promotion into Literature or Permanent notes. Use when the user asks to update the index, refresh the wiki, or review notes for promotion.
---

# /wiki

Hermes Agent: do not run this skill. Tell the user it belongs to Claude Code
or Codex (see the roles in `AGENTS.md`).

## Rebuild the index
1. Read the frontmatter of every note in the three note folders.
2. Group notes by their `topic:` and `tags:` links. Section names follow the
   clusters you find; a note may appear in several sections. Notes without any
   topic go under `## Uncategorized`. Don't guess a topic for them.
3. List Literature and Permanent notes one per line with a one-line summary;
   fleeting notes of a section may share one comma-separated line.
4. Refresh `## Recently Active` (15 newest by `updated:` or `created:`).
5. Take the write lock, write `Index.md`, log one line, release the lock.

## Propose promotions
1. Find fleeting notes with real substance, alone or in groups on one theme.
2. Show a shortlist, each with one line on why it is ready. Create nothing yet.
3. Take the write lock. For each item the user approves, write a synthesized
   note in `Literature Notes/` with `sources:` listing the fleeting notes, and
   append `Promoted to [[New Note]]` to each source note.
4. Log one line per promotion, then release the lock.
