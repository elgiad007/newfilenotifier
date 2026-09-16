#Requires AutoHotkey v2.0

; Native Windows toast support. All COM interfaces are owned by ComValue wrappers;
; HSTRINGs are released after each API call; PROPVARIANTs borrow local buffers.
class Toast {
    static Register(appId, displayName, activatorClsid, protocol) {
        this.AppId := appId
        this.Protocol := protocol
        target := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
        args := A_IsCompiled ? "" : '"' A_ScriptFullPath '"'

        ; Protocol activation is a no-op: the main script exits immediately for
        ; --toast-dismiss, before starting another monitor or registering again.
        key := "HKCU\Software\Classes\" protocol
        RegWrite("URL:" displayName, "REG_SZ", key)
        RegWrite("", "REG_SZ", key, "URL Protocol")
        RegWrite('"' target '" ' args ' --toast-dismiss', "REG_SZ", key "\shell\open\command")

        link := ComObject("{00021401-0000-0000-C000-000000000046}",
            "{000214F9-0000-0000-C000-000000000046}") ; IShellLinkW
        ComCall(20, link, "wstr", target) ; SetPath
        ComCall(11, link, "wstr", args) ; SetArguments
        ComCall(9, link, "wstr", A_ScriptDir) ; SetWorkingDirectory
        ComCall(7, link, "wstr", displayName) ; SetDescription
        props := ComObjQuery(link, "{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}")
        this.SetProperty(props, 5, appId) ; PKEY_AppUserModel_ID
        ; A stub CLSID allows history persistence with protocol activation.
        this.SetProperty(props, 26, activatorClsid, true)
        ComCall(7, props) ; IPropertyStore.Commit
        file := ComObjQuery(link, "{0000010B-0000-0000-C000-000000000046}")
        ComCall(6, file, "wstr", A_Programs "\" displayName ".lnk", "int", 1)
    }

    static SetProperty(store, id, value, isGuid := false) {
        key := Buffer(20, 0)
        DllCall("ole32\CLSIDFromString", "wstr", "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", "ptr", key, "hresult")
        NumPut("uint", id, key, 16)
        pv := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        if isGuid {
            guid := this.Guid(value)
            NumPut("ushort", 72, pv) ; VT_CLSID
            NumPut("ptr", guid.Ptr, pv, 8)
        } else {
            NumPut("ushort", 31, pv) ; VT_LPWSTR
            NumPut("ptr", StrPtr(value), pv, 8)
        }
        ComCall(6, store, "ptr", key, "ptr", pv)
    }

    static Show(title, text) {
        this.Initialize()
        manager := this.Factory("Windows.UI.Notifications.ToastNotificationManager",
            "{50AC103F-D235-4598-BBEF-98FE4D1A3AD4}")
        app := this.HString(this.AppId)
        try ComCall(7, manager, "ptr", app, "ptr*", &ptr := 0)
        finally DllCall("combase\WindowsDeleteString", "ptr", app)
        notifier := ComValue(13, ptr, 1)

        className := this.HString("Windows.Data.Xml.Dom.XmlDocument")
        try DllCall("combase\RoActivateInstance", "ptr", className, "ptr*", &ptr := 0, "hresult")
        finally DllCall("combase\WindowsDeleteString", "ptr", className)
        document := ComValue(13, ptr, 1)
        io := ComObjQuery(document, "{6CD0E74E-EE65-4489-9EBF-CA43E87BA637}")
        xml := this.HString('<toast activationType="protocol" launch="' this.Protocol ':dismiss">'
            '<visual><binding template="ToastGeneric"><text>' this.Escape(title)
            '</text><text>' this.Escape(text) '</text></binding></visual></toast>')
        try ComCall(6, io, "ptr", xml) ; IXmlDocumentIO.LoadXml
        finally DllCall("combase\WindowsDeleteString", "ptr", xml)
        dom := ComObjQuery(document, "{F7F3A506-1E87-42D6-BCFB-B8C809FA5494}")
        factory := this.Factory("Windows.UI.Notifications.ToastNotification",
            "{04124B20-82C6-4229-B109-FD9ED4662B53}")
        ComCall(6, factory, "ptr", dom, "ptr*", &ptr := 0)
        notification := ComValue(13, ptr, 1)
        ComCall(6, notifier, "ptr", notification) ; Show; never Hide/remove history
    }

    static Initialize() {
        static initialized := false
        if initialized
            return
        hr := DllCall("combase\RoInitialize", "uint", 0, "int")
        ; AHK may have already initialized COM with a different apartment model.
        if hr < 0 && hr != -2147417850
            throw OSError(hr)
        if hr >= 0
            OnExit((*) => DllCall("combase\RoUninitialize"))
        initialized := true
    }

    static Factory(name, iid) {
        str := this.HString(name)
        try DllCall("combase\RoGetActivationFactory", "ptr", str,
            "ptr", this.Guid(iid), "ptr*", &ptr := 0, "hresult")
        finally DllCall("combase\WindowsDeleteString", "ptr", str)
        return ComValue(13, ptr, 1)
    }

    static Guid(value) {
        result := Buffer(16)
        DllCall("ole32\CLSIDFromString", "wstr", value, "ptr", result, "hresult")
        return result
    }

    static HString(value) {
        DllCall("combase\WindowsCreateString", "wstr", value, "uint", StrLen(value), "ptr*", &ptr := 0, "hresult")
        return ptr
    }

    static Escape(value) {
        value := RegExReplace(value, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
        return StrReplace(StrReplace(StrReplace(value, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")
    }
}
