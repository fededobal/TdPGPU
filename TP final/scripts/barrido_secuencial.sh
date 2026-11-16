#!/usr/bin/env bash
# Barrido de parámetros de la versión secuencial en el cluster hexa.
# Compila una vez en el nodo, corre cada combinación de N y pasos REPETICIONES
# veces y guarda los tiempos en resultados/secuencial_<fecha>.csv
#
# Los tiempos los mide el propio programa, con el mismo criterio que la
# versión CUDA (desde la inicialización de la grilla hasta el final del bucle)
#
# Uso:  scripts/barrido_secuencial.sh
# Las listas se pueden cambiar sin editar el script:
#       TAMANIOS="512 1024" PASOS="100 200" scripts/barrido_secuencial.sh
# Para correr en un nodo fijo (y comparar con el paralelo en el mismo nodo):
#       NODO=hexa1 scripts/barrido_secuencial.sh
set -euo pipefail

HOST="hexa"                      # alias de ~/.ssh/config
REMOTO="gpu/tp_final"            # carpeta en el cluster, relativa a tu home
PART="ClusterHexa"               # única partición del cluster nuevo

TAMANIOS="${TAMANIOS:-512 1024 2048 4096}"  # N >= 42 (fuentes a distancia 20 del centro)
PASOS="${PASOS:-100}"
REPETICIONES="${REPETICIONES:-3}"
NODO="${NODO:-}"                            # vacío: el nodo que asigne slurm

DIR="$(cd "$(dirname "$0")/.." && pwd)"     # carpeta TP final
SEC="$DIR/Secuencial"
NOMBRE="difusion_secuencial"
mkdir -p "$DIR/resultados"
CSV="$DIR/resultados/secuencial_$(date +%Y%m%d_%H%M%S).csv"

ssh "$HOST" "mkdir -p $REMOTO/secuencial"
scp -q "$SEC/main.c" "$SEC/heat_simulation.c" "$SEC/heat_simulation.h" \
  "$HOST:$REMOTO/secuencial/"

# Script que corre dentro del nodo. Escribe el CSV por stdout (que termina en
# el archivo local) y el progreso por stderr (que se ve en la terminal)
ssh "$HOST" "cat > $REMOTO/secuencial/barrido_secuencial_nodo.sh" <<'EOF'
set -euo pipefail
TAMANIOS="$1"; PASOS="$2"; REPETICIONES="$3"; NOMBRE="$4"

gcc -O3 main.c heat_simulation.c -o "$NOMBRE" >&2
BIN="$PWD/$NOMBRE"

# Los frames van al disco local del nodo y se borran después de cada corrida:
# son N*N*4*pasos bytes y en el home (NFS) llenarían la cuota
TRABAJO="$(mktemp -d /tmp/difusion.XXXXXX)"
trap 'rm -rf "$TRABAJO"' EXIT
cd "$TRABAJO"

echo "nodo,N,pasos,rep,t_total_s,t_calculo_s,ms_por_paso,t_disco_s"
for N in $TAMANIOS; do
  for P in $PASOS; do
    for R in $(seq 1 "$REPETICIONES"); do
      echo "N=$N pasos=$P rep=$R" >&2
      if salida="$("$BIN" "$N" "$P")"; then
        echo "$salida" | awk -F': *' -v fila="$(hostname),$N,$P,$R" '
          /^Tiempo total/       { split($2, a, " "); total = a[1] }
          /^Tiempo de calculo/  { split($2, a, " "); calculo = a[1]
                                  por_paso = a[3]; sub(/\(/, "", por_paso) }
          /^Tiempo escribiendo/ { split($2, a, " "); disco = a[1] }
          END { print fila "," total "," calculo "," por_paso "," disco }'
      else
        echo "  falló: $salida" >&2
      fi
      rm -rf output_frames
    done
  done
done
EOF

ssh "$HOST" "cd $REMOTO/secuencial && srun -p $PART ${NODO:+-w $NODO} bash barrido_secuencial_nodo.sh \
  '$TAMANIOS' '$PASOS' '$REPETICIONES' '$NOMBRE'" > "$CSV"

echo "Resultados en $CSV"
