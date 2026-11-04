#!/bin/bash
# Desinstala Ctrl V + de macOS.   Uso:  bash uninstall.sh
set -uo pipefail

for APP in "$HOME/Applications/CtrlVPlus.app" "/Applications/CtrlVPlus.app"; do
    if [ -d "$APP" ]; then
        "$APP/Contents/MacOS/CtrlVPlus" --desregistrar 2>/dev/null || true   # quitar inicio automático
        pkill -x CtrlVPlus 2>/dev/null || true
        rm -rf "$APP" && echo "Eliminado: $APP"
    fi
done
pkill -x CtrlVPlus 2>/dev/null || true
defaults delete io.github.fabian-co.ctrlvplus 2>/dev/null || true
tccutil reset All io.github.fabian-co.ctrlvplus 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true
echo "Ctrl V + se desinstaló."
