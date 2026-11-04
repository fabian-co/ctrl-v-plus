# Ctrl V +

Pega imágenes del portapapeles **como archivo** en el Explorador de Windows.

Copias una imagen de una página web, de una app o de una captura de pantalla, vas a una carpeta y presionas **Ctrl+V**: se crea un archivo `Imagen_AAAA-MM-DD_HHMMSS.png`.

## Qué hace

- **Ctrl+V en el Explorador o en el Escritorio**
  - Si copiaste una **imagen**, la guarda como `.png` en la carpeta abierta y la deja seleccionada. Se conserva la transparencia cuando la imagen la trae.
  - Si copiaste **archivos**, se pegan como siempre.
  - Si copiaste **texto**, no cambia nada.
  - Si estás **escribiendo** (renombrando un archivo, en la barra de direcciones o en la búsqueda), se pega normal.
  - En cualquier otra aplicación, Ctrl+V no cambia.
- **Menú del clic derecho → "Pegar imagen"**
  - Aparece en el fondo de una carpeta, en el Escritorio y al hacer clic derecho sobre una carpeta.
  - Solo se muestra cuando hay una imagen en el portapapeles.

## Instalación

1. Descarga `Instalar Ctrl V +.exe` desde [Releases](../../releases/latest).
2. Ábrelo y elige **Instalar**.

- No necesita permisos de administrador. Se instala en `%LOCALAPPDATA%\CtrlVPlus`.
- Arranca solo con Windows y queda en la bandeja del sistema.
- Para desinstalarlo: **Configuración → Aplicaciones → Ctrl V + → Desinstalar**.
- Modo silencioso: `"Instalar Ctrl V +.exe" /silent` para instalar y `Desinstalar.exe /uninstall /silent` para desinstalar.

> El ejecutable no está firmado digitalmente, así que Windows SmartScreen puede mostrar un aviso. Elige **Más información → Ejecutar de todas formas**.

## Compilar desde el código

Requisitos: [AutoHotkey v2](https://www.autohotkey.com/) y [Ahk2Exe](https://github.com/AutoHotkey/Ahk2Exe), este último en `AutoHotkey\Compiler\`.

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

El instalador queda en `dist\Instalar Ctrl V +.exe`.

También puedes ejecutar `fuente\CtrlVPlus.ahk` directamente con AutoHotkey v2, sin compilar.

## Archivos

| Archivo | Qué es |
|---|---|
| `fuente/CtrlVPlus.ahk` | El programa: atajo Ctrl+V, menú contextual y guardado PNG |
| `fuente/Instalador.ahk` | Instalador y desinstalador; incrusta `CtrlVPlus.exe` |
| `build.ps1` | Compila los dos ejecutables |

## Cómo funciona

- Ctrl+V se intercepta solo cuando el foco está en la vista de archivos (`SHELLDLL_DefView`) del Explorador o del Escritorio.
- La imagen se toma del formato `PNG` del portapapeles si existe; si no, se convierte el bitmap a PNG con GDI+.
- La entrada **Pegar imagen** se escribe en `HKCU\Software\Classes\...\shell` cuando el portapapeles tiene una imagen y se borra cuando no la tiene. Por eso solo se ve en ese caso.

## Licencia

[MIT](LICENSE)
