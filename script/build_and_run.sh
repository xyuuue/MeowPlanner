#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MeowPlanner"
BUNDLE_ID="com.yuelingqiu.MeowPlanner"
MIN_SYSTEM_VERSION="14.0"
CONFIGURATION="${CONFIGURATION:-Debug}"
XCODE_DESTINATION="${XCODE_DESTINATION:-}"
XCODE_ONLY_ACTIVE_ARCH="${ONLY_ACTIVE_ARCH:-}"
TEMP_ENTITLEMENTS_FILE=""

cleanup_temp_entitlements() {
  if [ -n "$TEMP_ENTITLEMENTS_FILE" ]; then
    rm -f "$TEMP_ENTITLEMENTS_FILE"
    TEMP_ENTITLEMENTS_FILE=""
  fi
}
trap cleanup_temp_entitlements EXIT

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
INSTALL_BUNDLE="/Applications/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INSTALL_BINARY="$INSTALL_BUNDLE/Contents/MacOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
XCODE_DERIVED_DATA="$ROOT_DIR/build/XcodeRun"
XCODE_APP="$XCODE_DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

build_with_xcode() {
  local xcodebuild_args=(
    -project "$ROOT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$XCODE_DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO
  )

  if [[ -n "$XCODE_DESTINATION" ]]; then
    xcodebuild_args+=(-destination "$XCODE_DESTINATION")
  fi

  if [[ -n "$XCODE_ONLY_ACTIVE_ARCH" ]]; then
    xcodebuild_args+=(ONLY_ACTIVE_ARCH="$XCODE_ONLY_ACTIVE_ARCH")
  fi

  xcodebuild "${xcodebuild_args[@]}" build

  rm -rf "$APP_BUNDLE"
  mkdir -p "$DIST_DIR"
  cp -R "$XCODE_APP" "$APP_BUNDLE"

  local app_core="$APP_BUNDLE/Contents/Frameworks/MeowPlannerCore.framework"
  local widget="$APP_BUNDLE/Contents/PlugIns/MeowPlannerWidgetExtension.appex"
  local widget_core="$widget/Contents/Frameworks/MeowPlannerCore.framework"
  local app_entitlements="$ROOT_DIR/Config/MeowPlanner.entitlements"
  local widget_entitlements="$ROOT_DIR/Config/MeowPlannerWidget.entitlements"
  TEMP_ENTITLEMENTS_FILE="$(mktemp -t meowplanner_local.entitlements.plist)"

  if [[ -d "$widget_core" ]]; then
    codesign --force --sign - "$widget_core"
  fi
  if [[ -d "$widget" ]]; then
    codesign --force --sign - --entitlements "$widget_entitlements" "$widget"
  fi
  if [[ -d "$app_core" ]]; then
    codesign --force --sign - "$app_core"
  fi

  cat > "$TEMP_ENTITLEMENTS_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.yuelingqiu.MeowPlanner</string>
	</array>
	<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
	<array>
		<string>/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/</string>
	</array>
</dict>
</plist>
EOF

  codesign --force --sign - --entitlements "$TEMP_ENTITLEMENTS_FILE" "$APP_BUNDLE"
  TEMP_ENTITLEMENTS_FILE=""
}

build_with_swiftpm() {
  swift build --product "$APP_NAME"
  BUILD_DIR="$(swift build --show-bin-path)"
  BUILD_BINARY="$BUILD_DIR/$APP_NAME"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_RESOURCES"

  cp "$BUILD_BINARY" "$APP_BINARY"
  chmod +x "$APP_BINARY"

  if [[ -d "$BUILD_DIR/MeowPlanner_MeowPlannerApp.bundle" ]]; then
    cp -R "$BUILD_DIR/MeowPlanner_MeowPlannerApp.bundle" "$APP_RESOURCES/"
  fi

  if [[ -f "$ROOT_DIR/Resources/AppIcon/AppIcon.icns" ]]; then
    cp "$ROOT_DIR/Resources/AppIcon/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
  fi

  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

if [[ -d "$ROOT_DIR/$APP_NAME.xcodeproj" ]]; then
  build_with_xcode
else
  build_with_swiftpm
fi

install_app() {
  rm -rf "$INSTALL_BUNDLE"
  /usr/bin/ditto "$APP_BUNDLE" "$INSTALL_BUNDLE"
  /usr/bin/touch "$INSTALL_BUNDLE"
}

install_app

refresh_widget_registration() {
  WIDGET_BUNDLE="$INSTALL_BUNDLE/Contents/PlugIns/MeowPlannerWidgetExtension.appex"
  pkill -f "$INSTALL_BUNDLE/Contents/PlugIns/MeowPlannerWidgetExtension.appex" >/dev/null 2>&1 || true
  /usr/bin/pluginkit -r "$WIDGET_BUNDLE" >/dev/null 2>&1 || true
  /usr/bin/pluginkit -a "$WIDGET_BUNDLE" >/dev/null 2>&1 || true
  /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R "$INSTALL_BUNDLE" >/dev/null 2>&1 || true
}

refresh_widget_registration

open_app() {
  /usr/bin/open -n "$INSTALL_BUNDLE"
}

case "$MODE" in
  run|--run)
    open_app
    ;;
  --build-only|build)
    echo "Built $APP_BUNDLE"
    echo "Installed $INSTALL_BUNDLE"
    ;;
  --debug|debug)
    lldb -- "$INSTALL_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "Verified $APP_NAME is running from $INSTALL_BUNDLE"
    ;;
  *)
    echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
