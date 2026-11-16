#!/usr/bin/env bash
# Compara byte a byte los frames de una versión con streams contra los de la
# versión de referencia (por defecto, la de dos streams), en el cluster hexa.
# Las dos hacen el mismo cálculo, así que tienen que ser idénticos: cualquier
# diferencia es un error de sincronización
#
# Uso (desde TP final):  scripts/verificar_streams.sh <N> <pasos> <hilos por bloque>
# Para verificar otro .cu:  STREAMS=ruta/al/archivo.cu scripts/verificar_streams.sh 1024 30 256
# Para usar otra referencia:  REFERENCIA=Paralelo/difusion_calor_cuda.cu scripts/verificar_streams.sh 1024 30 256
set -euo pipefail

N="${1:-1024}"
PASOS="${2:-30}"
HILOS="${3:-256}"

HOST="hexa"                      # alias de ~/.ssh/config
REMOTO="gpu"                     # carpeta donde trabaja hexa-cuda.sh

DIR="$(cd "$(dirname "$0")/.." && pwd)"     # carpeta TP final
HEXA="$DIR/Paralelo/hexa-cuda.sh"
REFERENCIA="${REFERENCIA:-$DIR/Paralelo/desarrollo/difusion_calor_cuda_dos_streams.cu}"
STREAMS="${STREAMS:-$DIR/Paralelo/difusion_calor_cuda_streams.cu}"

for archivo in "$REFERENCIA" "$STREAMS"; do
  if [ ! -f "$archivo" ]; then
    echo "No existe el archivo: $archivo"
    exit 1
  fi
done

# Los frames se escriben en el home del cluster: N grande ocupa mucho
echo "== Referencia: $(basename "$REFERENCIA") N=$N pasos=$PASOS hilos=$HILOS"
ssh "$HOST" "rm -rf $REMOTO/output_frames $REMOTO/frames_referencia"
"$HEXA" "$REFERENCIA" "$N" "$PASOS" "$HILOS" > /dev/null
ssh "$HOST" "mv $REMOTO/output_frames $REMOTO/frames_referencia"

echo "== Versión a verificar: $(basename "$STREAMS")"
"$HEXA" "$STREAMS" "$N" "$PASOS" "$HILOS"

if ssh "$HOST" "cd $REMOTO && diff -rq frames_referencia output_frames"; then
  echo "Frames idénticos ($PASOS archivos)"
  ssh "$HOST" "rm -rf $REMOTO/output_frames $REMOTO/frames_referencia"
else
  echo "Hay frames distintos. Quedaron en el cluster para revisarlos:"
  echo "  ~/$REMOTO/frames_referencia y ~/$REMOTO/output_frames"
  exit 1
fi
