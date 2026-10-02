#!/usr/bin/env bash
set -euo pipefail

HOST="lidi"                      # alias de ~/.ssh/config
REMOTO="gpu"                     # carpeta en el cluster, relativa a tu home
PART="GPUS"                      # partición con GPU
ARCH="-arch=native"              # CUDA 11.7 lo soporta

SRC="$1"                         # el .cu que le pasa CLion
NOMBRE="$(basename "$SRC" .cu)"  # punto7.cu -> punto7

ssh "$HOST" "mkdir -p $REMOTO"
scp -q "$SRC" "$HOST:$REMOTO/"
ssh "$HOST" "cd $REMOTO && srun -p $PART bash -c 'nvcc $ARCH $NOMBRE.cu -o $NOMBRE && ./$NOMBRE'"