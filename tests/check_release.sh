#!/usr/bin/env bash
#
# tests/check_release.sh: check that version numbers, docs, and assets agree.
# Usage: bash tests/check_release.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
VERSION="$(cat VERSION)"
errors=0

fail() {
  echo "FAIL: $*" >&2
  errors=$((errors + 1))
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION '$VERSION' is not X.Y.Z"
grep -q "LLM_WIKI_VAULT_REF:-v$VERSION}" install.sh || fail "install.sh default REF is not v$VERSION"
grep -q "llm-wiki-vault/v$VERSION/install.sh" README.md || fail "README one-line install is not pinned to v$VERSION"
grep -q "^## $VERSION " CHANGELOG.md || fail "CHANGELOG.md has no '## $VERSION (date)' heading"
[[ "$(grep -m1 '^## ' CHANGELOG.md)" == "## $VERSION "* ]] || fail "CHANGELOG.md top entry is not $VERSION"
bash tests/release_notes.sh "$VERSION" >/dev/null || fail "release notes for $VERSION are empty"

# every skill install.sh ships exists and names itself
read -ra skills <<<"$(sed -n 's/^SKILLS="\(.*\)"$/\1/p' install.sh)"
for s in "${skills[@]}"; do
  [[ -f "skills/$s/SKILL.md" ]] || { fail "skills/$s/SKILL.md missing"; continue; }
  grep -q "^name: $s$" "skills/$s/SKILL.md" || fail "skills/$s/SKILL.md does not say name: $s"
done

# files the README points to exist, and SVG assets are well-formed XML
while read -r f; do
  [[ -e "$f" ]] || fail "README links to missing $f"
done < <(grep -oE '\]\(([a-zA-Z0-9_./-]+)\)|src="[a-zA-Z0-9_./-]+"' README.md | sed -E 's/^\]\(|\)$|^src="|"$//g')
for f in docs/*.svg; do
  [[ -e "$f" ]] || continue
  python3 -c 'import sys, xml.etree.ElementTree as E; E.parse(sys.argv[1])' "$f" || fail "$f is not valid XML"
done

((errors == 0)) || exit 1
echo "release metadata ok: $VERSION"
