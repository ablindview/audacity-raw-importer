#!/bin/bash
# Builds AudacityImporter.app on the Desktop.
# Run this script any time you update AudacityImporter.applescript or aud_helper.py.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DEST="$HOME/Desktop/AudacityImporter.app"

echo "Compiling AppleScript app..."
osacompile -o "$APP_DEST" "$SCRIPT_DIR/AudacityImporter.applescript"

echo "Copying Python helper into app bundle..."
cp "$SCRIPT_DIR/aud_helper.py" "$APP_DEST/Contents/Resources/aud_helper.py"

echo "Patching Info.plist (prevent multiple instances)..."
/usr/libexec/PlistBuddy -c "Add :LSMultipleInstancesProhibited bool true" "$APP_DEST/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :LSMultipleInstancesProhibited true"     "$APP_DEST/Contents/Info.plist"

echo "Done! AudacityImporter.app is on your Desktop."
