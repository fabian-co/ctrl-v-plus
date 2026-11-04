# Ctrl V +

Pega imágenes del portapapeles **como archivo** en el explorador de archivos: Windows, macOS y Linux.

Copias una imagen de una página web, de una app o de una captura de pantalla, vas a una carpeta y pegas: se crea un archivo `Imagen_AAAA-MM-DD_HHMMSS.png`.

## Qué funciona en cada sistema

| | Windows 10/11 | macOS 13+ | Linux |
|---|---|---|---|
| Atajo de pegar en el explorador | ✅ **Ctrl+V** en el Explorador y el Escritorio | ✅ **Cmd+V** en Finder | — (ver abajo) |
| Opción **Pegar imagen** en el clic derecho | ✅ Fondo de carpeta, Escritorio y sobre una carpeta | ✅ Sobre una carpeta o archivo → *Acciones rápidas / Servicios* | ✅ Nautilus, Dolphin, Nemo y Thunar |
| La opción aparece solo si hay una imagen copiada | ✅ | ❌ Siempre visible; si no hay imagen, avisa | ❌ Siempre visible; si no hay imagen, avisa |
| Texto, archivos y renombrar siguen igual | ✅ | ✅ | ✅ |

En todos los sistemas, si la imagen trae transparencia, se conserva.

## Funciona con programas de diseño (vectores → PNG)

Funciona con cualquier programa que, al copiar, deje una versión en imagen en el portapapeles, no solo con navegadores. Esto incluye programas **vectoriales**:

- **Adobe Illustrator:** selecciona tus vectores, presiona **Ctrl+C**, ve a una carpeta y pega. Se crea un **PNG con fondo transparente** de lo que copiaste. Probado en Windows con Illustrator 2026: una estrella vectorial de 240 pt quedó como un PNG de 963×916 px.
- **Photoshop, Figma, PowerPoint, Word, Excel, Paint, la herramienta de Recortes**, capturas de pantalla, etc.: igual. Se guarda lo que el programa ponga como imagen en el portapapeles.

> Ctrl V + guarda la imagen que el programa pone en el portapapeles. La resolución y la transparencia dependen de ese programa. Si necesitas el archivo vectorial (SVG, AI o PDF), usa la exportación del propio programa.
>
> En macOS, si el programa solo copia PDF (algunos programas vectoriales lo hacen), Ctrl V + lo convierte a PNG. En ese caso la resolución puede ser menor. Por ahora esto solo se ha probado en Windows.

## Instalación

Descarga el archivo de tu sistema desde [Releases](../../releases/latest).

### Windows
1. Descarga y abre `CtrlVPlus-Windows-Setup.exe`, y elige **Instalar**.
2. No necesita permisos de administrador. Arranca solo con Windows.
3. Para desinstalar: **Configuración → Aplicaciones → Ctrl V + → Desinstalar**.

> El ejecutable no está firmado digitalmente, así que SmartScreen puede mostrar un aviso. Elige **Más información → Ejecutar de todas formas**.

### macOS
1. Descarga y descomprime `CtrlVPlus-macOS.zip`.
2. Abre **Terminal** y ejecuta:
   ```bash
   bash ~/Downloads/CtrlVPlus-macOS/install.sh
   ```
3. Da los permisos que pide macOS:
   - **Accesibilidad** (Ajustes del Sistema → Privacidad y seguridad → Accesibilidad → *Ctrl V +*). Lo necesita **Cmd+V**.
   - **Automatización → Finder**: se pide la primera vez que pegas. Sirve para saber qué carpeta está abierta.
4. La app queda en la barra de menú (icono de portapapeles). Desde ahí puedes pausarla o quitar el inicio automático.
5. Para desinstalar: `bash ~/Downloads/CtrlVPlus-macOS/uninstall.sh`.

> No está firmada con una cuenta de Apple Developer. El instalador quita la marca de "descargado de internet" para que Gatekeeper no la bloquee.
>
> Si **Pegar imagen** no aparece en el clic derecho: Ajustes del Sistema → Teclado → Atajos de teclado → Servicios → *Archivos y carpetas* → activa **Pegar imagen**.

### Linux
1. Instala la herramienta del portapapeles:
   - Wayland: `wl-clipboard`
   - X11: `xclip`
   ```bash
   sudo apt install wl-clipboard xclip      # Ubuntu/Debian
   sudo dnf install wl-clipboard xclip      # Fedora
   sudo pacman -S wl-clipboard xclip        # Arch
   ```
2. Descomprime y ejecuta el instalador (sin sudo):
   ```bash
   tar xzf CtrlVPlus-Linux.tar.gz
   sh CtrlVPlus-Linux/install.sh
   ```
3. Reinicia el explorador de archivos (`nautilus -q`, `thunar -q`, etc.).

El instalador agrega **Pegar imagen** a los exploradores que encuentre:

| Explorador | Dónde aparece |
|---|---|
| **Nautilus** (GNOME) | En el menú, en el fondo de la carpeta y sobre una carpeta. Requiere `python3-nautilus` / `nautilus-python`; sin eso, va en *Scripts → Pegar imagen* |
| **Dolphin** (KDE) | Menú del clic derecho |
| **Nemo** (Cinnamon) | En el fondo de la carpeta y sobre una carpeta |
| **Thunar** (XFCE) | Menú del clic derecho (acción personalizada) |

También se puede usar desde la terminal: `ctrlvplus pegar ~/Imágenes`.

**¿Por qué no hay Ctrl+V en Linux?** En Wayland (Ubuntu y Fedora actuales) el sistema no permite que un programa intercepte las teclas de otro, y cada explorador maneja Ctrl+V por su cuenta. Para quitarlo: `sh CtrlVPlus-Linux/uninstall.sh`.

## Compilar desde el código

| Sistema | Requisitos | Comando | Resultado |
|---|---|---|---|
| Windows | [AutoHotkey v2](https://www.autohotkey.com/) + [Ahk2Exe](https://github.com/AutoHotkey/Ahk2Exe) | `powershell -ExecutionPolicy Bypass -File windows\build.ps1` | `dist\Instalar Ctrl V +.exe` |
| macOS | Xcode Command Line Tools | `bash macos/build.sh` | `dist/CtrlVPlus-macOS.zip` |
| Linux | python3 (no se compila) | `sh linux/install.sh` | — |

GitHub Actions compila y prueba las tres versiones en cada cambio. Al crear una etiqueta `v*`, publica un Release con los tres instaladores.

## Estructura

```
windows/   CtrlVPlus.ahk (programa), Instalador.ahk, build.ps1
macos/     Sources/main.swift (app de barra de menú), Info.plist, build.sh, install.sh, uninstall.sh
linux/     ctrlvplus (Python), integraciones/ (extensión Nautilus), install.sh, uninstall.sh
```

## Cómo funciona

- **Windows:** Ctrl+V se intercepta solo cuando el foco está en la vista de archivos (`SHELLDLL_DefView`). La opción del menú se escribe en `HKCU\Software\Classes\...\shell` mientras haya una imagen copiada, y se borra cuando ya no la hay.
- **macOS:** un *event tap* detecta Cmd+V cuando Finder está al frente y no se está escribiendo en un campo de texto. Le pregunta a Finder por AppleScript qué carpeta está abierta. El clic derecho es un *Servicio* de macOS (`NSServices`).
- **Linux:** lee la imagen con `wl-paste` o `xclip` y la guarda con su formato original; si hay PNG, usa PNG.

## Licencia

[MIT](LICENSE)
