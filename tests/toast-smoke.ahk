#Requires AutoHotkey v2.0
#Include ..\Toast.ahk

; Run the main app once to register it before this integration test.
; Sends one visible test notification and verifies it remains in history.
try {
    Toast.AppId := "LucDaigle.NewFileNotifier"
    Toast.Protocol := "newfilenotifier-toast"
    title := "Toast integration test " A_Now "-" A_TickCount
    body := "C:\Test\caf" Chr(233) " & notes.txt`n<second file>"
    Toast.Show(title, body)
    Sleep(15000)

    manager := Toast.Factory("Windows.UI.Notifications.ToastNotificationManager",
        "{7AB93C52-0E48-4750-BA9D-1A4113981847}")
    ComCall(6, manager, "ptr*", &ptr := 0)
    history := ComValue(13, ptr, 1)
    history2 := ComObjQuery(history, "{3BC3D253-2F31-4092-9129-8AD5ABF067DA}")
    id := Toast.HString(Toast.AppId)
    try ComCall(7, history2, "ptr", id, "ptr*", &ptr := 0)
    finally DllCall("combase\WindowsDeleteString", "ptr", id)
    entries := ComValue(13, ptr, 1)
    ComCall(7, entries, "uint*", &count := 0)
    found := false
    Loop count {
        ComCall(6, entries, "uint", A_Index - 1, "ptr*", &ptr := 0)
        entry := ComValue(13, ptr, 1)
        ComCall(6, entry, "ptr*", &ptr := 0)
        document := ComValue(13, ptr, 1)
        serializer := ComObjQuery(document, "{5CC5B382-E6DD-4991-ABEF-06D8D2E7BD0C}")
        ComCall(6, serializer, "ptr*", &xml := 0)
        try {
            chars := DllCall("combase\WindowsGetStringRawBuffer", "ptr", xml, "uint*", &length := 0, "ptr")
            content := StrGet(chars, length, "UTF-16")
            if InStr(content, title) {
                parsed := ComObject("Msxml2.DOMDocument.6.0")
                parsed.loadXML(content)
                if parsed.selectSingleNode("/toast/visual/binding/text[2]").text != body
                    throw Error("Retained toast text does not match")
                found := true
            }
        } finally DllCall("combase\WindowsDeleteString", "ptr", xml)
    }
    if !found
        throw Error("Test toast was not retained in notification history")
    FileAppend("PASS: native toast retained with Unicode and escaped text`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message "`n" err.Stack, "*")
    ExitApp(1)
}
