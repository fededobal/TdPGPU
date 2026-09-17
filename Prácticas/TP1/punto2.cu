#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

__global__ void punto2(int *d_C, int *d_A, int *d_B, int d_N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < d_N) {
        d_C[idx] = d_A[idx] + d_B[idx];
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
    int h_N = 10;

    int threadsXBloque = 256;
    int bloques = (h_N + threadsXBloque - 1) / threadsXBloque;

    size_t bytes = h_N * sizeof(int);
    int *h_C = (int *) malloc(bytes);
    int *h_A = (int *) malloc(bytes);
    int *h_B = (int *) malloc(bytes);
    for (int i = 0; i < h_N; i++) {
        h_C[i] = 0;
        h_A[i] = i;
        h_B[i] = i;
    }

    int *d_C = NULL;
    int *d_A = NULL;
    int *d_B = NULL;

    cudaMalloc((void **) &d_C, bytes);
    cudaMemcpy(d_C, h_C, bytes, cudaMemcpyHostToDevice);
    cudaMalloc((void **) &d_A, bytes);
    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMalloc((void **) &d_B, bytes);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);

    double ini = dwalltime();
    punto2<<<bloques, threadsXBloque>>>(d_C, d_A, d_B, h_N);
    cudaDeviceSynchronize();
    double fin = dwalltime();

    cudaMemcpy(h_A, d_A, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_B, d_B, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost);

    printf("%f\n", fin - ini);
    for (int i = 0; i < h_N; i++) {
        printf("C: %d\n", h_C[i]);
        printf("A: %d\n", h_A[i]);
        printf("B: %d\n", h_B[i]);
        printf("");
    }

    free(h_A);
    cudaFree(d_A);
    free(h_B);
    cudaFree(d_B);
    free(h_C);
    cudaFree(d_C);

    return 0;
}