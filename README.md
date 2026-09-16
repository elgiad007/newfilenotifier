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

## Windows notifications

On Windows 10/11, new files produce native toast notifications under **New File
Notifier**. After the banner disappears, notifications remain in the Windows
notification panel until dismissed or removed by Windows' history limits.
There are no buttons or actions for opening detected files; clicking a toast
only dismisses it.

`Toast.ahk` is our own AHK v2 library using Windows COM/WinRT APIs directly.
Keep it beside `newfilenotify.ahk` when running the source. The executable in
`distribute` includes the library and needs no separate AHK installation.
No third-party libraries or PowerShell helpers are required.

Startup creates/refreshes a per-user **New File Notifier** Start Menu shortcut
with a stable app ID and stub activation CLSID, and the inert
`HKCU\Software\Classes\newfilenotifier-toast` protocol handler. The handler
invokes the script with `--toast-dismiss`, which exits before starting a monitor.
This supports notification history without a running COM activation server.
Registration requires no administrator privileges. Run the script again after
moving it to update the registered paths. The source and compiled versions
share one notification identity; the most recently started version owns the
shortcut and protocol registration.

If registration or a toast API call fails, the error is logged and a temporary
tray notification is used as a fallback. Windows notification settings still
control whether banners and history are enabled. The log retains the full list
of detected paths even when a long notification is visually truncated.

To remove registration after exiting the app, delete the **New File Notifier**
shortcut from your user Start Menu and the above per-user registry key.

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
8. Let a new-file banner time out, then open the notification panel with Win+N
   on Windows 11. Confirm it remains under **New File Notifier**, including
   after exiting/restarting the script. Clicking it should dismiss it without
   opening a file or starting a second monitor.
9. Test paths containing `&` and non-ASCII characters, and several files in one
   scan. Confirm the notification text and log preserve the names.

For an automated Windows integration check, run the main app once to register
it, then run `AutoHotkey64.exe /ErrorStdOut tests\toast-smoke.ahk` (or
`AutoHotkey32.exe`). It sends one test notification, waits 15 seconds, and
checks Windows' notification history and the retained text. Notifications must
be enabled; do not dismiss the test notification during the check.
