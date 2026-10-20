---
name: explain
description: Build a self-contained HTML explainer page about a topic from the vault's notes, with inline SVG diagrams and citations, saved to outputs/. Use when the user asks for an explainer, a visual explanation, or an answer in HTML.
---

# /explain <topic>

Hermes Agent: do not run this skill. Tell the user it belongs to Claude Code
or Codex (see the roles in `AGENTS.md`).

1. Read `Index.md` and the notes on the topic. If the vault has little on it,
   say so and ask before you continue.
2. Plan one question for the page to answer, 3 to 6 sections, and a diagram
   for each relationship that prose explains badly.
3. Take the write lock. Write `outputs/explain-<topic>-<date>.html` as one file:
   inline CSS, JavaScript, and SVG; no network requests; light and dark mode.
4. Use only what the notes say. Mark outside facts as LLM-suggested.
5. End with the list of notes used, as `obsidian://open?vault=<vault>&file=<path>`
   links. Do not link the page from any note; it is discardable.
6. Log one line, release the lock, and tell the user the path.
