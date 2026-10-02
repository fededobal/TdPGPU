#ifndef UTILS_H
#define UTILS_H

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

/* Intercambia el contenido de dos enteros */
static inline void swap(int *a, int *b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

/* Tiempo de reloj en segundos. Se usa restando dos lecturas:
   double t = dwalltime(); ...; printf("%f\n", dwalltime() - t); */
static inline double dwalltime(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double) tv.tv_sec + (double) tv.tv_usec / 1000000.0;
}

/* Imprime los n primeros elementos del arreglo, separados por '-' */
static inline void imprimir_arreglo(const int *v, const int n) {
    for (int i = 0; i < n; i++) {
        printf("%d%s", v[i], i + 1 < n ? "-" : "\n");
    }
}

/* Devuelve 1 si el arreglo esta ordenado de menor a mayor */
static inline int esta_ordenado(const int *v, const int n) {
    for (int i = 1; i < n; i++) {
        if (v[i - 1] > v[i]) return 0;
    }
    return 1;
}

#endif /* UTILS_H */
