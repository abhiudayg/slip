#!/usr/bin/env bash
# Generate release notes between two refs (default: previous tag → HEAD).
# Usage: ./scripts/generate-release-notes.sh [from_ref] [to_ref] > RELEASE_NOTES.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TO_REF="${2:-HEAD}"
VERSION="$(tr -d '[:space:]' <VERSION)"

if [[ -n "${1:-}" ]]; then
  FROM_REF="$1"
else
  FROM_REF="$(git describe --tags --abbrev=0 2>/dev/null || true)"
  if [[ -z "$FROM_REF" ]]; then
    FROM_REF="$(git rev-list --max-parents=0 HEAD | tail -1)"
  fi
fi

RANGE="${FROM_REF}..${TO_REF}"

features=()
fixes=()
chores=()
other=()

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  lower="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower" == feat:* || "$lower" == feat\(* ]]; then
    features+=("$line")
  elif [[ "$lower" == fix:* || "$lower" == fix\(* ]]; then
    fixes+=("$line")
  elif [[ "$lower" == chore:* || "$lower" == docs:* || "$lower" == ci:* || "$lower" == build:* || "$lower" == refactor:* ]]; then
    chores+=("$line")
  else
    other+=("$line")
  fi
done < <(git log --pretty=format:'%s' "$RANGE")

echo "## Slip v${VERSION}"
echo
echo "Compare: \`${FROM_REF}\` → \`${TO_REF}\`"
echo

section() {
  local title="$1"
  shift || true
  if [[ $# -eq 0 ]]; then
    return 0
  fi
  echo "### ${title}"
  echo
  for i in "$@"; do
    echo "- ${i}"
  done
  echo
}

((${#features[@]})) && section "Features" "${features[@]}"
((${#fixes[@]})) && section "Fixes" "${fixes[@]}"
((${#chores[@]})) && section "Chores" "${chores[@]}"
((${#other[@]})) && section "Other" "${other[@]}"

echo "### Packages"
echo
echo "- \`pass-engine-${VERSION}.jar\` — Spring Boot pass signer"
echo "- \`slip-templates-${VERSION}.zip\` — Wallet brand templates"
echo "- Maven: \`com.slip:pass-engine:${VERSION}\` (GitHub Packages)"
echo "- Container: \`ghcr.io/abhiudayg/slip-pass-engine:${VERSION}\`"
echo
echo "### Install / run"
echo
echo '```bash'
echo "java -jar pass-engine-${VERSION}.jar"
echo "# or"
echo "docker pull ghcr.io/abhiudayg/slip-pass-engine:${VERSION}"
echo '```'
