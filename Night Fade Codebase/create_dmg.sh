#!/bin/bash

# Night Fade DMG Creator Script
# Simple version without background image

APP_NAME="Night Fade"
DMG_NAME="Night_Fade_v1"
DMG_FINAL="${DMG_NAME}.dmg"
DMG_TMP="${DMG_NAME}-temp.dmg"
VOLUME_NAME="${APP_NAME}"
SOURCE_APP="./build/Build/Products/Release/${APP_NAME}.app"

# Clean up any existing DMG files
echo "Cleaning up old files..."
rm -f "${DMG_TMP}" "${DMG_FINAL}"

# Create a temporary directory for DMG contents
echo "Creating temporary directory..."
mkdir -p dmg_contents

# Copy the app to the temporary directory
echo "Copying app..."
cp -R "${SOURCE_APP}" dmg_contents/

# Create a symbolic link to Applications
echo "Creating Applications symlink..."
ln -s /Applications dmg_contents/Applications

# Copy RTF README file
echo "Copying README..."
if [ -f "Please Read This.rtf" ]; then
    cp "Please Read This.rtf" dmg_contents/
else
    echo "Error: Please Read This.rtf not found!"
    exit 1
fi

# Create the initial DMG
echo "Creating DMG..."
hdiutil create -volname "${VOLUME_NAME}" -srcfolder dmg_contents -ov -format UDRW "${DMG_TMP}"

# Mount the DMG
echo "Mounting DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify "${DMG_TMP}" | egrep '^/dev/' | sed 1q | awk '{print $1}')

# Wait for mount
sleep 2

# Set window properties
echo "Setting DMG window properties..."
osascript << EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "Please Read This.rtf" of container window to {250, 100}
        set position of item "${APP_NAME}.app" of container window to {150, 250}
        set position of item "Applications" of container window to {350, 250}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount the DMG
echo "Unmounting DMG..."
hdiutil detach "${DEVICE}"

# Convert to compressed DMG
echo "Compressing DMG..."
hdiutil convert "${DMG_TMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}"

# Clean up
echo "Cleaning up..."
rm -rf dmg_contents
rm -f "${DMG_TMP}"

echo "✅ DMG created successfully: ${DMG_FINAL}"
echo "📦 Size: $(du -h "${DMG_FINAL}" | cut -f1)"