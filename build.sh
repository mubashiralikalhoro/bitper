#!/bin/sh
# Builds Bitper.app (menu bar only, mic permission via Info.plist).
set -e
cd "$(dirname "$0")"
APP=Bitper.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp AppIcon.icns "$APP/Contents/Resources/"
swiftc -O -parse-as-library -target "$(uname -m)-apple-macos14.0" Bitper.swift -o "$APP/Contents/MacOS/Bitper"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.bitper</string>
  <key>CFBundleName</key><string>Bitper</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleExecutable</key><string>Bitper</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>Record speech for local transcription with whisper.cpp.</string>
</dict></plist>
EOF
"$APP/Contents/MacOS/Bitper" --selftest
codesign --force --sign - "$APP"
echo "Built $APP — run: open $APP"
