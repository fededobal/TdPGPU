# TP final: Difusión de Calor en GPU

Simulación de la difusión de calor (ley de Fourier) en una grilla de N×N, paralelizada con CUDA y comparada contra el algoritmo secuencial de la cátedra.

## Estructura

```
TP final/
├── Secuencial/                Algoritmo secuencial de la cátedra (con medición de tiempos)
├── Paralelo/
│   ├── difusion_calor_cuda.cu           Versión CUDA (memoria compartida + coalescencia)
│   ├── difusion_calor_cuda_streams.cu   Versión con un vector de streams
│   ├── desarrollo/
│   │   └── difusion_calor_cuda_dos_streams.cu   Versión anterior, con dos streams
│   ├── hexa-cuda.sh           Compila y ejecuta un .cu en el cluster hexa
│   └── show_blue2red.py       Visualización de los frames (de la cátedra)
├── scripts/
│   ├── barrido_secuencial.sh  Barrido de parámetros de la versión secuencial
│   ├── barrido_paralelo.sh    Barrido de parámetros de la versión CUDA
│   ├── verificar_streams.sh   Verifica que los frames de la versión con streams sean idénticos
│   └── comparar_frames.py     Compara los frames de dos simulaciones
├── resultados/                CSV de los barridos
├── informe/                   Informe en LaTeX y PDF
└── docs/tp/                   Enunciado y material del problema
```

Cada programa escribe sus frames en `output_frames/`, dentro de la carpeta desde donde se ejecuta.

## Compilar y ejecutar

Secuencial:

```sh
cd Secuencial
gcc -O3 -o main main.c heat_simulation.c
./main 512 100
```

Paralelo:

```sh
cd Paralelo
nvcc -O3 -arch=sm_120 -o difusion_calor_cuda difusion_calor_cuda.cu
./difusion_calor_cuda 512 100 256      # <N> <pasos> <hilos por bloque>
```

En el cluster (desde `TP final`):

```sh
Paralelo/hexa-cuda.sh Paralelo/difusion_calor_cuda_streams.cu 1024 100 256
```

## Visualizar y verificar

Los scripts de Python usan numpy y matplotlib. Se ejecutan desde la carpeta que tiene los frames:

```sh
cd Paralelo
python3 show_blue2red.py
python3 ../scripts/comparar_frames.py ../Secuencial/output_frames output_frames
```

La comparación contra el secuencial solo tiene sentido con N = 512, que es donde la distancia entre fuentes coincide.

## Mediciones

Los barridos corren en el cluster hexa y guardan los tiempos en `resultados/`:

```sh
NODO=hexa1 scripts/barrido_secuencial.sh
NODO=hexa1 scripts/barrido_paralelo.sh
NODO=hexa1 SRC=Paralelo/difusion_calor_cuda_streams.cu scripts/barrido_paralelo.sh
```
