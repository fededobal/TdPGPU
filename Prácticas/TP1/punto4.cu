%%writefile punto4.cu
#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>

__global__ void punto4(int *d_C, int *d_A, int *d_B, int d_N) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < d_N && j < d_N) {
        int suma = 0;
        for(int k = 0; k < d_N; k++) {
            suma += d_A[i * d_N + k] * d_B[k * d_N + j];
        }
        d_C[i * d_N + j] = suma;
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

    dim3 bloque(16, 16);
    dim3 grid((h_N + bloque.x - 1) / bloque.x, (h_N + bloque.y - 1) / bloque.y);

    size_t bytes = h_N * h_N * sizeof(int);
    int *h_C = (int *) malloc(bytes);
    int *h_A = (int *) malloc(bytes);
    int *h_B = (int *) malloc(bytes);

    srand(time(NULL));
    for (int i = 0; i < h_N; i++) {
        for(int j = 0; j < h_N; j++) {
            h_C[i * h_N + j] = 0;
            h_A[i * h_N + j] = rand() % 10000;
            h_B[i * h_N + j] = rand() % 10000;
        }
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
    punto4<<<grid, bloque>>>(d_C, d_A, d_B, h_N);
    cudaDeviceSynchronize();
    double fin = dwalltime();

    cudaMemcpy(h_A, d_A, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_B, d_B, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost);

    printf("%f\n", fin - ini);
    for (int i = 0; i < h_N; i++) {
        for(int j = 0; j < h_N; j++) {        
            printf("C: %d\n", h_C[i * h_N + j]);
            printf("A: %d\n", h_A[i * h_N + j]);
            printf("B: %d\n", h_B[i * h_N + j]);
            printf("\n");
        }
    }

    free(h_A);
    cudaFree(d_A);
    free(h_B);
    cudaFree(d_B);
    free(h_C);
    cudaFree(d_C);

    return 0;
}