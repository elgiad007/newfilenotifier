/*
newfilenotify.ahk - A script for monitoring one or more directories for new files.
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; This keeps the script running (normally it would exit when it reached the final "return" statement).
#Persistent

global datadir, configfile, logfile, defaultfolder

; Make sure we have a place to store data
datadir = %A_AppData%\newfilenotifier\
if not fileexist(datadir)
	FileCreateDir, %datadir%

configfile = %datadir%config.ini
logfile = %datadir%newfilenotifylog.txt

; Make sure we have a default folder to monitor
defaultfolder = %datadir%monitor\
if not fileexist(defaultfolder)
	FileCreateDir, %defaultfolder%
defaultmonitor = %defaultfolder%*

; Log the start of this script.
writelog("Starting script")

; Create a new config.ini if one does not exist.
if not FileExist(configfile)
{
	FileAppend, [config]`ninterval=5000`npathstocheck=%defaultmonitor%, %configfile%
}

; Read config.ini settings
IniRead, timerinterval, %configfile%, config, interval, 5000
IniRead, pathstocheck, %configfile%, config, pathstocheck, %defaultmonitor%
; Log the values pulled from the INI file.
writelog("Interval (ms) = " . timerinterval)
writelog("Paths to check (pipe-delimited) = " . pathstocheck)

; Get the list of existing files for each folder in the INI.
global currentfilelist
writelog("Performing initial file check...")

loop parse, pathstocheck, |
{
	loop Files, %a_loopfield%, R
	{
		writelog("Found file: " . A_LoopFileFullPath)
		currentfilelist = %currentfilelist%%A_LoopFileFullPath%`n
	}
}

Menu, Tray, NoStandard
Menu, Tray, Add, Edit config.ini, editconfig
Menu, Tray, Add, View Log File, viewlogfile
Menu, Tray, Add
Menu, Tray, Add, Online Help, onlinehelp
Menu, Tray, Add
Menu, Tray, Add, Restart, restartscript
Menu, Tray, Add, Exit, exitscript

SetTimer, checkfornewfiles, %timerinterval%

writelog("Waiting for new files...")
return

checkfornewfiles:
checkpaths(pathstocheck)
return


writelog(msg)
{
	FormatTime, currenttimestamp, %a_now%, yyyy-MM-dd HH:mm:ss
	FileAppend, %currenttimestamp%`t%msg%`n, %logfile%
}

/*
	Check the paths for new or missing files.
*/
checkpaths(paths)
{
	; Initialize variables
	checkingfilelist = 
	newfiles = 
	newcurrentfilelist =
	
	; Check each path for new files.
	loop parse, paths, |
	{
		loop files, %a_loopfield%, R
		{
			; Add this file to the list for checking.
			checkingfilelist = %checkingfilelist%%A_LoopFileFullPath%`n
			; Check for file in the current list.
			if not instr(currentfilelist, a_loopfilefullpath)
			{
				writelog("Found new file: " . A_LoopFileFullPath)
				newfiles = %newfiles%%A_LoopFileFullPath%`n
			}
		}
	}
	
	; Build a new current file list by including only files from the previous current list that are still there (this omits any files that have been removed)
	loop parse, currentfilelist, `n
	{
		if instr(checkingfilelist, a_loopfield)
			newcurrentfilelist = %newcurrentfilelist%%a_loopfield%`n
	}
	
	; Set the file list we just created plus the new files as the current list for the next run.
	currentfilelist = %newcurrentfilelist%%newfiles%
	
	; Notify the user if we found any new files.
	if newfiles then
		notifynewfiles(newfiles)
	
	; Re-initialize variables, in case the list is large and takes up a lot of memory.
	checkingfilelist = 
	newfiles = 
	newcurrentfilelist =
}

notifynewfiles(newfiles)
{
	TrayTip, New Files, %newfiles%
}

/*
	Tray menu labels.
*/

editconfig:
run, notepad.exe %configfile%
return

viewlogfile:
run, notepad.exe %logfile%
return

onlinehelp:
run, https://wiki.lucdaigle.net/doku.php?id=newfilenotify.ahk
return

restartscript:
writelog("User is restarting the script.")
Reload
return

exitscript:
writelog("User is exiting the script.")
ExitApp
return