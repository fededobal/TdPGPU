#!/usr/bin/env bash
set -euo pipefail

HOST="hexa"                      # alias de ~/.ssh/config
REMOTO="gpu"                     # carpeta en el cluster, relativa a tu home
PART="ClusterHexa"               # única partición del cluster nuevo
ARCH="-arch=native"              # compila para la GPU del nodo donde corre srun
CUDA="/netusr/cuda-13.4/bin"     # nvcc no está en el PATH del cluster

SRC="$1"                         # el .cu a compilar
NOMBRE="$(basename "$SRC" .cu)"  # difusion_calor_yo.cu -> difusion_calor_yo
shift
ARGS="$*"                        # parámetros del programa, ej: 512 100 256

ssh "$HOST" "mkdir -p $REMOTO"
scp -q "$SRC" "$HOST:$REMOTO/"
ssh "$HOST" "cd $REMOTO && srun -p $PART bash -c 'export PATH=$CUDA:\$PATH && nvcc -O3 $ARCH $NOMBRE.cu -o $NOMBRE && ./$NOMBRE $ARGS'"
