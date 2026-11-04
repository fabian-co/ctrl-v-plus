; =====================================================================
;  Ctrl V +  (AutoHotkey v2)
;
;  1) Ctrl+V en el Explorador / Escritorio:
;       - Si el portapapeles tiene una IMAGEN -> la guarda como .png en la
;         carpeta abierta y la selecciona.
;       - Si tiene archivos, texto u otra cosa -> pegado normal de Windows.
;       - Si estás escribiendo (renombrar, barra de direcciones, búsqueda)
;         -> pegado normal.
;  2) Menú contextual "Pegar imagen" (clic derecho en el fondo de una
;     carpeta, en el Escritorio o sobre una carpeta). Solo aparece cuando
;     el portapapeles tiene una imagen.
;
;  Uso:  CtrlVPlus.exe                 -> modo residente (bandeja)
;        CtrlVPlus.exe /pegar "carpeta" -> guarda la imagen ahí y termina
; =====================================================================
#Requires AutoHotkey v2.0
#SingleInstance Off
;@Ahk2Exe-SetName Ctrl V +
;@Ahk2Exe-SetDescription Ctrl V + : pega imágenes como archivo
;@Ahk2Exe-SetVersion 1.2.0

global CF_BITMAP := 2
global CF_DIB    := 8
global CF_HDROP  := 15
global CF_PNG    := DllCall("RegisterClipboardFormat", "Str", "PNG", "UInt")

global VERBO  := "CtrlVPlus.PegarImagen"
global CLAVES := [
    "HKCU\Software\Classes\Directory\Background\shell\" VERBO,
    "HKCU\Software\Classes\DesktopBackground\Shell\" VERBO,
    "HKCU\Software\Classes\Directory\shell\" VERBO,
]

; ---------------------------------------------------------------------
; Modo "pegar en carpeta" (lo usa el menú contextual)
if (A_Args.Length >= 2 && A_Args[1] = "/pegar") {
    carpeta := RTrim(A_Args[2], '\"')
    if (StrLen(carpeta) = 2 && SubStr(carpeta, 2) = ":")   ; "C:" -> "C:\"
        carpeta .= "\"
    if !HayImagen() {
        MsgBox "El portapapeles no tiene una imagen.", "Ctrl V +", "Icon! T3"
        ExitApp 1
    }
    ruta := GuardarImagenEn(carpeta)
    if ruta
        SeleccionarArchivo(ruta, BuscarVentanaDeCarpeta(carpeta))
    else
        MsgBox "No se pudo guardar la imagen en:`n" carpeta, "Ctrl V +", "Iconx"
    ExitApp ruta ? 0 : 1
}

; ---------------------------------------------------------------------
; Modo residente: una sola instancia
DllCall("CreateMutex", "Ptr", 0, "Int", 0, "Str", "CtrlVPlus_Residente")
if (A_LastError = 183)        ; ERROR_ALREADY_EXISTS
    ExitApp

Persistent
A_IconTip := "Ctrl V + : pega imágenes como archivo en el Explorador"
TraySetIcon("shell32.dll", 303)

OnClipboardChange ActualizarMenuContextual
OnExit (*) => QuitarMenuContextual()
ActualizarMenuContextual()

#HotIf EsVistaDeArchivos()
$^v:: {
    if !HayImagen() {
        Send "^v"
        return
    }
    carpeta := CarpetaActual()
    if (carpeta = "" || !DirExist(carpeta)) {
        Aviso("Esta ubicación no es una carpeta normal; no se puede guardar la imagen.")
        return
    }
    ruta := GuardarImagenEn(carpeta)
    if ruta
        SeleccionarArchivo(ruta, WinExist("A"))
    else
        Aviso("No se pudo guardar la imagen del portapapeles.")
}
#HotIf

; ---------------------------------------------------------------------
; Menú contextual: se agrega solo mientras haya una imagen copiada
ActualizarMenuContextual(*) {
    static hayAntes := ""
    hay := HayImagen()
    if (hay = hayAntes)
        return
    hayAntes := hay
    if hay
        PonerMenuContextual()
    else
        QuitarMenuContextual()
}

PonerMenuContextual() {
    global CLAVES
    exe := A_IsCompiled ? '"' A_ScriptFullPath '"' : '"' A_AhkPath '" "' A_ScriptFullPath '"'
    for i, k in CLAVES {
        arg := (i = 3) ? "%1" : "%V"       ; sobre carpeta -> %1, fondo -> %V
        try {
            RegWrite "Pegar imagen", "REG_SZ", k, "MUIVerb"
            RegWrite (A_IsCompiled ? A_ScriptFullPath : A_AhkPath) ",0", "REG_SZ", k, "Icon"
            RegWrite exe ' /pegar "' arg '"', "REG_SZ", k "\command"
        }
    }
}

QuitarMenuContextual() {
    global CLAVES
    for k in CLAVES
        try RegDeleteKey k
}

; ---------------------------------------------------------------------
HayImagen() {
    global CF_BITMAP, CF_DIB, CF_HDROP, CF_PNG
    if DllCall("IsClipboardFormatAvailable", "UInt", CF_HDROP)
        return false
    return DllCall("IsClipboardFormatAvailable", "UInt", CF_PNG)
        || DllCall("IsClipboardFormatAvailable", "UInt", CF_DIB)
        || DllCall("IsClipboardFormatAvailable", "UInt", CF_BITMAP)
}

; Guarda la imagen del portapapeles en la carpeta. Devuelve la ruta o "".
GuardarImagenEn(carpeta) {
    global CF_PNG
    if !DirExist(carpeta)
        return ""
    carpeta := RTrim(carpeta, "\")
    nombre := "Imagen_" FormatTime(, "yyyy-MM-dd_HHmmss")
    ruta := carpeta "\" nombre ".png"
    n := 2
    while FileExist(ruta)
        ruta := carpeta "\" nombre "_" n++ ".png"

    ok := false
    if DllCall("IsClipboardFormatAvailable", "UInt", CF_PNG)
        ok := GuardarPngCrudo(ruta)        ; conserva transparencia
    if !ok
        ok := GuardarBitmapComoPng(ruta)
    return ok ? ruta : ""
}

; ---------------------------------------------------------------------
; ¿El foco está en la lista de archivos del Explorador o del Escritorio?
EsVistaDeArchivos() {
    cls := WinGetClass("A")
    if !(cls = "CabinetWClass" || cls = "ExploreWClass" || cls = "Progman" || cls = "WorkerW")
        return false
    try hFoco := ControlGetFocus("A")
    catch
        return false
    if !hFoco
        return false
    h := hFoco
    loop 6 {
        c := ClaseDe(h)
        if InStr(c, "Edit")          ; renombrando / barra de direcciones
            return false
        if c = "SHELLDLL_DefView"
            return true
        h := DllCall("GetParent", "Ptr", h, "Ptr")
        if !h
            break
    }
    return false
}

ClaseDe(hwnd) {
    buf := Buffer(512)
    DllCall("GetClassName", "Ptr", hwnd, "Ptr", buf, "Int", 256)
    return StrGet(buf)
}

CarpetaActual() {
    hwnd := WinExist("A")
    cls := WinGetClass("ahk_id " hwnd)
    if (cls = "Progman" || cls = "WorkerW")
        return A_Desktop
    try {
        for w in ComObject("Shell.Application").Windows {
            if (w.HWND = hwnd)
                return w.Document.Folder.Self.Path
        }
    }
    return ""
}

BuscarVentanaDeCarpeta(carpeta) {
    carpeta := RTrim(carpeta, "\")
    try {
        for w in ComObject("Shell.Application").Windows {
            try {
                if (RTrim(w.Document.Folder.Self.Path, "\") = carpeta)
                    return w.HWND
            }
        }
    }
    return 0
}

SeleccionarArchivo(ruta, hwnd) {
    if !hwnd
        return
    SplitPath ruta, &nombreArchivo
    Sleep 150
    try {
        for w in ComObject("Shell.Application").Windows {
            if (w.HWND = hwnd) {
                item := w.Document.Folder.ParseName(nombreArchivo)
                if item
                    w.Document.SelectItem(item, 1 | 4 | 8 | 16)
                return
            }
        }
    }
}

; ---------------------------------------------------------------------
; Formato "PNG" del portapapeles (navegadores, Office, etc.)
GuardarPngCrudo(ruta) {
    global CF_PNG
    if !AbrirPortapapeles()
        return false
    ok := false
    try {
        hData := DllCall("GetClipboardData", "UInt", CF_PNG, "Ptr")
        if hData {
            tam := DllCall("GlobalSize", "Ptr", hData, "UPtr")
            p := DllCall("GlobalLock", "Ptr", hData, "Ptr")
            if (p && tam) {
                f := FileOpen(ruta, "w")
                f.RawWrite(p, tam)
                f.Close()
                ok := true
            }
            DllCall("GlobalUnlock", "Ptr", hData)
        }
    }
    DllCall("CloseClipboard")
    return ok && FileGetSize(ruta) > 0
}

; Bitmap del portapapeles -> PNG usando GDI+
GuardarBitmapComoPng(ruta) {
    global CF_BITMAP
    if !AbrirPortapapeles()
        return false
    hBmp := DllCall("GetClipboardData", "UInt", CF_BITMAP, "Ptr")
    if hBmp
        hBmp := DllCall("CopyImage", "Ptr", hBmp, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x2000 | 0x4, "Ptr")
    DllCall("CloseClipboard")
    if !hBmp
        return false

    hMod := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    si := Buffer(24, 0), NumPut("UInt", 1, si)
    token := 0
    DllCall("gdiplus\GdiplusStartup", "UPtr*", &token, "Ptr", si, "Ptr", 0)
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBmp, "Ptr", 0, "Ptr*", &pBitmap)
    ok := false
    if pBitmap {
        clsid := Buffer(16)
        DllCall("ole32\CLSIDFromString", "Str", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid)
        r := DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", ruta, "Ptr", clsid, "Ptr", 0)
        ok := (r = 0)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    }
    DllCall("gdiplus\GdiplusShutdown", "UPtr", token)
    DllCall("DeleteObject", "Ptr", hBmp)
    if hMod
        DllCall("FreeLibrary", "Ptr", hMod)
    return ok
}

AbrirPortapapeles() {
    loop 10 {
        if DllCall("OpenClipboard", "Ptr", A_ScriptHwnd)
            return true
        Sleep 30
    }
    return false
}

Aviso(msg) {
    ToolTip msg
    SetTimer () => ToolTip(), -2500
}
