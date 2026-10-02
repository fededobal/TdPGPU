#include <cuda.h>
#include <cuda_runtime.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <limits.h>
#include <math.h>

__global__ void punto5Max(int i, int *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < i) {
        if(d_V[idx] < d_V[i + idx]) {
            d_V[idx] = d_V[i + idx];
        }
    }
}

__global__ void punto5Min(int i, int *d_V) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < i) {
        if(d_V[idx] > d_V[i + idx]) {
            d_V[idx] = d_V[i + idx];
        }
    }
}

static void HandleError( cudaError_t err, const char *file, int line ) {
    if (err != cudaSuccess) {
        printf( "%s in %s at line %d\n", cudaGetErrorString( err ), file, line );
        exit( EXIT_FAILURE );
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
    int N = 16;
    int block = 256;
    dim3 dimBlock(block);

    size_t bytes = N * sizeof(int);
    int *h_V = (int *) malloc(bytes);
    srand(time(NULL));

    for (int i = 0; i < N; i++) {
        h_V[i] = rand() % 100;
        printf("%d\n", h_V[i]);
    }

    int *d_VMax = NULL;
    int *d_VMin = NULL;
    cudaMalloc((void **) &d_VMax, bytes);
    cudaMemcpy(d_VMax, h_V, bytes, cudaMemcpyHostToDevice);
    cudaMalloc((void **) &d_VMin, bytes);
    cudaMemcpy(d_VMin, h_V, bytes, cudaMemcpyHostToDevice);

    double ini = dwalltime();
    for(int i = N/2; i > 0; i/=2) {
        dim3 dimGrid((i + dimBlock.x - 1) / dimBlock.x);
        punto5Max<<<dimGrid, dimBlock>>>(i, d_VMax);
        cudaDeviceSynchronize();
    }

    for(int i = N/2; i > 0; i/=2) {
        dim3 dimGrid((i + dimBlock.x - 1) / dimBlock.x);
        punto5Min<<<dimGrid, dimBlock>>>(i, d_VMin);
        cudaDeviceSynchronize();
    }
    double fin = dwalltime();

    HANDLE_ERROR(cudaPeekAtLastError());
    HANDLE_ERROR(cudaDeviceSynchronize());

    printf("Tiempo de ejecución en segundos: %f seg.\n", fin - ini);

    cudaMemcpy(h_V, d_VMax, sizeof(int), cudaMemcpyDeviceToHost);
    printf("Elemento máximo: %d\n", h_V[0]);
    cudaMemcpy(h_V, d_VMin, sizeof(int), cudaMemcpyDeviceToHost);
    printf("Elemento mínimo: %d\n", h_V[0]);

    free(h_V);
    cudaFree(d_VMax);
    cudaFree(d_VMin);

    return 0;
}