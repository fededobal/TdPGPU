## I. Introducción a la multiplicación de matrices
Dadas dos matrices $A$ y $B$ de $N \times N$ elementos, la multiplicación $AB$ retorna una matriz resultado $C$ donde cada elemento se calcula como:
$$c_{i,j} = \sum_{k=0}^{N-1} a_{i,k} \cdot b_{k,j}$$
Para calcular la posición $(i,j)$ de la matriz resultante $C$ es necesario procesar la **fila $i$ de A** y la **columna $j$ de B**.
## II. Organización de matrices en memoria
Para mejorar la localidad de caché, las matrices se almacenan en memoria como arreglos ordenados según el patrón de acceso:
- Las matrices **A y C se almacenan por filas**.
- La matriz **B se almacena por columnas**.
Fórmulas de acceso a la posición $(i,j)$ de una matriz $M$ de tamaño $N \times N$:
- Ordenada por filas: `M[i*N + j]`
- Ordenada por columnas: `M[i + j*N]`
## III. Solución en GPU
### Idea general
- A cada **hilo** se le asigna el cálculo de **una celda** de la matriz resultado.
- Cada hilo necesita acceder a la fila $i$ de A y la columna $j$ de B.
- CUDA permite crear **grids y bloques bidimensionales**, que se mapean naturalmente a la estructura 2D de las matrices.
Ejemplo: crear bloques de 2x2 hilos → crear un grid de 2x2 bloques → mapear el grid a la matriz resultado.
### ¿Cómo conoce cada hilo la posición (i,j) que debe calcular?
Usando las **variables built-in** de CUDA (`blockIdx`, `blockDim`, `threadIdx`):
```c
__global__ mm(int *C, int *A, int *B, int N) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    int k;
    for (k = 0; k < N; k++)
        C[i*N + j] += A[i*N + k] * B[k + j*N];
}
```
### Manejo de hilos "de más"
Si la dimensión del grid no es proporcional al tamaño de la matriz (más hilos que posiciones a calcular en C), existen hilos que **no deberían trabajar**. Se agrega un chequeo de límites:
```c
__global__ mm(int *C, int *A, int *B, int N) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    int k;
    if (i < N && j < N) {
        for (k = 0; k < N; k++)
            C[i*N + j] += A[i*N + k] * B[k + j*N];
    }
}
```