#!/usr/bin/env bash
# Archive Slip for TestFlight and optionally upload to App Store Connect.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${SCHEME:-Slip}"
CONFIG="${CONFIG:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT/build/Slip.xcarchive}"
EXPORT_DIR="${EXPORT_DIR:-$ROOT/build/export}"
EXPORT_OPTIONS="${EXPORT_OPTIONS:-$ROOT/ExportOptions.plist}"
UPLOAD="${UPLOAD:-0}"

mkdir -p "$ROOT/build"

echo "==> Regenerating project (if xcodegen present)"
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
fi

echo "==> Archiving $SCHEME ($CONFIG)"
rm -rf "$ARCHIVE_PATH"
xcodebuild \
  -project Slip.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  CLEAN_FIRST=YES \
  archive \
  | xcbeautify 2>/dev/null || xcodebuild \
  -project Slip.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "==> Archive ready: $ARCHIVE_PATH"
echo "Open Organizer in Xcode → Distribute App → App Store Connect → Upload"
echo "Or set UPLOAD=1 to export/upload via ExportOptions.plist"

if [[ "$UPLOAD" == "1" ]]; then
  rm -rf "$EXPORT_DIR"
  mkdir -p "$EXPORT_DIR"
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS"
  echo "==> Exported to $EXPORT_DIR"
fi
