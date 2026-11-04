#!/bin/sh
# Desinstala Ctrl V + para Linux.   Uso:  sh uninstall.sh
set -u

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"

rm -f "$HOME/.local/bin/ctrlvplus" \
      "$DATA/nautilus-python/extensions/ctrlvplus_nautilus.py" \
      "$DATA/nautilus/scripts/Pegar imagen" \
      "$DATA/kio/servicemenus/ctrlvplus.desktop" \
      "$DATA/nemo/actions/ctrlvplus-fondo.nemo_action" \
      "$DATA/nemo/actions/ctrlvplus-carpeta.nemo_action"

if [ -f "$CONF/Thunar/uca.xml" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$CONF/Thunar/uca.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
ruta = sys.argv[1]
arbol = ET.parse(ruta); raiz = arbol.getroot()
for a in list(raiz):
    if (a.findtext("unique-id") or "") == "ctrlvplus-pegar-imagen":
        raiz.remove(a)
arbol.write(ruta, encoding="UTF-8", xml_declaration=True)
PY
fi

echo "Ctrl V + se desinstaló. Reinicia el explorador de archivos para que desaparezca la opción."
