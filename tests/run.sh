#!/usr/bin/env bash
#
# tests/run.sh: end-to-end tests for install.sh, wiki_lint.py, and wiki_index.py.
# Usage: bash tests/run.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
V="$T/vault"
SKILLS="digest wiki qna lint explain"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}
snapshot() { (cd "$V" && find . -type f -exec cksum {} + | sort); }

echo "1. fresh install"
bash "$ROOT/install.sh" --no-git "$V" >"$T/out1"
for f in AGENTS.md CLAUDE.md Index.md Log.md .gitignore "Templates/Note Template.md" \
  wiki_lint.py wiki_index.py index_sections.json .llm-wiki-vault-version; do
  [[ -f "$V/$f" ]] || fail "missing $f"
done
for d in "Fleeting Notes" "Literature Notes" "Permanent Notes" Files raw outputs; do
  [[ -d "$V/$d" ]] || fail "missing folder $d"
done
for s in $SKILLS; do
  for d in .claude/skills .agents/skills; do
    cmp -s "$ROOT/skills/$s/SKILL.md" "$V/$d/$s/SKILL.md" || fail "skill $d/$s differs"
  done
done
if grep -q -e __TODAY__ -e __VERSION__ "$V/Index.md" "$V/Log.md"; then fail "placeholders left"; fi
[[ "$(cat "$V/.llm-wiki-vault-version")" == "$(cat "$ROOT/VERSION")" ]] || fail "version file"

echo "2. rerun changes nothing"
before="$(snapshot)"
bash "$ROOT/install.sh" --no-git "$V" >"$T/out2"
[[ "$before" == "$(snapshot)" ]] || fail "rerun changed files"
if grep -q '^added' "$T/out2"; then fail "rerun added files"; fi

echo "3. user edits survive, --update-skills restores skills with a backup"
echo "- custom rule" >>"$V/AGENTS.md"
echo "local edit" >>"$V/.claude/skills/digest/SKILL.md"
bash "$ROOT/install.sh" --no-git "$V" >"$T/out3"
grep -q 'skip    .claude/skills/digest/SKILL.md (differs' "$T/out3" || fail "edited skill not reported"
grep -q 'local edit' "$V/.claude/skills/digest/SKILL.md" || fail "skill replaced without --update-skills"
bash "$ROOT/install.sh" --no-git --update-skills "$V" >"$T/out4"
grep -q 'custom rule' "$V/AGENTS.md" || fail "AGENTS.md was overwritten"
cmp -s "$ROOT/skills/digest/SKILL.md" "$V/.claude/skills/digest/SKILL.md" || fail "skill not updated"
ls "$V/.claude/skills/digest/"SKILL.md.bak-* >/dev/null 2>&1 || fail "no backup of the replaced skill"
grep -q 'skills updated to llm-wiki-vault' "$V/Log.md" || fail "update not logged"

echo "4. wiki_lint.py finds the planted problems"
cp -R "$ROOT/tests/fixtures/." "$V/"
set +e
python3 "$V/wiki_lint.py" "$V" >"$T/lint.out"
rc=$?
set -e
[[ $rc -eq 1 ]] || fail "wiki_lint.py exit code $rc, expected 1"
diff -u "$ROOT/tests/expected-lint.txt" "$T/lint.out" || fail "wiki_lint.py output differs"

echo "5. wiki_index.py builds Index.md from the section map"
cp "$ROOT/tests/index_sections.json" "$V/index_sections.json"
python3 "$V/wiki_index.py" "$V" >"$T/index.out"
grep -q '^Index.md written: 3 notes, 1 in sections, 2 uncategorized' "$T/index.out" || fail "wiki_index.py summary"
if grep -q '\[\[position sizing\]\]' "$T/index.out"; then fail "mapped target reported as unmapped"; fi
grep -v '^updated:' "$V/Index.md" | diff -u "$ROOT/tests/expected-index.md" - || fail "Index.md differs"
python3 "$V/wiki_index.py" "$V" | grep -q '^Index.md unchanged' || fail "rerun rewrote Index.md"
python3 "$V/wiki_index.py" "$V" --check >/dev/null || fail "--check says out of date"
perl -pi -e 's/^title: "Lonely"/title: "Lonely"\ntags: ["#sizing"]/' "$V/Fleeting Notes/Lonely.md"
if python3 "$V/wiki_index.py" "$V" --check >/dev/null; then fail "--check missed a change"; fi

echo "6. default download ref matches VERSION"
grep -q "LLM_WIKI_VAULT_REF:-v$(cat "$ROOT/VERSION")}" "$ROOT/install.sh" || fail "REF in install.sh != VERSION"

echo "all tests passed"
