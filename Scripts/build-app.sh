#!/usr/bin/env bash
#
# Bygger Folkomaten.app – en kjørbar menylinje-app – fra Swift-pakken.
# Bruk:  ./Scripts/build-app.sh [debug|release]   (standard: release)
#
set -euo pipefail

CONFIG="${1:-release}"
APP_NAME="Folkomaten"
BUNDLE_ID="no.folkomaten.app"
# Versjonen kommer fra miljøet hvis satt (release-workflowen sender VERSION fra
# git-taggen), ellers utledes den fra siste tag, med en dev-fallback for et
# repo helt uten tagger.
VERSION="${VERSION:-$(git -C "$(dirname "$0")/.." describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0-dev}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▸ Bygger ($CONFIG)…"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"
APP="$ROOT/$APP_NAME.app"

echo "▸ Setter sammen $APP_NAME.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_PATH/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"

# Kopier SwiftPM-ressursbundle (Bundle.module) inn i appen.
for bundle in "$BIN_PATH"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>                 <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>          <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>           <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>           <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>          <string>APPL</string>
    <key>CFBundleShortVersionString</key>   <string>${VERSION}</string>
    <key>CFBundleVersion</key>              <string>1</string>
    <key>LSMinimumSystemVersion</key>       <string>13.0</string>
    <key>LSUIElement</key>                  <true/>
    <key>NSHumanReadableCopyright</key>     <string>MIT-lisens</string>
</dict>
</plist>
PLIST

# Ad-hoc-signering: bygget lokalt → ingen Gatekeeper-advarsel.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✓ Ferdig: $APP"
echo "  Åpne med:  open \"$APP\""
