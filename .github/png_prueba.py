"""Genera un PNG pequeño (sin dependencias) para las pruebas de CI."""
import struct
import sys
import zlib


def chunk(tipo, datos):
    c = tipo + datos
    return struct.pack(">I", len(datos)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)


ancho, alto = 32, 20
filas = b"".join(b"\x00" + bytes([255, 120, 0, 255]) * ancho for _ in range(alto))
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 6, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(filas))
       + chunk(b"IEND", b""))
with open(sys.argv[1], "wb") as f:
    f.write(png)
