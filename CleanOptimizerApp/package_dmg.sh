#!/bin/bash
set -e

WORKSPACE_DIR="/Users/appconsultdeck/.gemini/antigravity/brain/6e4cf2af-d32f-4b0d-b32c-c6a86f15f24a"
APP_DIR="${WORKSPACE_DIR}/CleanOptimizerApp"
ICON_PNG="${WORKSPACE_DIR}/app_icon_1781235640629.png"

echo "Creating iconset..."
mkdir -p "${APP_DIR}/AppIcon.iconset"

sips -s format png -z 16 16     "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_16x16.png"
sips -s format png -z 32 32     "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_16x16@2x.png"
sips -s format png -z 32 32     "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_32x32.png"
sips -s format png -z 64 64     "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_32x32@2x.png"
sips -s format png -z 128 128   "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_128x128.png"
sips -s format png -z 256 256   "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_128x128@2x.png"
sips -s format png -z 256 256   "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_256x256.png"
sips -s format png -z 512 512   "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_256x256@2x.png"
sips -s format png -z 512 512   "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_512x512.png"
sips -s format png -z 1024 1024 "${ICON_PNG}" --out "${APP_DIR}/AppIcon.iconset/icon_512x512@2x.png"

echo "Compiling AppIcon.icns..."
iconutil -c icns "${APP_DIR}/AppIcon.iconset" -o "${APP_DIR}/AppIcon.icns"
rm -rf "${APP_DIR}/AppIcon.iconset"

echo "Structuring CleanOptimizerApp.app..."
mkdir -p "${APP_DIR}/CleanOptimizerApp.app/Contents/MacOS"
mkdir -p "${APP_DIR}/CleanOptimizerApp.app/Contents/Resources"

echo "Copying binary and icon..."
cp "${APP_DIR}/.build/release/CleanOptimizerApp" "${APP_DIR}/CleanOptimizerApp.app/Contents/MacOS/CleanOptimizerApp"
cp "${APP_DIR}/AppIcon.icns" "${APP_DIR}/CleanOptimizerApp.app/Contents/Resources/AppIcon.icns"

echo "Creating Info.plist..."
cat << 'EOF' > "${APP_DIR}/CleanOptimizerApp.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CleanOptimizerApp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.appconsultdeck.CleanOptimizerApp</string>
    <key>CFBundleName</key>
    <string>CleanOptimizer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "Creating DMGContents folder..."
rm -rf "${APP_DIR}/DMGContents"
mkdir -p "${APP_DIR}/DMGContents"
mv "${APP_DIR}/CleanOptimizerApp.app" "${APP_DIR}/DMGContents/"
ln -s /Applications "${APP_DIR}/DMGContents/Applications"

echo "Building DMG..."
rm -f "${WORKSPACE_DIR}/CleanOptimizer.dmg"
hdiutil create -volname "CleanOptimizer" -srcfolder "${APP_DIR}/DMGContents" -ov -format UDZO "${WORKSPACE_DIR}/CleanOptimizer.dmg"

echo "Cleanup..."
rm -rf "${APP_DIR}/DMGContents"
rm -f "${APP_DIR}/AppIcon.icns"

echo "Successfully created CleanOptimizer.dmg!"
