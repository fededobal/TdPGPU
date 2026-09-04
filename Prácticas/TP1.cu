#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>

__global__ void punto1a(int C, int N, int *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < N) {
        d_V[idx] = d_V[idx] * C;
    }
}

int main(int argc, char** argv) {
    int N = 50;
    int threadsXBloque = 256;
    int bloques = (N + threadsXBloque - 1) / threadsXBloque;

    size_t bytes = N * sizeof(int);
    int *h_V = (int *) malloc(bytes);
    for (int i = 0; i < N; i++) {
        h_V[i] = i;
    }

    int *d_V = NULL;
    cudaMalloc((void **) &d_V, bytes);
    cudaMemcpy(d_V, h_V, bytes, cudaMemcpyHostToDevice);

    for (int i = 0; i < N; i++) {
        printf("%d ", h_V[i]);
    }
    printf("\n");

    punto1a<<<bloques, threadsXBloque>>>(10, N, d_V);

    cudaMemcpy(h_V, d_V, bytes, cudaMemcpyDeviceToHost);

    for (int i = 0; i < N; i++) {
        printf("%d ", h_V[i]);
    }
    printf("\n");
}
