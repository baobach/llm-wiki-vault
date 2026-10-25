#!/usr/bin/env bash
#
# tests/release_notes.sh: print the GitHub release notes for a version, from CHANGELOG.md.
# Usage: bash tests/release_notes.sh [VERSION]   (default: the VERSION file)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-$(cat "$ROOT/VERSION")}"

section="$(awk -v v="$VERSION" '
  /^## / { on = (index($0, "## " v " ") == 1) ; next }
  on { print }
' "$ROOT/CHANGELOG.md" | sed -e '/./,$!d')"
[[ -n "$section" ]] || { echo "no CHANGELOG.md section for $VERSION" >&2; exit 1; }

cat <<EOT
Install into a new or existing vault:

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/baobach/llm-wiki-vault/v$VERSION/install.sh | bash -s -- ~/external-brain
\`\`\`

Update an installed vault: \`./install.sh --update-skills ~/external-brain\` from a fresh clone.

$section
EOT
