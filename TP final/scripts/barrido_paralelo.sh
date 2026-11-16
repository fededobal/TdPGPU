#!/usr/bin/env bash
# Barrido de parámetros de la versión CUDA en el cluster hexa.
# Compila una vez en el nodo, corre cada combinación de N, pasos e hilos por
# bloque REPETICIONES veces y guarda los tiempos en resultados/paralelo_<fecha>.csv
#
# Uso:  scripts/barrido_paralelo.sh
# Las listas se pueden cambiar sin editar el script:
#       TAMANIOS="512 1024" HILOS="128 256" scripts/barrido_paralelo.sh
# Para correr en un nodo fijo (y comparar con el secuencial en el mismo nodo):
#       NODO=hexa1 scripts/barrido_paralelo.sh
# Para medir otro .cu (por ejemplo, la versión con streams):
#       SRC=Paralelo/difusion_calor_cuda_streams.cu scripts/barrido_paralelo.sh
set -euo pipefail

HOST="hexa"                      # alias de ~/.ssh/config
REMOTO="gpu/tp_final"            # carpeta en el cluster, relativa a tu home
PART="ClusterHexa"               # única partición del cluster nuevo
ARCH="-arch=native"              # compila para la GPU del nodo donde corre srun
CUDA="/netusr/cuda-13.4/bin"     # nvcc no está en el PATH del cluster

TAMANIOS="${TAMANIOS:-512 1024 2048 4096}"  # N: potencias de 2, >= 32
PASOS="${PASOS:-100}"
HILOS="${HILOS:-64 128 256 512 1024}"       # múltiplos de 32, hasta 1024
REPETICIONES="${REPETICIONES:-3}"
NODO="${NODO:-}"                            # vacío: el nodo que asigne slurm

DIR="$(cd "$(dirname "$0")/.." && pwd)"     # carpeta TP final
SRC="${SRC:-$DIR/Paralelo/difusion_calor_cuda.cu}"
NOMBRE="$(basename "$SRC" .cu)"
mkdir -p "$DIR/resultados"
CSV="$DIR/resultados/paralelo_${NOMBRE}_$(date +%Y%m%d_%H%M%S).csv"

ssh "$HOST" "mkdir -p $REMOTO"
scp -q "$SRC" "$HOST:$REMOTO/"

# Script que corre dentro del nodo. Escribe el CSV por stdout (que termina en
# el archivo local) y el progreso por stderr (que se ve en la terminal)
ssh "$HOST" "cat > $REMOTO/barrido_paralelo_nodo.sh" <<'EOF'
set -euo pipefail
TAMANIOS="$1"; PASOS="$2"; HILOS="$3"; REPETICIONES="$4"
CUDA="$5"; ARCH="$6"; NOMBRE="$7"

export PATH="$CUDA:$PATH"
nvcc -O3 $ARCH "$NOMBRE.cu" -o "$NOMBRE" >&2
BIN="$PWD/$NOMBRE"

# Los frames van al disco local del nodo y se borran después de cada corrida:
# son N*N*4*pasos bytes y en el home (NFS) llenarían la cuota
TRABAJO="$(mktemp -d /tmp/difusion.XXXXXX)"
trap 'rm -rf "$TRABAJO"' EXIT
cd "$TRABAJO"

echo "nodo,N,pasos,hilos,rep,t_total_s,t_kernels_s,ms_por_paso,t_d2h_s,t_disco_s,ancho_banda_gbs,t_espera_s"
for N in $TAMANIOS; do
  for P in $PASOS; do
    for H in $HILOS; do
      for R in $(seq 1 "$REPETICIONES"); do
        echo "N=$N pasos=$P hilos=$H rep=$R" >&2
        if salida="$("$BIN" "$N" "$P" "$H")"; then
          echo "$salida" | awk -F': *' -v fila="$(hostname),$N,$P,$H,$R" '
            /^Tiempo total/       { split($2, a, " "); total = a[1] }
            /^Tiempo en kernels/  { split($2, a, " "); kernels = a[1]
                                    por_paso = a[3]; sub(/\(/, "", por_paso) }
            /^Tiempo en copias/   { split($2, a, " "); d2h = a[1] }
            /^Tiempo escribiendo/ { split($2, a, " "); disco = a[1] }
            /^Ancho de banda/     { split($2, a, " "); bw = a[1] }
            /^Tiempo esperando/   { split($2, a, " "); espera = a[1] }
            END { print fila "," total "," kernels "," por_paso "," d2h "," disco "," bw "," espera }'
        else
          echo "  falló: $salida" >&2
        fi
        rm -rf output_frames
      done
    done
  done
done
EOF

ssh "$HOST" "cd $REMOTO && srun -p $PART ${NODO:+-w $NODO} bash barrido_paralelo_nodo.sh \
  '$TAMANIOS' '$PASOS' '$HILOS' '$REPETICIONES' '$CUDA' '$ARCH' '$NOMBRE'" > "$CSV"

echo "Resultados en $CSV"
