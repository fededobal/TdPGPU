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

__device__ void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

__global__ void ordenar(int *d_V, int N) {
    int id = threadIdx.x;
    __shared__ int s_V[256];
    if(id < N) {
        s_V[id] = d_V[id];
    }
    __syncthreads();
    for (int i = 0; i < N/2; i++) {
        // Iteracion impar
        if(id % 2 != 0 && id < N -1) {
            if (s_V[id] > s_V[id + 1]) {
                swap(&s_V[id], &s_V[id+1]);
            }
        }
        __syncthreads();
        
        // Iteracion par
        if(id % 2 == 0 && id < N -1) {
            if (s_V[id] > s_V[id + 1]) {
                swap(&s_V[id], &s_V[id+1]);
            }
        }
        __syncthreads();
    }
    if (id < N) {
        d_V[id] = s_V[id];
    }
}

int main(int argc, char** argv) {
    int N = 256;
    int tamañoBytes = sizeof(int) * N;
    int h_V[256];

    srand(time(NULL));
    for(int i = 0; i < N; i++) {
        h_V[i] = rand() % N;
    }
    int *d_V;
    cudaMalloc(&d_V, tamañoBytes);
    cudaMemcpy(d_V, h_V, tamañoBytes, cudaMemcpyHostToDevice);

    ordenar<<<1, N>>>(d_V, N);

    cudaDeviceSynchronize();
    HANDLE_ERROR(cudaGetLastError());
    cudaMemcpy(h_V, d_V, tamañoBytes, cudaMemcpyDeviceToHost);

    for(int i = 0; i < N; i++) {
        printf("%d, ", h_V[i]);
    }

    cudaFree(d_V);

    return 0;
}