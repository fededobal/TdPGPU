%%writefile punto1b.cu
#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

__constant__ int d_N;
__constant__ int d_C;

__global__ void punto1b(int *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < d_N) {
        d_V[idx] = d_V[idx] * d_C;
    }
}

double dwalltime(){
        double sec;
        struct timeval tv;

        gettimeofday(&tv,NULL);
        sec = tv.tv_sec + tv.tv_usec/1000000.0;
        return sec;
}

int main(int argc, char** argv) {
    int h_N = 1000000000;
    int h_C = 10;

    int threadsXBloque = 256;
    int bloques = (h_N + threadsXBloque - 1) / threadsXBloque;

    size_t bytes = h_N * sizeof(int);
    int *h_V = (int *) malloc(bytes);
    for (int i = 0; i < h_N; i++) {
        h_V[i] = i;
    }

    int *d_V = NULL;
    cudaMalloc((void **) &d_V, bytes);
    cudaMemcpy(d_V, h_V, bytes, cudaMemcpyHostToDevice);

    cudaMemcpyToSymbol(d_N, &h_N, sizeof(int));
    cudaMemcpyToSymbol(d_C, &h_C, sizeof(int));

    double ini = dwalltime();
    punto1b<<<bloques, threadsXBloque>>>(d_V);
    cudaDeviceSynchronize();
    double fin = dwalltime();

    cudaMemcpy(h_V, d_V, bytes, cudaMemcpyDeviceToHost);

    printf("%f", fin - ini);

    free(h_V);
    cudaFree(d_V);

    return 0;
}