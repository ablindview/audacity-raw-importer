# Audacity Raw Data Importer

A macOS desktop application that automates importing RAW audio files into Audacity, processing them, and saving the project — no Terminal required.

## What it does

1. Prompts you to select one or more RAW audio data files
2. Imports them into Audacity on a single timeline (each file follows the previous)
3. Applies the **Normalize** effect
4. Applies the **Amplify** effect (brings peak to 0 dB)
5. Sets metadata: Artist = *NFB of California*, Album = *NFBCAL Convention 2026*, Year = *2026*
6. Prompts for a project name and saves as an Audacity `.aup3` project

**Raw data import settings:**
- Encoding: Signed 16-bit PCM
- Byte order: Default endianness
- Channels: 1 (mono)
- Sample rate: 44,100 Hz

## Requirements

- macOS
- [Audacity](https://www.audacityteam.org/) installed
- Python 3 (included with macOS)

## One-time Audacity setup

Before using this script for the first time:

1. Open Audacity
2. Go to **Audacity menu → Preferences → Modules**
3. Set `mod-script-pipe` to **Enabled**
4. Click **OK** and **restart Audacity**

## Building the desktop app

1. Open `AudacityImporter.applescript` in **Script Editor**
   (`/Applications/Utilities/Script Editor.app`)
2. Go to **File → Export → Export as Application**
3. Save to your Desktop

Or build from Terminal:

```bash
osacompile -o ~/Desktop/AudacityImporter.app AudacityImporter.applescript
```

## Files

| File | Description |
|------|-------------|
| `AudacityImporter.applescript` | AppleScript application source (handles all dialogs) |
| `aud_helper.py` | Python helper that communicates with Audacity via the scripting pipe |

## Accessibility

- All dialogs are native macOS — fully compatible with **VoiceOver**
- Automatically honors **dark/light mode** system preference
- Responds to **Dynamic Type** settings
- No Terminal window appears during use
