-- ================================================================
-- Audacity Raw Data Importer
-- Imports RAW audio files, processes them, sets metadata, saves.
--
-- FIRST-TIME SETUP (one time only):
--   1. Open Audacity
--   2. Audacity menu → Preferences → Modules
--   3. Set 'mod-script-pipe' to Enabled
--   4. Click OK and restart Audacity
-- ================================================================

on run

    -- ── Select RAW audio files ────────────────────────────────
    try
        set rawFiles to choose file ¬
            with prompt "Select the RAW audio data files to import. You may select multiple files." ¬
            with multiple selections allowed
    on error
        return
    end try

    if (count of rawFiles) = 0 then
        display alert "No files were selected." ¬
            message "Please run the script again and select at least one RAW audio file." ¬
            as warning
        return
    end if

    -- ── Enter project name ────────────────────────────────────
    try
        set nameResult to display dialog "Enter a name for this Audacity project:" ¬
            default answer "" ¬
            with title "Audacity Project Name" ¬
            buttons {"Cancel", "Save Project"} ¬
            default button "Save Project"
    on error
        return
    end try

    set projectName to text returned of nameResult
    if projectName is "" then
        display alert "A project name is required." as warning
        return
    end if

    -- ── Choose where to save the project ─────────────────────
    try
        set saveFolder to choose folder ¬
            with prompt "Choose the folder where '" & projectName & "' will be saved:"
    on error
        return
    end try

    set savePath to (POSIX path of saveFolder) & projectName

    -- ── Open Audacity ─────────────────────────────────────────
    tell application "Audacity" to activate

    display dialog ¬
        "Audacity is launching." & return & return & ¬
        "Wait until Audacity shows an empty project window, then click Continue." ¬
        with title "Waiting for Audacity" ¬
        buttons {"Cancel", "Continue"} ¬
        default button "Continue"

    -- ── Build newline-separated file path list ────────────────
    set fileListText to ""
    set isFirst to true
    repeat with aFile in rawFiles
        if not isFirst then set fileListText to fileListText & linefeed
        set fileListText to fileListText & (POSIX path of aFile)
        set isFirst to false
    end repeat

    -- ── Write file list to temp path ──────────────────────────
    set tmpList to "/tmp/aud_importer_files.txt"
    set tmpPy to "/tmp/aud_importer.py"

    set fh to open for access POSIX file tmpList with write permission
    set eof of fh to 0
    write fileListText to fh
    close access fh

    -- ── Decode embedded Python helper and write to temp ───────
    -- The base64 below encodes the full Python Audacity scripting helper.
    set b64 to "IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwppbXBvcnQgc3lzLCBvcywgdGltZQoKZGVmIHNlbmQodHAsIGZwLCBjbWQpOgogICAgd2l0aCBvcGVuKHRwLCAndycpIGFzIGY6CiAgICAgICAgZi53cml0ZShjbWQgKyAnXG4nKQogICAgcmVzcCA9IFtdCiAgICB3aXRoIG9wZW4oZnAsICdyJykgYXMgZjoKICAgICAgICBmb3IgbGluZSBpbiBmOgogICAgICAgICAgICBsaW5lID0gbGluZS5yc3RyaXAoJ1xuXHInKQogICAgICAgICAgICByZXNwLmFwcGVuZChsaW5lKQogICAgICAgICAgICBpZiBsaW5lID09ICdCYXRjaENvbW1hbmQgZmluaXNoZWQnOgogICAgICAgICAgICAgICAgYnJlYWsKICAgIHJldHVybiByZXNwCgpkZWYgbWFpbigpOgogICAgZmlsZV9saXN0X3BhdGggPSBzeXMuYXJndlsxXQogICAgcHJvamVjdF9uYW1lICAgPSBzeXMuYXJndlsyXQogICAgc2F2ZV9wYXRoICAgICAgPSBzeXMuYXJndlszXQoKICAgIHVpZCA9IHN0cihvcy5nZXR1aWQoKSkKICAgIHRwICA9ICcvdG1wL2F1ZGFjaXR5X3NjcmlwdF9waXBlLnRvLicgICArIHVpZAogICAgZnAgID0gJy90bXAvYXVkYWNpdHlfc2NyaXB0X3BpcGUuZnJvbS4nICsgdWlkCgogICAgaWYgbm90IG9zLnBhdGguZXhpc3RzKHRwKToKICAgICAgICBwcmludCgnTk9QSVBFJykKICAgICAgICByZXR1cm4KCiAgICB3aXRoIG9wZW4oZmlsZV9saXN0X3BhdGgpIGFzIGY6CiAgICAgICAgZmlsZXMgPSBbbGluZS5zdHJpcCgpIGZvciBsaW5lIGluIGYgaWYgbGluZS5zdHJpcCgpXQoKICAgIGlmIG5vdCBmaWxlczoKICAgICAgICBwcmludCgnTk9GSUxFUycpCiAgICAgICAgcmV0dXJuCgogICAgIyBOZXcgZW1wdHkgcHJvamVjdAogICAgc2VuZCh0cCwgZnAsICdOZXc6JykKICAgIHRpbWUuc2xlZXAoMikKCiAgICAjIEltcG9ydCBlYWNoIHJhdyBmaWxlIGFzIGEgbmV3IHRyYWNrCiAgICBmb3IgcGF0aCBpbiBmaWxlczoKICAgICAgICBzZW5kKHRwLCBmcCwKICAgICAgICAgICAgJ0ltcG9ydFJhdzogRmlsZW5hbWU9IicgKyBwYXRoICsgJyIgRW5jb2Rpbmc9IlNpZ25lZCAxNi1iaXQgUENNIiAnCiAgICAgICAgICAgICdCeXRlT3JkZXI9IkRlZmF1bHQgYnl0ZSBvcmRlciIgQ2hhbm5lbHM9MSBSYXRlPTQ0MTAwJykKICAgICAgICB0aW1lLnNsZWVwKDEuNSkKCiAgICAjIElmIG11bHRpcGxlIGZpbGVzOiBhbGlnbiBlbmQtdG8tZW5kLCB0aGVuIG1peCBkb3duIHRvIG9uZSB0cmFjawogICAgaWYgbGVuKGZpbGVzKSA+IDE6CiAgICAgICAgc2VuZCh0cCwgZnAsICdTZWxlY3RBbGw6JykKICAgICAgICB0aW1lLnNsZWVwKDAuNSkKICAgICAgICBzZW5kKHRwLCBmcCwgJ0FsaWduX0VuZFRvRW5kOicpCiAgICAgICAgdGltZS5zbGVlcCgwLjUpCiAgICAgICAgc2VuZCh0cCwgZnAsICdNaXhBbmRSZW5kZXI6JykKICAgICAgICB0aW1lLnNsZWVwKDMpCgogICAgIyBOb3JtYWxpemUKICAgIHNlbmQodHAsIGZwLCAnU2VsZWN0QWxsOicpCiAgICB0aW1lLnNsZWVwKDAuNSkKICAgIHNlbmQodHAsIGZwLCAnTm9ybWFsaXplOiBQZWFrTGV2ZWw9LTEgQXBwbHlHYWluPTEgUmVtb3ZlRGNPZmZzZXQ9MSBTdGVyZW9JbmRlcGVuZGVudD0wJykKICAgIHRpbWUuc2xlZXAoNSkKCiAgICAjIEFtcGxpZnkgKGRlZmF1bHQ6IGJyaW5nIHBlYWsgdG8gMCBkQikKICAgIHNlbmQodHAsIGZwLCAnU2VsZWN0QWxsOicpCiAgICB0aW1lLnNsZWVwKDAuNSkKICAgIHNlbmQodHAsIGZwLCAnQW1wbGlmeTonKQogICAgdGltZS5zbGVlcCg1KQoKICAgICMgU2V0IG1ldGFkYXRhIHRhZ3MKICAgIHNlbmQodHAsIGZwLCAnVGFnczogYXJ0aXN0PSJORkIgb2YgQ2FsaWZvcm5pYSIgYWxidW09Ik5GQkNBTCBDb252ZW50aW9uIDIwMjYiIHllYXI9MjAyNicpCiAgICB0aW1lLnNsZWVwKDEpCgogICAgIyBTYXZlIEF1ZGFjaXR5IHByb2plY3QgKC5hdXAzKQogICAgc2VuZCh0cCwgZnAsICdTYXZlUHJvamVjdDI6IEZpbGVuYW1lPSInICsgc2F2ZV9wYXRoICsgJyIgQWRkVG9IaXN0b3J5PTAnKQogICAgdGltZS5zbGVlcCgzKQoKICAgIHByaW50KCdET05FJykKCm1haW4oKQo="

    do shell script "echo " & quoted form of b64 & " | base64 -d > " & quoted form of tmpPy

    -- ── Run the Python automation ─────────────────────────────
    try
        set cmdResult to do shell script ¬
            "python3 " & quoted form of tmpPy & ¬
            " " & quoted form of tmpList & ¬
            " " & quoted form of projectName & ¬
            " " & quoted form of savePath

        if cmdResult contains "NOPIPE" then
            display alert "Audacity Scripting Is Not Enabled" ¬
                message "Complete this one-time setup:" & return & return & ¬
                "1. Open Audacity" & return & ¬
                "2. Audacity menu → Preferences → Modules" & return & ¬
                "3. Set 'mod-script-pipe' to Enabled" & return & ¬
                "4. Click OK and restart Audacity" & return & ¬
                "5. Run this script again" ¬
                as critical
        else if cmdResult contains "NOFILES" then
            display alert "No valid file paths were found." as warning
        else
            display alert "Project Saved" ¬
                message "'" & projectName & ".aup3' has been saved successfully." ¬
                as informational ¬
                buttons {"OK"} default button "OK"
        end if

    on error errMsg
        display alert "An Error Occurred" ¬
            message errMsg ¬
            as critical
    end try

    -- ── Clean up temp files ───────────────────────────────────
    try
        do shell script "rm -f " & quoted form of tmpList & " " & quoted form of tmpPy
    end try

end run
