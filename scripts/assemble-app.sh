#!/usr/bin/env bash
# Build LilshotApp and assemble dist/lilshot.app (no codesign).
# Sourced by make-app.sh / make-release.sh, or run standalone.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="lilshot"
APP_DIR="$ROOT/dist/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
BINARY_NAME="lilshot-app"

echo "Building release..."
swift build -c release --product LilshotApp

BIN="$(swift build -c release --product LilshotApp --show-bin-path)/LilshotApp"
if [[ ! -x "$BIN" ]]; then
  echo "error: expected executable at $BIN" >&2
  exit 1
fi

echo "Assembling ${APP_DIR}..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BIN" "$MACOS/$BINARY_NAME"
chmod +x "$MACOS/$BINARY_NAME"

cp "$ROOT/assets/appicon/lilshot.icns" "$RESOURCES/lilshot.icns"
cp "$ROOT/assets/menubar-icon.png" "$RESOURCES/menubar-icon.png"
cp "$ROOT/assets/menubar-icon@2x.png" "$RESOURCES/menubar-icon@2x.png"

# SPM resource bundle next to the executable (Bundle.module for swift run / .app)
BUNDLE_SRC="$(dirname "$BIN")/lilshot_LilshotApp.bundle"
BUNDLE_DST="$MACOS/lilshot_LilshotApp.bundle"
if [[ -d "$BUNDLE_SRC" ]]; then
  rm -rf "$BUNDLE_DST"
  cp -R "$BUNDLE_SRC" "$BUNDLE_DST"
  # Resource bundles need Info.plist for codesign --deep
  if [[ ! -f "$BUNDLE_DST/Info.plist" ]]; then
    cat > "$BUNDLE_DST/Info.plist" <<'BUNDLEPLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>com.lilgroup.lilshot.resources</string>
	<key>CFBundleName</key>
	<string>lilshot_LilshotApp</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
</dict>
</plist>
BUNDLEPLIST
  fi
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>lilshot-app</string>
	<key>CFBundleIconFile</key>
	<string>lilshot.icns</string>
	<key>CFBundleIdentifier</key>
	<string>com.lilgroup.lilshot</string>
	<key>CFBundleName</key>
	<string>lilshot</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

echo "Assembled: ${APP_DIR}"
