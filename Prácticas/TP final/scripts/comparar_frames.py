"""
Compara los frames de dos simulaciones (por ejemplo: secuencial vs GPU).

Uso:   python3 ../scripts/comparar_frames.py <carpeta_A> <carpeta_B>
Ej.:   (desde Paralelo/) python3 ../scripts/comparar_frames.py ../Secuencial/output_frames output_frames
"""
import glob
import os
import sys

import numpy as np

TOLERANCIA = 1e-3  # la GPU usa FMA: diferencias del orden de 1e-5 son normales


def leer(ruta):
    with open(ruta, "rb") as f:
        n = np.fromfile(f, dtype=np.int32, count=1)[0]
        return np.fromfile(f, dtype=np.float32).reshape((n, n))


if len(sys.argv) != 3:
    print(__doc__)
    sys.exit(1)

carpeta_a, carpeta_b = sys.argv[1], sys.argv[2]
nombres = sorted(os.path.basename(p) for p in glob.glob(os.path.join(carpeta_a, "iter_*.bin")))
if not nombres:
    print(f"No hay frames en {carpeta_a}")
    sys.exit(1)

peor_dif, peor_frame, faltantes = 0.0, None, 0
nan_total, primer_nan = 0, None
for nombre in nombres:
    ruta_b = os.path.join(carpeta_b, nombre)
    if not os.path.exists(ruta_b):
        faltantes += 1
        continue
    a, b = leer(os.path.join(carpeta_a, nombre)), leer(ruta_b)
    if a.shape != b.shape:
        print(f"{nombre}: tamanos distintos {a.shape} vs {b.shape}")
        sys.exit(1)
    # Un NaN no es mayor que nada (NaN > x siempre es falso): hay que contarlos aparte
    nan_frame = int(np.isnan(a).sum() + np.isnan(b).sum())
    if nan_frame > 0:
        nan_total += nan_frame
        primer_nan = primer_nan or nombre
    dif = float(np.nanmax(np.abs(a - b))) if nan_frame < a.size * 2 else 0.0
    if dif > peor_dif:
        peor_dif, peor_frame = dif, nombre

print(f"Frames comparados : {len(nombres) - faltantes} (faltan en B: {faltantes})")
print(f"Diferencia maxima : {peor_dif:g}" + (f" (en {peor_frame})" if peor_frame else ""))
if nan_total > 0:
    print(f"Celdas con NaN    : {nan_total} (la primera en {primer_nan})")
ok = peor_dif <= TOLERANCIA and faltantes == 0 and nan_total == 0
print("RESULTADO: OK" if ok else "RESULTADO: DIFIEREN")
