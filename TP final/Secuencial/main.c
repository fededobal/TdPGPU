#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/time.h>
#include "heat_simulation.h"

double dwalltime() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

int main(int argc, char* argv[]) {
	
	if (argc < 3) {
        printf("Uso correcto: %s <Tamano de Grilla N> <Total de Pasos>\n", argv[0]);
        printf("Ejemplo: %s 512 200\n", argv[0]);
        return 1;
    }

    int N = atoi(argv[1]);
    int TOTAL_STEPS = atoi(argv[2]);	
	
    // Crear directorio de salida (Compatible con Linux y Windows)
    #ifdef _WIN32
        system("mkdir output_frames 2> nul");
    #else
        system("mkdir -p output_frames");
    #endif

    printf("Generando %d iteraciones de la simulacion...\n", TOTAL_STEPS);

    // Acumuladores en segundos, medidos con el mismo criterio que la versión CUDA
    double t, t_calculo = 0.0, t_disco = 0.0, t_depuracion = 0.0;

    // A partir de acá se mide el tiempo total
    double t_inicio = dwalltime();

    // Inicializar grilla
    initialize_grid(N);

    for (int step = 0; step < TOTAL_STEPS; step++) {
        // Guarda el estado actual en un archivo binario
        t = dwalltime();
        char filename[128]; // Nombre de archivo, 128 caracteres
        sprintf(filename, "output_frames/iter_%04d.bin", step);

        FILE *f = fopen(filename, "wb");
        if (f) {
            // Guarda primero el tamaño N y luego los datos de la grilla
            fwrite(&grid_size, sizeof(int), 1, f);
            fwrite(grid, sizeof(float), grid_size * grid_size, f);
            fclose(f);
        } else {
            printf("Error al abrir el archivo %s para escritura.\n", filename); // Por las dudas del espacio en disco
        }
        t_disco += dwalltime() - t;

        // Actualiza la simulación para el siguiente paso
        t = dwalltime();
        update_simulation();
        t_calculo += dwalltime() - t;

		// Muestra en pantalla cada 10 iteraciones
        // La impresión de progreso no se cuenta en el tiempo total
        if (step % 10 == 0) {
            t = dwalltime();
            printf("Procesado paso %d/%d\n", step, TOTAL_STEPS);
            t_depuracion += dwalltime() - t;
        }
    }

    double t_total = dwalltime() - t_inicio - t_depuracion;

    printf("Tiempo total             : %.4f s\n", t_total);
    printf("Tiempo de calculo        : %.4f s (%.4f ms por paso)\n",
           t_calculo, t_calculo * 1000.0 / TOTAL_STEPS);
    printf("Tiempo escribiendo disco : %.4f s\n", t_disco);

    destroy__grid();

    return 0;
}
