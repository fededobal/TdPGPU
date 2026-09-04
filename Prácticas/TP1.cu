%%writefile TP1.cu
#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

__global__ void punto1a(int C, int N, int *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < N) {
        d_V[idx] = d_V[idx] * C;
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
    int N = 1000000000;
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

    double ini = dwalltime();
    punto1a<<<bloques, threadsXBloque>>>(10, N, d_V);
    cudaDeviceSynchronize();
    double fin = dwalltime();

    cudaMemcpy(h_V, d_V, bytes, cudaMemcpyDeviceToHost);

    printf("%f", fin - ini);
}