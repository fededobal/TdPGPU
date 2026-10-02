#include <cuda.h>
#include <cuda_runtime.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <limits.h>
#include <math.h>

static void HandleError(cudaError_t err, const char *file, int line) {
    if (err != cudaSuccess) {
        printf("%s in %s at line %d\n", cudaGetErrorString( err ), file, line);
        exit(EXIT_FAILURE);
    }
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

__global__ void verificar(int N, int X, int *d_V, int *d_Ocurrencias) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < N) {
        d_Ocurrencias[idx] += (d_V[idx] == X) ? 1 : 0;
    }
}

__global__ void sumar(int n, int mitad, int *d_Ocurrencias) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < n - mitad) {
        d_Ocurrencias[idx] += d_Ocurrencias[idx + mitad];
    }
}

int main(int argc, char** argv) {
    int N = 16;
    int block = 256;

    dim3 dimBlock(block);

    int tam = N * sizeof(int);

    int *h_V = (int *) malloc(tam);
    for(int i = 0; i < N; i++) {
        h_V[i] = (i % 3) + 1; // 1, 2, 3, 1, 2, 3, 1, 2, 3, ...
    }
    int *h_Ocurrencias = (int *) malloc(tam);
    for(int i = 0; i < N; i++) {
        h_Ocurrencias[i] = 0;
    }

    int *d_V;
    cudaMalloc((void **) &d_V, tam);
    cudaMemcpy(d_V, h_V, tam, cudaMemcpyHostToDevice);
    int *d_Ocurrencias;
    cudaMalloc((void **) &d_Ocurrencias, tam);
    cudaMemcpy(d_Ocurrencias, h_Ocurrencias, tam, cudaMemcpyHostToDevice);

    int X = 2;
    dim3 dimGrid((N + dimBlock.x - 1) / dimBlock.x);
    verificar<<<dimGrid, dimBlock>>>(N, X, d_V, d_Ocurrencias);

    int n = N;
    while(n > 1) {
        int mitad = (n + 1) / 2;
        int hilos = n - mitad;
        dim3 gridSuma((hilos + dimBlock.x - 1) / dimBlock.x);
        sumar<<<gridSuma, dimBlock>>>(n, mitad, d_Ocurrencias);
        HANDLE_ERROR(cudaGetLastError());
        n = mitad;
    }

    cudaMemcpy(h_Ocurrencias, d_Ocurrencias, sizeof(int), cudaMemcpyDeviceToHost);
    printf("%d", h_Ocurrencias[0]);

    free(h_V);
    free(h_Ocurrencias);
    cudaFree(d_V);
    cudaFree(d_Ocurrencias);

    return 0;
}