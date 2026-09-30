#!/usr/bin/env bash
# Sync Slip versions across VERSION, Maven, and iOS project.yml.
# Usage:
#   ./scripts/version.sh              # print current
#   ./scripts/version.sh set 1.2.3    # set exact
#   ./scripts/version.sh bump patch|minor|major
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
POM="$ROOT/pass-engine/pom.xml"
IOS_YML="$ROOT/ios/project.yml"

current() {
  tr -d '[:space:]' <"$VERSION_FILE"
}

semver_bump() {
  local v="$1" part="$2"
  IFS=. read -r major minor patch <<<"$v"
  case "$part" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
    *) echo "bump part must be major|minor|patch" >&2; exit 1 ;;
  esac
}

apply_version() {
  local v="$1"
  if [[ ! "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid semver: $v" >&2
    exit 1
  fi

  printf '%s\n' "$v" >"$VERSION_FILE"

  # Maven project version (first non-parent <version> under project)
  python3 - "$POM" "$v" <<'PY'
import re, sys
path, ver = sys.argv[1], sys.argv[2]
text = open(path).read()
# Replace only the module version after artifactId pass-engine
text2, n = re.subn(
    r'(<artifactId>pass-engine</artifactId>\s*<version>)[^<]+(</version>)',
    rf'\g<1>{ver}\g<2>',
    text,
    count=1,
)
if n != 1:
    raise SystemExit(f'Failed to update pom version (matches={n})')
open(path, 'w').write(text2)
print(f'pom -> {ver}')
PY

  python3 - "$IOS_YML" "$v" <<'PY'
import re, sys
path, ver = sys.argv[1], sys.argv[2]
text = open(path).read()
text2, n = re.subn(r'(MARKETING_VERSION:\s*")[^"]+(")', rf'\g<1>{ver}\g<2>', text)
if n < 1:
    raise SystemExit('Failed to update MARKETING_VERSION')
# Keep build number monotonic: bump CURRENT_PROJECT_VERSION by 1
def bump_build(m):
    return f'{m.group(1)}{int(m.group(2)) + 1}{m.group(3)}'
text3, nb = re.subn(
    r'(CURRENT_PROJECT_VERSION:\s*")(\d+)(")',
    bump_build,
    text2,
)
open(path, 'w').write(text3)
print(f'ios MARKETING_VERSION -> {ver} (build keys updated={nb})')
PY

  # Regenerate Xcode project if xcodegen is available locally
  if command -v xcodegen >/dev/null 2>&1; then
    (cd "$ROOT/ios" && xcodegen generate >/dev/null)
    echo "ios Xcode project regenerated"
  fi

  echo "$v"
}

cmd="${1:-}"
case "$cmd" in
  ""|get|current)
    echo "$(current)"
    ;;
  set)
    apply_version "${2:?usage: version.sh set X.Y.Z}"
    ;;
  bump)
    apply_version "$(semver_bump "$(current)" "${2:?usage: version.sh bump patch|minor|major}")"
    ;;
  *)
    echo "usage: $0 [get|set X.Y.Z|bump patch|minor|major]" >&2
    exit 1
    ;;
esac
