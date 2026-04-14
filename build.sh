#!/bin/bash
# Builds AudacityImporter.app on the Desktop.
# Run this script any time you update AudacityImporter.applescript or aud_helper.py.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DEST="$HOME/Desktop/AudacityImporter.app"

echo "Compiling AppleScript app..."
osacompile -o "$APP_DEST" "$SCRIPT_DIR/AudacityImporter.applescript"

echo "Copying Python helper into app bundle..."
cp "$SCRIPT_DIR/aud_helper.py" "$APP_DEST/Contents/Resources/aud_helper.py"

echo "Done! AudacityImporter.app is on your Desktop."
