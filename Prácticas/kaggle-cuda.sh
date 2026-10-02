#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"   # CLion no hereda el PATH de la terminal

USUARIO="federicodobal"
SLUG="cuda-runner"
SRC="$1"                               # el .cu que le pasa CLion
DIR="$(mktemp -d)"                     # carpeta temporal de trabajo

# 1) Codificar el .cu en base64 para meterlo dentro del script de Python
B64=$(base64 < "$SRC" | tr -d '\n')

# 2) Script que corre en Kaggle: compila, ejecuta y guarda la salida
cat > "$DIR/runner.py" <<EOF
import base64, subprocess
open('prog.cu', 'wb').write(base64.b64decode('$B64'))
with open('/kaggle/working/salida.txt', 'w') as f:
    def run(cmd):
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        f.write(r.stdout + r.stderr)
        return r.returncode
    run('nvidia-smi --query-gpu=name --format=csv,noheader')
    f.write('--- compilacion ---\n')
    if run('nvcc -arch=native prog.cu -o prog') == 0:
        f.write('--- ejecucion ---\n')
        run('./prog')
EOF

# 3) Metadatos: script privado de Python con GPU
cat > "$DIR/kernel-metadata.json" <<EOF
{
  "id": "$USUARIO/$SLUG",
  "title": "$SLUG",
  "code_file": "runner.py",
  "language": "python",
  "kernel_type": "script",
  "is_private": true,
  "enable_gpu": true,
  "enable_internet": false,
  "dataset_sources": [],
  "competition_sources": [],
  "kernel_sources": []
}
EOF

# 4) Subir y esperar a que termine
kaggle kernels push -p "$DIR"
echo "Esperando a Kaggle..."
while true; do
  ESTADO=$(kaggle kernels status "$USUARIO/$SLUG")
  echo "$ESTADO"
  echo "$ESTADO" | grep -qiE 'complete|error|cancel' && break
  sleep 15
done

# 5) Descargar y mostrar la salida
kaggle kernels output "$USUARIO/$SLUG" -p "$DIR/out" > /dev/null
cat "$DIR/out/salida.txt"