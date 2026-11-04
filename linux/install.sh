#!/bin/sh
# Instala Ctrl V + para Linux (solo para tu usuario, sin sudo).
# Agrega "Pegar imagen" al clic derecho de: Nautilus (GNOME), Dolphin (KDE),
# Nemo (Cinnamon) y Thunar (XFCE), los que estén instalados.
# Uso:  sh install.sh
set -eu

AQUI="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
CMD="$BIN/ctrlvplus"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
instalados=""

command -v python3 >/dev/null 2>&1 || { echo "Error: se necesita python3." >&2; exit 1; }

mkdir -p "$BIN"
cp "$AQUI/ctrlvplus" "$CMD"
chmod 755 "$CMD"

# --- Nautilus -------------------------------------------------------------
if command -v nautilus >/dev/null 2>&1; then
    if find /usr/lib /usr/lib64 /usr/local/lib -maxdepth 4 -name 'libnautilus-python.so' 2>/dev/null | grep -q .; then
        mkdir -p "$DATA/nautilus-python/extensions"
        cp "$AQUI/integraciones/ctrlvplus_nautilus.py" "$DATA/nautilus-python/extensions/"
        instalados="$instalados Nautilus"
        reiniciar_nautilus=1
    else
        # Alternativa sin nautilus-python: clic derecho > Scripts > Pegar imagen
        mkdir -p "$DATA/nautilus/scripts"
        printf '#!/bin/sh\nexec "%s" pegar "$@"\n' "$CMD" > "$DATA/nautilus/scripts/Pegar imagen"
        chmod 755 "$DATA/nautilus/scripts/Pegar imagen"
        instalados="$instalados Nautilus(Scripts)"
        falta_nautilus_python=1
    fi
fi

# --- Dolphin (KDE) --------------------------------------------------------
if command -v dolphin >/dev/null 2>&1; then
    mkdir -p "$DATA/kio/servicemenus"
    cat > "$DATA/kio/servicemenus/ctrlvplus.desktop" <<EOF
[Desktop Entry]
Type=Service
MimeType=inode/directory;
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
X-KDE-Priority=TopLevel
Actions=pegarImagen;

[Desktop Action pegarImagen]
Name=Pegar imagen
Icon=image-x-generic
Exec="$CMD" pegar %f
EOF
    chmod 755 "$DATA/kio/servicemenus/ctrlvplus.desktop"
    instalados="$instalados Dolphin"
fi

# --- Nemo (Cinnamon) ------------------------------------------------------
if command -v nemo >/dev/null 2>&1; then
    mkdir -p "$DATA/nemo/actions"
    cat > "$DATA/nemo/actions/ctrlvplus-fondo.nemo_action" <<EOF
[Nemo Action]
Name=Pegar imagen
Comment=Guardar la imagen del portapapeles como archivo aquí
Exec="$CMD" pegar %P
Icon-Name=image-x-generic
Selection=None
Quote=double
Extensions=any;
EOF
    cat > "$DATA/nemo/actions/ctrlvplus-carpeta.nemo_action" <<EOF
[Nemo Action]
Name=Pegar imagen
Comment=Guardar la imagen del portapapeles en esta carpeta
Exec="$CMD" pegar %F
Icon-Name=image-x-generic
Selection=s
Quote=double
Extensions=dir;
EOF
    instalados="$instalados Nemo"
fi

# --- Thunar (XFCE) --------------------------------------------------------
if command -v thunar >/dev/null 2>&1; then
    mkdir -p "$CONF/Thunar"
    python3 - "$CONF/Thunar/uca.xml" "$CMD" <<'PY'
import os, sys, xml.etree.ElementTree as ET
ruta, cmd = sys.argv[1], sys.argv[2]
if os.path.exists(ruta):
    arbol = ET.parse(ruta); raiz = arbol.getroot()
else:
    raiz = ET.Element("actions"); arbol = ET.ElementTree(raiz)
for a in list(raiz):
    if (a.findtext("unique-id") or "") == "ctrlvplus-pegar-imagen":
        raiz.remove(a)
a = ET.SubElement(raiz, "action")
for etiqueta, texto in [("icon", "image-x-generic"), ("name", "Pegar imagen"),
                        ("unique-id", "ctrlvplus-pegar-imagen"),
                        ("command", f'"{cmd}" pegar %f'),
                        ("description", "Guardar la imagen del portapapeles como archivo aquí"),
                        ("patterns", "*")]:
    ET.SubElement(a, etiqueta).text = texto
ET.SubElement(a, "directories")
arbol.write(ruta, encoding="UTF-8", xml_declaration=True)
PY
    instalados="$instalados Thunar"
fi

# --- Resumen --------------------------------------------------------------
echo "Ctrl V + instalado en $CMD"
if [ -n "$instalados" ]; then
    echo "Menú 'Pegar imagen' agregado en:$instalados"
else
    echo "No encontré Nautilus, Dolphin, Nemo ni Thunar. Puedes usarlo desde la terminal:"
    echo "    ctrlvplus pegar /ruta/de/la/carpeta"
fi

if [ -n "${WAYLAND_DISPLAY:-}" ] && ! command -v wl-paste >/dev/null 2>&1; then
    echo
    echo "IMPORTANTE: falta wl-clipboard para leer el portapapeles en Wayland. Instálalo con:"
    echo "    Ubuntu/Debian: sudo apt install wl-clipboard"
    echo "    Fedora:        sudo dnf install wl-clipboard"
    echo "    Arch:          sudo pacman -S wl-clipboard"
fi
if [ -z "${WAYLAND_DISPLAY:-}" ] && ! command -v xclip >/dev/null 2>&1; then
    echo
    echo "IMPORTANTE: falta xclip para leer el portapapeles. Instálalo con:"
    echo "    Ubuntu/Debian: sudo apt install xclip"
    echo "    Fedora:        sudo dnf install xclip"
    echo "    Arch:          sudo pacman -S xclip"
fi
if [ "${falta_nautilus_python:-0}" = 1 ]; then
    echo
    echo "Nautilus: por ahora la opción está en clic derecho > Scripts > Pegar imagen."
    echo "Para tenerla directo en el menú instala nautilus-python y vuelve a ejecutar este instalador:"
    echo "    Ubuntu/Debian: sudo apt install python3-nautilus"
    echo "    Fedora:        sudo dnf install nautilus-python"
    echo "    Arch:          sudo pacman -S python-nautilus"
fi
if [ "${reiniciar_nautilus:-0}" = 1 ]; then
    echo
    echo "Cierra y vuelve a abrir Nautilus para ver la opción (o ejecuta: nautilus -q)."
fi
if command -v thunar >/dev/null 2>&1; then
    echo "Thunar: cierra y vuelve a abrir Thunar para ver la opción (o ejecuta: thunar -q)."
fi
