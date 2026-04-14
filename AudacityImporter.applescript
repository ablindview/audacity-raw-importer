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

-- Prevent macOS from showing a system file-open dialog when the
-- app is double-clicked (which would trigger an extra file picker).
on open droppedFiles
    -- Files dropped onto the app icon are ignored; use the run handler.
end open

on run

    -- ── Locate the Python helper inside the app bundle ────────
    set appPath to POSIX path of (path to me)
    set helperPath to appPath & "Contents/Resources/aud_helper.py"

    -- Verify the helper exists before doing anything else
    set helperExists to do shell script "test -f " & quoted form of helperPath & " && echo yes || echo no"
    if helperExists is not "yes" then
        display alert "Installation Problem" ¬
            message "The Python helper was not found inside the app bundle." & return & return & ¬
            "Please rebuild the app using build.sh." ¬
            as critical
        return
    end if

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

    -- ── Write file list to temp file ──────────────────────────
    set tmpList to "/tmp/aud_importer_files.txt"

    set fh to open for access POSIX file tmpList with write permission
    set eof of fh to 0
    write fileListText to fh
    close access fh

    -- ── Run the Python automation ─────────────────────────────
    try
        set cmdResult to do shell script ¬
            "python3 " & quoted form of helperPath & ¬
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
        do shell script "rm -f " & quoted form of tmpList
    end try

end run
