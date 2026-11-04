#!/bin/bash
# Instala Ctrl V + en ~/Applications (sin contraseña de administrador).
# Uso: abre Terminal y ejecuta:  bash ~/Downloads/CtrlVPlus-macOS/install.sh
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Applications"
APP="$DEST/CtrlVPlus.app"

if [ ! -d "$AQUI/CtrlVPlus.app" ]; then
    echo "No encuentro CtrlVPlus.app junto a este script." >&2
    exit 1
fi

pkill -x CtrlVPlus 2>/dev/null || true
mkdir -p "$DEST"
rm -rf "$APP"
cp -R "$AQUI/CtrlVPlus.app" "$DEST/"

# Quitar la marca de "descargado de internet" para que Gatekeeper no lo bloquee
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

# Registrar la app y su servicio "Pegar imagen"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true

open "$APP"

cat <<'EOF'

Ctrl V + quedó instalado en ~/Applications y ya está abierto (icono en la barra de menú).

Falta dar dos permisos (macOS los pide la primera vez):
  1. Accesibilidad: Ajustes del Sistema > Privacidad y seguridad > Accesibilidad > activa "Ctrl V +".
     (Sin esto Cmd+V en Finder no funciona; el menú del clic derecho sí.)
  2. Automatización: la primera vez que pegues, permite que "Ctrl V +" controle Finder.

Menú del clic derecho: sobre una carpeta o archivo > Acciones rápidas (o Servicios) > Pegar imagen.
Si no aparece: Ajustes del Sistema > Teclado > Atajos de teclado > Servicios > Archivos y carpetas > activa "Pegar imagen".
EOF
