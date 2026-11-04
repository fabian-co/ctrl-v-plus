# Extensión de Nautilus (GNOME Files) para Ctrl V +.
# Agrega "Pegar imagen" al clic derecho en el fondo de una carpeta y sobre una carpeta.
# Requiere nautilus-python (paquete python3-nautilus / nautilus-python).
import os
import subprocess

import gi

try:
    gi.require_version("Nautilus", "4.0")
except ValueError:
    gi.require_version("Nautilus", "3.0")
from gi.repository import GObject, Nautilus  # noqa: E402

CMD = os.path.expanduser("~/.local/bin/ctrlvplus")


def _ruta(archivo):
    try:
        return archivo.get_location().get_path()
    except Exception:
        return None


class CtrlVPlusMenu(GObject.GObject, Nautilus.MenuProvider):
    def _item(self, nombre, carpeta):
        item = Nautilus.MenuItem(
            name=nombre,
            label="Pegar imagen",
            tip="Guardar la imagen del portapapeles como archivo aquí",
            icon="image-x-generic",
        )
        item.connect("activate", lambda *_: subprocess.Popen([CMD, "pegar", carpeta]))
        return item

    # Nautilus 4: (self, current_folder) | Nautilus 3: (self, window, current_folder)
    def get_background_items(self, *args):
        carpeta = _ruta(args[-1])
        return [self._item("CtrlVPlus::PegarImagenFondo", carpeta)] if carpeta else []

    # Nautilus 4: (self, files) | Nautilus 3: (self, window, files)
    def get_file_items(self, *args):
        archivos = args[-1]
        if len(archivos) != 1 or not archivos[0].is_directory():
            return []
        carpeta = _ruta(archivos[0])
        return [self._item("CtrlVPlus::PegarImagenCarpeta", carpeta)] if carpeta else []
