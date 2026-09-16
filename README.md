# newfilenotifier
An AHK script to monitor one or more folders for new files and report them. I wrote this script back in 2021 when Dad asked me to create something for him to monitor a folder for new files at work. 

See https://wiki.lucdaigle.net/doku.php?id=newfilenotify.ahk

## Requirements and running

Install the latest stable [AutoHotkey v2](https://www.autohotkey.com/) release,
then double-click `newfilenotify.ahk`. AutoHotkey v1 is no longer supported.

Existing settings in `%AppData%\newfilenotifier\config.ini` are reused.
The polling interval is in milliseconds; `pathstocheck` contains pipe-separated
file patterns (for example, `C:\Folder One\*|D:\Folder Two\*`). Subfolders are
included. Use the tray menu to edit settings, then Restart to apply them.

## File filtering

Both the initial scan and subsequent scans ignore files with the Windows Hidden
attribute and files whose names start with `~$` (Microsoft Office owner/lock
files). These files are excluded before tracking, logging, and notification,
including in monitored subfolders. Intentionally hidden files are also ignored.
Existing log entries are retained.

Other visible files, including `.tmp` files and names starting with `~` but not
`~$`, remain eligible. A `~$` prefix on a folder name does not exclude the files
inside it. Temporary files that do not match either rule remain eligible.
A previously ignored file becomes eligible when it no longer matches either rule.

This version displays a New Files tray notification only; it has no New Files
window or action for opening detected files.

## Manual verification (AutoHotkey v2)

Use a test folder configured in `%AppData%\newfilenotifier\config.ini` and wait
at least one configured polling interval after each change.

1. Before starting the script, create a normal file, a file with the Windows
   Hidden attribute, and a visible file named `~$existing.docx`. Start the script
   and confirm only the normal file appears in the initial scan log.
2. Add a new normal document. Confirm it is logged and notified once, with no
   repeat notification on the next scan.
3. Open and close that document in Office. Confirm its hidden/`~$` temporary
   files never appear in the log or notifications.
4. While the script is running, create a hidden file and a visible
   `~$new.docx`. Confirm neither is reported. Prepare the hidden file outside
   the monitored folder, set its Hidden attribute, then move it into the folder
   so a scan cannot detect it before the attribute is set.
5. Add visible files named `~notes.txt` and `example.tmp`, and a normal file
   inside a folder named `~$folder`. Confirm they are reported.
6. Repeat the checks in a subfolder and a second configured monitored folder.
7. Remove the Hidden attribute from an ignored file. Confirm it is reported
   once on a subsequent scan. Restart and confirm ignored files remain absent
   from new log entries; historical log entries remain intact.
