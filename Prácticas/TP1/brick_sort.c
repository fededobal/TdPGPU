#include "utils.h"

/* <----------- Brick Sort (odd-even transposition sort) -----------> */
void brick_sort(int *arr, const int n) {
    if (n <= 1 || arr == NULL) return;
    // El algoritmo asegura que luego de n iteraciones
    // (n/2 pares y n/2 impares), el arreglo estará ordenado
    for (int i = 0; i < (n+1)/2; i++) {
        char esta_ordenado = 1;
        // Iteracion impar
        for (int j = 0; j < n/2; j++) {
            if (arr[2*j] > arr[2*j+1]) {
                swap(&arr[2*j], &arr[2*j+1]);
                esta_ordenado = 0;
            }
        }
        // Iteracion par
        for (int j = 0; j < (n-1)/2; j++) {
            if (arr[2*j+1] > arr[2*j+2]) {
                swap(&arr[2*j+1], &arr[2*j+2]);
                esta_ordenado = 0;
            }
        }
        if (esta_ordenado == 1)
            break;
    }
}

int main() {
    const int size = 50;
    int *v = malloc(size * sizeof(int));
    for(int i = 0; i < size; i++) {
        v[i] = i % 3 + 1;
    }
    for(int i = 0; i < size; i++) {
        printf("%d-", v[i]);
    }
    printf("\n");

    brick_sort(v, size);

    for(int i = 0; i < size; i++) {
        printf("%d-", v[i]);
    }
    return 0;
}