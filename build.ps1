# Compila Ctrl V + y su instalador.
# Requiere AutoHotkey v2 y Ahk2Exe (https://github.com/AutoHotkey/Ahk2Exe).
# Uso:  powershell -ExecutionPolicy Bypass -File build.ps1
param(
    [string]$AhkDir = "$env:LOCALAPPDATA\Programs\AutoHotkey"
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src  = Join-Path $root 'fuente'
$out  = Join-Path $root 'dist'

$base = Join-Path $AhkDir 'v2\AutoHotkey64.exe'
$comp = Join-Path $AhkDir 'Compiler\Ahk2Exe.exe'
if (-not (Test-Path $base)) { $base = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe" }
if (-not (Test-Path $comp)) { $comp = "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe" }
foreach ($p in $base, $comp) { if (-not (Test-Path $p)) { throw "No se encontró: $p" } }

New-Item -ItemType Directory -Force $out | Out-Null

function Compilar($in, $exe) {
    $p = Start-Process $comp -ArgumentList "/in `"$in`" /out `"$exe`" /base `"$base`" /silent" -NoNewWindow -PassThru
    $p.WaitForExit()
    if (-not (Test-Path $exe)) { throw "Falló la compilación de $in" }
}

# 1) Programa (el instalador lo incrusta con FileInstall desde la carpeta fuente)
Compilar (Join-Path $src 'CtrlVPlus.ahk') (Join-Path $src 'CtrlVPlus.exe')
# 2) Instalador
Compilar (Join-Path $src 'Instalador.ahk') (Join-Path $out 'Instalar Ctrl V +.exe')

Write-Host "Listo: $out\Instalar Ctrl V +.exe"
