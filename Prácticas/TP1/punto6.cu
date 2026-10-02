#include <cuda.h>
#include <cuda_runtime.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <limits.h>
#include <math.h>

__global__ void promedio(int i, double *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < i) {
        d_V[idx] = (d_V[idx] + d_V[i + idx]) / 2;
    }
}

__global__ void potencias(int N, double *d_V, double promedio) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < N) {
        d_V[idx] = pow(d_V[idx] - promedio, 2);
    }
}

__global__ void sumatoria(int i, double *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < i) {
        d_V[idx] = d_V[idx] + d_V[idx + i];
    }
}

static void HandleError(cudaError_t err, const char *file, int line) {
    if (err != cudaSuccess) {
        printf("%s in %s at line %d\n", cudaGetErrorString( err ), file, line);
        exit(EXIT_FAILURE);
    }
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

double dwalltime(){
        double sec;
        struct timeval tv;

        gettimeofday(&tv,NULL);
        sec = tv.tv_sec + tv.tv_usec/1000000.0;
        return sec;
}

int main(int argc, char** argv) {
    int N = 32;
    int block = 256;
    dim3 dimBlock(block);

    size_t bytes = N * sizeof(double);
    double *h_V = (double *) malloc(bytes);
    srand(time(NULL));

    for (int i = 0; i < N; i++) {
        h_V[i] = rand() % 100;
        printf("%f\n", h_V[i]);
    }

    double *d_VProm = NULL;
    double *d_VPotencias = NULL;
    cudaMalloc((void **) &d_VProm, bytes);
    cudaMemcpy(d_VProm, h_V, bytes, cudaMemcpyHostToDevice);
    cudaMalloc((void **) &d_VPotencias, bytes);
    cudaMemcpy(d_VPotencias, h_V, bytes, cudaMemcpyHostToDevice);

    double ini = dwalltime();
    for(int i = N/2; i > 0; i/=2) {
        dim3 dimGrid((i + dimBlock.x - 1) / dimBlock.x);
        promedio<<<dimGrid, dimBlock>>>(i, d_VProm);
        cudaDeviceSynchronize();
    }
    double promedio;
    cudaMemcpy(&promedio, d_VProm, sizeof(double), cudaMemcpyDeviceToHost);

    dim3 dimGrid((N + dimBlock.x - 1) / dimBlock.x);
    potencias<<<dimGrid, dimBlock>>>(N, d_VPotencias, promedio);

    double *d_VSumatoria;
    cudaMalloc((void **) &d_VSumatoria, bytes);
    cudaMemcpy(d_VSumatoria, d_VPotencias, bytes, cudaMemcpyHostToDevice);
    for(int i = N/2; i > 0; i/=2) {
        dim3 dimGrid((i + dimBlock.x - 1) / dimBlock.x);
        sumatoria<<<dimGrid, dimBlock>>>(i, d_VSumatoria);
        cudaDeviceSynchronize();
    }

    double fin = dwalltime();

    HANDLE_ERROR(cudaPeekAtLastError());
    HANDLE_ERROR(cudaDeviceSynchronize());

    printf("Tiempo de ejecución en segundos: %f seg.\n", fin - ini);

    cudaMemcpy(h_V, d_VSumatoria, sizeof(double), cudaMemcpyDeviceToHost);
    printf("Resultado: %f\n", h_V[0]);

    free(h_V);
    cudaFree(d_VProm);
    cudaFree(d_VPotencias);
    cudaFree(d_VSumatoria);

    return 0;
}