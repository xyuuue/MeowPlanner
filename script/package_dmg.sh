#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MeowPlanner"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
DMG_SHA="$DIST_DIR/$APP_NAME.dmg.sha256"
STAGING_DIR="$DIST_DIR/dmg-staging"
WEBSITE_DOWNLOAD_DIR="$ROOT_DIR/website/downloads"
WEBSITE_DMG="$WEBSITE_DOWNLOAD_DIR/$APP_NAME.dmg"
WEBSITE_SHA="$WEBSITE_DOWNLOAD_DIR/$APP_NAME.dmg.sha256"

cd "$ROOT_DIR"

XCODE_DESTINATION=generic/platform=macOS ONLY_ACTIVE_ARCH=NO CONFIGURATION=Release "$ROOT_DIR"/script/build_and_run.sh --build-only

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Missing app bundle at $APP_BUNDLE" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

rm -rf "$STAGING_DIR" "$DMG_PATH" "$DMG_SHA"
mkdir -p "$STAGING_DIR" "$WEBSITE_DOWNLOAD_DIR"

/usr/bin/ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

create_with_hdiutil() {
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
}

if command -v create-dmg >/dev/null 2>&1; then
  create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 520 320 \
    --icon-size 96 \
    --icon "$APP_NAME.app" 150 155 \
    --app-drop-link 370 155 \
    "$DMG_PATH" \
    "$STAGING_DIR" || create_with_hdiutil
else
  create_with_hdiutil
fi

hdiutil verify "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_SHA"

/usr/bin/ditto "$DMG_PATH" "$WEBSITE_DMG"
shasum -a 256 "$WEBSITE_DMG" | sed "s|$WEBSITE_DMG|$APP_NAME.dmg|" > "$WEBSITE_SHA"

rm -rf "$STAGING_DIR"

echo "Created $DMG_PATH"
echo "Synced $WEBSITE_DMG"
echo "Wrote $WEBSITE_SHA"
