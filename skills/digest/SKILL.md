---
name: digest
description: Turn a file in raw/, a URL, or pasted text into a new fleeting note that cites its origin. Use when the user drops a source into raw/, shares a link, or asks to digest or save something into the vault.
---

# /digest

1. Check `Log.md` and the `sources:` fields for the same source. If it was
   digested before, say so and ask before creating a second note.
2. Take the write lock (see `AGENTS.md`).
3. Read the source. Distill the ideas worth keeping into a few dense bullets;
   don't copy it.
4. Write `Fleeting Notes/<Title>.md` with the frontmatter from `AGENTS.md`.
   `sources:` holds the original URL or a plain description, never a `raw/` path.
5. Copy any image the note needs into `Files/` and embed it with `![[name.png]]`.
6. Link two or three related notes that `Index.md` lists.
7. Append to your log (`Log.md`; Hermes uses `Log-hermes.md`):
   `- <date> | <agent> | /digest | <source> -> [[New Note]]`.
8. Release the lock and tell the user the `raw/` file can now be removed.
