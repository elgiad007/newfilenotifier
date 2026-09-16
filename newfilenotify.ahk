/*
newfilenotify.ahk - A script for monitoring one or more directories for new files.
*/

#Requires AutoHotkey v2.0
; Ignore duplicate launches before AutoHotkey can prompt, including toast clicks.
#SingleInstance Ignore
#Include Toast.ahk

if A_Args.Length && A_Args[1] = "--toast-dismiss"
    ExitApp()

SetWorkingDir(A_ScriptDir)
Persistent()

; Keep the existing data and configuration locations.
datadir := A_AppData "\newfilenotifier\"
DirCreate(datadir)
configfile := datadir "config.ini"
logfile := datadir "newfilenotifylog.txt"
defaultfolder := datadir "monitor\"
DirCreate(defaultfolder)
defaultmonitor := defaultfolder "*"

writelog("Starting script")

toastReady := false
try {
    Toast.Register("LucDaigle.NewFileNotifier", "New File Notifier",
        "{7B59283A-714E-4FAD-9C94-A6E990DDAE8B}", "newfilenotifier-toast")
    toastReady := true
} catch Error as err {
    writelog("Toast registration failed: " err.Message)
}

if !FileExist(configfile)
    FileAppend("[config]`ninterval=5000`npathstocheck=" defaultmonitor, configfile)

timerinterval := IniRead(configfile, "config", "interval", 5000)
pathstocheck := IniRead(configfile, "config", "pathstocheck", defaultmonitor)
writelog("Interval (ms) = " timerinterval)
writelog("Paths to check (pipe-delimited) = " pathstocheck)

; Use exact, case-insensitive paths so similar filenames remain distinct.
currentfilelist := Map()
currentfilelist.CaseSense := "Off"
writelog("Performing initial file check...")
Loop Parse, pathstocheck, "|"
{
    Loop Files, A_LoopField, "FR"
    {
        if ShouldIgnoreFile(A_LoopFileFullPath, A_LoopFileAttrib)
            continue
        writelog("Found file: " A_LoopFileFullPath)
        currentfilelist[A_LoopFileFullPath] := true
    }
}

A_TrayMenu.Delete()
A_TrayMenu.Add("Edit config.ini", editconfig)
A_TrayMenu.Add("View Log File", viewlogfile)
A_TrayMenu.Add()
A_TrayMenu.Add("Online Help", onlinehelp)
A_TrayMenu.Add()
A_TrayMenu.Add("Restart", restartscript)
A_TrayMenu.Add("Exit", exitscript)

SetTimer(checkfornewfiles, timerinterval)
writelog("Waiting for new files...")

checkfornewfiles()
{
    checkpaths(pathstocheck)
}

writelog(msg)
{
    currenttimestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(currenttimestamp "`t" msg "`n", logfile)
}

; Ignore hidden files and Office owner/lock files before tracking or logging them.
ShouldIgnoreFile(path, attributes)
{
    SplitPath(path, &filename)
    return InStr(attributes, "H") || (SubStr(filename, 1, 2) = "~$")
}

; Check the paths for new or missing files.
checkpaths(paths)
{
    global currentfilelist
    checkingfilelist := Map()
    checkingfilelist.CaseSense := "Off"
    newfiles := ""

    Loop Parse, paths, "|"
    {
        Loop Files, A_LoopField, "FR"
        {
            if ShouldIgnoreFile(A_LoopFileFullPath, A_LoopFileAttrib)
                continue
            ; Overlapping monitored paths should notify only once per file.
            if !currentfilelist.Has(A_LoopFileFullPath) && !checkingfilelist.Has(A_LoopFileFullPath)
            {
                writelog("Found new file: " A_LoopFileFullPath)
                newfiles .= A_LoopFileFullPath "`n"
            }
            checkingfilelist[A_LoopFileFullPath] := true
        }
    }

    ; Replacing the snapshot also removes files that no longer exist.
    currentfilelist := checkingfilelist
    if newfiles != ""
        notifynewfiles(newfiles)
}

notifynewfiles(newfiles)
{
    try {
        if !toastReady
            throw Error("Toast registration is unavailable")
        Toast.Show("New Files", newfiles)
    } catch Error as err {
        writelog("Toast notification failed (using temporary tray notification): " err.Message)
        TrayTip(newfiles, "New Files")
    }
}

; Tray menu callbacks accept the arguments supplied by AutoHotkey v2.
editconfig(*)
{
    Run('notepad.exe "' configfile '"')
}

viewlogfile(*)
{
    Run('notepad.exe "' logfile '"')
}

onlinehelp(*)
{
    Run("https://wiki.lucdaigle.net/doku.php?id=newfilenotify.ahk")
}

restartscript(*)
{
    writelog("User is restarting the script.")
    Reload()
}

exitscript(*)
{
    writelog("User is exiting the script.")
    ExitApp()
}
