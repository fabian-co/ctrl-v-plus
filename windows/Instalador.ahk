; =====================================================================
;  Instalador de "Ctrl V +"  (AutoHotkey v2, se compila a Setup.exe)
;  - Instala en %LOCALAPPDATA%\CtrlVPlus (no requiere administrador)
;  - Arranca con Windows (acceso directo en Inicio)
;  - Aparece en "Aplicaciones y características" para desinstalar
;  Parámetros: /silent (instala sin preguntar)  /uninstall  [/silent]
; =====================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
;@Ahk2Exe-SetName Ctrl V +
;@Ahk2Exe-SetDescription Instalador de Ctrl V +
;@Ahk2Exe-SetVersion 1.2.0

APP      := "Ctrl V +"
DIR      := EnvGet("LOCALAPPDATA") "\CtrlVPlus"
EXE      := DIR "\CtrlVPlus.exe"
UNINST   := DIR "\Desinstalar.exe"
LNK      := A_Startup "\Ctrl V +.lnk"
REGKEY   := "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\CtrlVPlus"

silent := false, quitar := false
for a in A_Args {
    if (a = "/silent")
        silent := true
    else if (a = "/uninstall")
        quitar := true
}

if quitar
    Desinstalar()
else if silent
    Instalar()
else
    MostrarVentana()
return

; ---------------------------------------------------------------------
MostrarVentana() {
    global APP, EXE
    instalado := FileExist(EXE)
    g := Gui("-MaximizeBox", APP)
    g.SetFont("s11 bold")
    g.AddText("w380", APP)
    g.SetFont("s9 norm")
    g.AddText("w380 y+6",
        "Al presionar Ctrl+V en el Explorador de Windows o en el Escritorio, "
        "si copiaste una imagen (de una página web, una app, una captura...) "
        "se guarda como archivo .png en esa carpeta.`n`n"
        "También agrega la opción 'Pegar imagen' al menú del clic derecho (solo aparece cuando hay una imagen copiada).`n`n"
        "El texto y los archivos se pegan como siempre, y Ctrl+V no cambia en las demás aplicaciones.")
    g.AddText("w380 y+10 cGray", instalado ? "Estado: ya está instalado." : "Estado: no instalado.")
    b1 := g.AddButton("w120 y+14 Default", instalado ? "Reinstalar" : "Instalar")
    b2 := g.AddButton("w120 x+10", "Desinstalar")
    b3 := g.AddButton("w120 x+10", "Cancelar")
    b2.Enabled := instalado
    b1.OnEvent("Click", (*) => (g.Destroy(), Instalar()))
    b2.OnEvent("Click", (*) => (g.Destroy(), Desinstalar()))
    b3.OnEvent("Click", (*) => ExitApp())
    g.OnEvent("Close", (*) => ExitApp())
    g.Show()
}

; ---------------------------------------------------------------------
Instalar() {
    global
    CerrarProgramas()
    try {
        DirCreate DIR
        FileInstall "CtrlVPlus.exe", EXE, 1
        if A_IsCompiled
            FileCopy A_ScriptFullPath, UNINST, 1

        FileCreateShortcut EXE, LNK, DIR, , "Ctrl V +: pega imágenes como archivo"

        RegWrite APP,                       "REG_SZ",    REGKEY, "DisplayName"
        RegWrite "1.2.0",                   "REG_SZ",    REGKEY, "DisplayVersion"
        RegWrite "Ctrl V +",                "REG_SZ",    REGKEY, "Publisher"
        RegWrite EXE,                       "REG_SZ",    REGKEY, "DisplayIcon"
        RegWrite DIR,                       "REG_SZ",    REGKEY, "InstallLocation"
        RegWrite '"' UNINST '" /uninstall', "REG_SZ",    REGKEY, "UninstallString"
        RegWrite 1,                         "REG_DWORD", REGKEY, "NoModify"
        RegWrite 1,                         "REG_DWORD", REGKEY, "NoRepair"
    } catch as e {
        MsgBox "No se pudo instalar:`n" e.Message, APP, "Iconx"
        ExitApp 1
    }
    Run '"' EXE '"', DIR
    if !silent
        MsgBox APP " quedó instalado y ya está activo.`n`n"
            . "Arranca solo con Windows. Lo verás en la bandeja del sistema (junto al reloj).`n"
            . "Para quitarlo: Configuración > Aplicaciones > " APP " > Desinstalar.", APP, "Iconi"
    ExitApp 0
}

Desinstalar() {
    global
    if !silent && MsgBox("¿Desinstalar " APP "?", APP, "YesNo Icon?") != "Yes"
        ExitApp 0
    CerrarProgramas()
    try FileDelete LNK
    for k in ["Directory\Background\shell", "DesktopBackground\Shell", "Directory\shell"]
        try RegDeleteKey "HKCU\Software\Classes\" k "\CtrlVPlus.PegarImagen"
    try RegDeleteKey REGKEY
    try FileDelete EXE
    if !silent
        MsgBox APP " se desinstaló.", APP, "Iconi"
    ; Borrar la carpeta (incluido este desinstalador) cuando termine el proceso
    Run A_ComSpec ' /c timeout /t 2 /nobreak >nul & rmdir /s /q "' DIR '"', , "Hide"
    ExitApp 0
}

CerrarProgramas() {
    ; Versión instalada
    while ProcessExist("CtrlVPlus.exe")
        ProcessClose "CtrlVPlus.exe"
    ; Versión antigua como script .ahk (si existiera)
    DetectHiddenWindows true
    for t in ["PegarComoArchivo.ahk ahk_class AutoHotkey", "CtrlVPlus.ahk ahk_class AutoHotkey"]
        while WinExist(t)
            WinClose
    try FileDelete A_Startup "\PegarComoArchivo.lnk"
    Sleep 300
}

