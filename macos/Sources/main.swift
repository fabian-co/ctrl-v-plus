// Ctrl V + para macOS
//
//  1) Cmd+V en Finder: si el portapapeles tiene una IMAGEN, la guarda como
//     .png en la carpeta de la ventana de Finder al frente (o en el
//     Escritorio si no hay ventanas). Texto, archivos y renombrado: normal.
//  2) Servicio "Pegar imagen" en el clic derecho de Finder (sobre una
//     carpeta o un archivo -> se guarda en esa carpeta / en su carpeta).
//
//  Uso:  CtrlVPlus                    -> app de la barra de menú
//        CtrlVPlus --pegar <carpeta>  -> guarda la imagen ahí y termina
//        CtrlVPlus --desregistrar     -> quita el inicio automático

import Cocoa
import ApplicationServices
import ServiceManagement

let nombreApp = "Ctrl V +"

// MARK: - Portapapeles -> archivo PNG

enum Portapapeles {
    static func hayImagen(_ pb: NSPasteboard = .general) -> Bool {
        let tipos = pb.types ?? []
        // Archivos copiados en Finder traen también un icono TIFF: no cuentan.
        if tipos.contains(.fileURL) { return false }
        return tipos.contains(.png) || tipos.contains(.tiff) || NSImage.canInit(with: pb)
    }

    static func datosPNG(_ pb: NSPasteboard = .general) -> Data? {
        if let d = pb.data(forType: .png), !d.isEmpty { return d }   // conserva transparencia
        guard let img = NSImage(pasteboard: pb),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Guarda la imagen del portapapeles en `carpeta`. Devuelve la ruta o nil.
    static func guardar(en carpeta: URL) -> URL? {
        guard hayImagen(), let datos = datosPNG() else { return nil }
        var esDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: carpeta.path, isDirectory: &esDir), esDir.boolValue else { return nil }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        let base = "Imagen_" + f.string(from: Date())
        var url = carpeta.appendingPathComponent(base + ".png")
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = carpeta.appendingPathComponent("\(base)_\(n).png")
            n += 1
        }
        do { try datos.write(to: url); return url } catch { return nil }
    }
}

// MARK: - Finder (AppleScript)

enum Finder {
    static func ejecutar(_ fuente: String) -> String? {
        var err: NSDictionary?
        let r = NSAppleScript(source: fuente)?.executeAndReturnError(&err)
        return err == nil ? r?.stringValue : nil
    }

    /// Carpeta de la ventana de Finder al frente, o el Escritorio si no hay ventanas.
    static func carpetaActual() -> URL? {
        let fuente = """
        tell application "Finder"
            if (count of Finder windows) > 0 then
                try
                    return POSIX path of (target of front Finder window as alias)
                on error
                    return ""
                end try
            end if
            return POSIX path of (desktop as alias)
        end tell
        """
        guard let ruta = ejecutar(fuente), !ruta.isEmpty else { return nil }   // p. ej. "Recientes"
        return URL(fileURLWithPath: ruta, isDirectory: true)
    }

    static func seleccionar(_ url: URL) {
        let p = url.path.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        _ = ejecutar("tell application \"Finder\" to select (POSIX file \"\(p)\" as alias)")
    }
}

func pegarEnFinder() {
    guard let carpeta = Finder.carpetaActual(), let url = Portapapeles.guardar(en: carpeta) else {
        NSSound.beep()
        return
    }
    Finder.seleccionar(url)
}

/// ¿El foco está en un campo de texto? (renombrar, búsqueda, barra "Ir a")
func editandoTexto() -> Bool {
    let sistema = AXUIElementCreateSystemWide()
    var foco: CFTypeRef?
    guard AXUIElementCopyAttributeValue(sistema, kAXFocusedUIElementAttribute as CFString, &foco) == .success,
          let elemento = foco, CFGetTypeID(elemento) == AXUIElementGetTypeID() else { return false }
    var rol: CFTypeRef?
    AXUIElementCopyAttributeValue(elemento as! AXUIElement, kAXRoleAttribute as CFString, &rol)
    let r = (rol as? String) ?? ""
    return ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(r)
}

// MARK: - Atajo Cmd+V (event tap; requiere permiso de Accesibilidad)

final class Atajo {
    private var tap: CFMachPort?
    var activo = true

    var iniciado: Bool { tap != nil }

    func iniciar() -> Bool {
        if tap != nil { return true }
        let mascara = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let t = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mascara,
            callback: { _, tipo, evento, refcon in
                let yo = Unmanaged<Atajo>.fromOpaque(refcon!).takeUnretainedValue()
                return yo.manejar(tipo, evento)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        tap = t
        let fuente = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), fuente, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        return true
    }

    private func manejar(_ tipo: CGEventType, _ evento: CGEvent) -> Unmanaged<CGEvent>? {
        let seguir = Unmanaged.passUnretained(evento)
        if tipo == .tapDisabledByTimeout || tipo == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return seguir
        }
        guard activo, tipo == .keyDown,
              evento.getIntegerValueField(.keyboardEventKeycode) == 9   // tecla V
        else { return seguir }
        let mods = evento.flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
        guard mods == .maskCommand,
              NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder",
              Portapapeles.hayImagen(),
              !editandoTexto()
        else { return seguir }

        DispatchQueue.main.async { pegarEnFinder() }   // fuera del callback (no bloquear el tap)
        return nil                                      // consumir Cmd+V
    }
}

// MARK: - Servicio "Pegar imagen" (clic derecho en Finder)

final class Servicio: NSObject {
    @objc func pegarImagen(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        let urls = (pboard.readObjects(forClasses: [NSURL.self],
                                       options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        guard var destino = urls.first else { return }
        if !destino.hasDirectoryPath {
            var esDir: ObjCBool = false
            FileManager.default.fileExists(atPath: destino.path, isDirectory: &esDir)
            if !esDir.boolValue { destino = destino.deletingLastPathComponent() }
        }
        if let url = Portapapeles.guardar(en: destino) {
            Finder.seleccionar(url)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            let a = NSAlert()
            a.messageText = nombreApp
            a.informativeText = Portapapeles.hayImagen()
                ? "No se pudo guardar la imagen en \(destino.path)."
                : "El portapapeles no tiene una imagen."
            a.runModal()
        }
    }
}

// MARK: - App de la barra de menú

final class AppDelegate: NSObject, NSApplicationDelegate {
    let atajo = Atajo()
    let servicio = Servicio()
    var status: NSStatusItem!
    var itemActivo: NSMenuItem!
    var itemInicio: NSMenuItem!
    var itemPermiso: NSMenuItem!
    var temporizador: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.servicesProvider = servicio
        NSUpdateDynamicServices()
        construirMenu()
        primerArranque()
        intentarAtajo(pedirPermiso: true)
    }

    func construirMenu() {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nombreApp)
        status.button?.image?.isTemplate = true
        status.button?.toolTip = "\(nombreApp): pega imágenes como archivo en Finder"

        let menu = NSMenu()
        let titulo = NSMenuItem(title: nombreApp, action: nil, keyEquivalent: "")
        titulo.isEnabled = false
        menu.addItem(titulo)
        menu.addItem(.separator())

        itemActivo = NSMenuItem(title: "Activo (Cmd+V en Finder)", action: #selector(alternarActivo), keyEquivalent: "")
        itemActivo.target = self
        menu.addItem(itemActivo)

        itemInicio = NSMenuItem(title: "Abrir al iniciar sesión", action: #selector(alternarInicio), keyEquivalent: "")
        itemInicio.target = self
        menu.addItem(itemInicio)

        itemPermiso = NSMenuItem(title: "⚠︎ Dar permiso de Accesibilidad…", action: #selector(abrirAccesibilidad), keyEquivalent: "")
        itemPermiso.target = self
        menu.addItem(itemPermiso)

        menu.addItem(.separator())
        let salir = NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(salir)
        status.menu = menu
        actualizarMenu()
    }

    func actualizarMenu() {
        itemActivo.state = atajo.activo ? .on : .off
        itemActivo.isEnabled = atajo.iniciado
        itemInicio.state = SMAppService.mainApp.status == .enabled ? .on : .off
        itemPermiso.isHidden = atajo.iniciado
    }

    func primerArranque() {
        let d = UserDefaults.standard
        if !d.bool(forKey: "configurado") {
            try? SMAppService.mainApp.register()
            d.set(true, forKey: "configurado")
        }
    }

    func intentarAtajo(pedirPermiso: Bool) {
        let opciones = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: pedirPermiso] as CFDictionary
        if AXIsProcessTrustedWithOptions(opciones) && atajo.iniciar() {
            temporizador?.invalidate()
            temporizador = nil
        } else if temporizador == nil {
            temporizador = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
                self?.intentarAtajo(pedirPermiso: false)
            }
        }
        actualizarMenu()
    }

    @objc func alternarActivo() {
        atajo.activo.toggle()
        actualizarMenu()
    }

    @objc func alternarInicio() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }
        actualizarMenu()
    }

    @objc func abrirAccesibilidad() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Arranque

let args = CommandLine.arguments
if let i = args.firstIndex(of: "--pegar") {
    let ruta = i + 1 < args.count ? args[i + 1] : FileManager.default.currentDirectoryPath
    if let url = Portapapeles.guardar(en: URL(fileURLWithPath: ruta, isDirectory: true)) {
        print(url.path)
        exit(0)
    }
    FileHandle.standardError.write("No hay una imagen en el portapapeles o la carpeta no existe.\n".data(using: .utf8)!)
    exit(1)
}
if args.contains("--desregistrar") {
    try? SMAppService.mainApp.unregister()
    exit(0)
}

let app = NSApplication.shared
let delegado = AppDelegate()
app.delegate = delegado
app.setActivationPolicy(.accessory)
app.run()
