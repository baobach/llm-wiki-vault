#!/usr/bin/env bash
#
# install.sh: set up an agent-maintained Zettelkasten vault (llm-wiki-vault).
# https://github.com/baobach/llm-wiki-vault
#
# Works with bash 3.2 (macOS default) and later. Touches nothing outside VAULT.

set -euo pipefail

REPO="baobach/llm-wiki-vault"
REF="${LLM_WIKI_VAULT_REF:-v0.2.0}"
SKILLS="digest wiki qna lint explain"
SKILL_DIRS=".claude/skills .agents/skills" # Claude Code / Codex and Hermes Agent

usage() {
  cat <<'EOF'
Usage: install.sh [options] [VAULT]

Set up (or extend) an Obsidian vault that Claude Code, Codex, and Hermes Agent
maintain with the /digest, /wiki, /qna, /lint, and /explain skills.

  VAULT              vault folder, created if missing (default: ~/external-brain)

Options:
  --update-skills    replace installed skills, wiki_lint.py, and wiki_index.py
                     with this version;
                     replaced files are kept as *.bak-<timestamp>
  --no-git           don't run git init
  --ref REF          tag or branch to download when not run from a clone
  -h, --help         show this help

Existing files are never overwritten, except skills and the two scripts with
--update-skills. AGENTS.md, index_sections.json, and your notes are never touched.
EOF
}

update=false
use_git=true
VAULT=""

while (($#)); do
  case "$1" in
  --update-skills)
    update=true
    shift
    ;;
  --no-git)
    use_git=false
    shift
    ;;
  --ref)
    [[ $# -ge 2 ]] || { echo "--ref needs a value" >&2; exit 1; }
    REF="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  *)
    VAULT="$1"
    shift
    ;;
  esac
done
VAULT="${VAULT:-$HOME/external-brain}"

# Where the kit's files come from: this clone, or a release tarball.
SRC=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$here/template/AGENTS.md" && -f "$here/skills/digest/SKILL.md" ]]; then
    SRC="$here"
  fi
fi
if [[ -z "$SRC" ]]; then
  command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "> downloading $REPO@$REF"
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" | tar -xz -C "$tmp"
  SRC="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -f "$SRC/template/AGENTS.md" ]] || { echo "download did not contain the kit" >&2; exit 1; }
fi

VERSION="$(cat "$SRC/VERSION")"
TODAY="$(date +%F)"
STAMP="$(date +%Y%m%d-%H%M%S)"
changed=0

# copy_new SRC DEST: copy unless DEST already exists
copy_new() {
  if [[ -e "$2" ]]; then
    echo "skip    $2 (exists)"
  else
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    echo "added   $2"
    changed=$((changed + 1))
  fi
}

# render_new SRC DEST: like copy_new, with __TODAY__ and __VERSION__ filled in
render_new() {
  if [[ -e "$2" ]]; then
    echo "skip    $2 (exists)"
  else
    sed -e "s/__TODAY__/$TODAY/g" -e "s/__VERSION__/$VERSION/g" "$1" >"$2"
    echo "added   $2"
    changed=$((changed + 1))
  fi
}

# install_file SRC DEST: add if missing; with --update-skills, replace a
# different file and keep the old one as DEST.bak-<timestamp>
updated=0
install_file() {
  if [[ ! -e "$2" ]]; then
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    echo "added   $2"
    changed=$((changed + 1))
  elif cmp -s "$1" "$2"; then
    echo "same    $2"
  elif $update; then
    cp "$2" "$2.bak-$STAMP"
    cp "$1" "$2"
    echo "updated $2 (old copy: $(basename "$2").bak-$STAMP)"
    updated=$((updated + 1))
  else
    echo "skip    $2 (differs; --update-skills replaces it)"
  fi
}

echo "> llm-wiki-vault $VERSION into $VAULT"
mkdir -p "$VAULT"
cd "$VAULT"
mkdir -p "Fleeting Notes" "Literature Notes" "Permanent Notes" Templates Files raw outputs

copy_new "$SRC/template/AGENTS.md" AGENTS.md
copy_new "$SRC/template/CLAUDE.md" CLAUDE.md
render_new "$SRC/template/Index.md" Index.md
render_new "$SRC/template/Log.md" Log.md
copy_new "$SRC/template/Templates/Note Template.md" "Templates/Note Template.md"
copy_new "$SRC/template/gitignore" .gitignore
copy_new "$SRC/template/index_sections.json" index_sections.json

for skill in $SKILLS; do
  for dir in $SKILL_DIRS; do
    install_file "$SRC/skills/$skill/SKILL.md" "$dir/$skill/SKILL.md"
  done
done
install_file "$SRC/tools/wiki_lint.py" wiki_lint.py
install_file "$SRC/tools/wiki_index.py" wiki_index.py

if [[ ! -e .llm-wiki-vault-version ]] || ((updated > 0)); then
  echo "$VERSION" >.llm-wiki-vault-version
fi
if ((updated > 0)); then
  echo "- $TODAY | human | setup | skills updated to llm-wiki-vault $VERSION ($updated files)" >>Log.md
fi

if $use_git && [[ ! -d .git ]]; then
  git init -q
  echo "added   .git (git init)"
fi

cat <<EOF

> done: $changed added, $updated updated
Next steps:
  1. Open "$(pwd)" as a vault in Obsidian.
  2. Claude Code: cd into the vault, run claude, then /digest, /qna, /wiki, /lint, /explain.
     Codex: run codex in the vault, then \$digest (or /skills).
     Hermes Agent: trust the vault once per machine (this replaces the whole list,
     so include any folders you already trust):
       hermes config set skills.trusted_project_dirs '["$(pwd)"]'
  3. Keep the vault in a private git repository: it holds your notes.
EOF
