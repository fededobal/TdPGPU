#include <cuda_runtime.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>

#define N_REFERENCIA 512
#define DISTANCIA_REFERENCIA 20
#define TEMP_FUENTE 100.0f
#define DIFUSION 0.25f
#define ANCHO_BLOQUE 32
#define STREAMS 5

bool validar_parametros(int argc, char *argv[]) {
  if (argc < 4) {
    printf("Se necesitan al menos 3 parámetros:\n");
    printf("    programa <N> <Pasos de simulación> <hilos por bloque>\n");
    return false;
  }

  int N = atoi(argv[1]);
  int pasos = atoi(argv[2]);
  int hilosXBloque = atoi(argv[3]);

  if (!(N > 0 && (N & (N - 1)) == 0)) {
    printf("Error: N debe ser potencia de 2.\n");
    return false;
  }

  if (N < 32) {
    printf("Error: N debe ser mayor o igual a 32.\n");
    return false;
  }

  if (pasos < 1) {
    printf("Error: se requiere al menos 1 paso.\n");
    return false;
  }

  if (hilosXBloque < ANCHO_BLOQUE || hilosXBloque > 1024 ||
      hilosXBloque % ANCHO_BLOQUE != 0) {
    printf("Error: los hilos por bloque deben ser multiplo de %d, entre %d y "
           "1024.\n",
           ANCHO_BLOQUE, ANCHO_BLOQUE);
    return false;
  }

  return true;
}

__global__ void inicializar_fuentes_de_calor(float *grilla, int N,
                                             int distancia) {
  int centroX = N / 2;
  int centroY = N / 2;

  grilla[centroY * N + centroX] = TEMP_FUENTE;
  grilla[(centroY + distancia) * N + (centroX + distancia)] = TEMP_FUENTE;
  grilla[(centroY - distancia) * N + (centroX + distancia)] = TEMP_FUENTE;
  grilla[(centroY + distancia) * N + (centroX - distancia)] = TEMP_FUENTE;
  grilla[(centroY - distancia) * N + (centroX - distancia)] = TEMP_FUENTE;
}

void ubicar_fuentes_de_calor(const float *grilla, int N) {
  printf("Ubicación de las fuentes de calor en la grilla:\n");
  for (int i = 0; i < N * N; i++) {
    if (grilla[i] == 100)
      printf("(%d,%d)\n", i % N, i / N);
  }
}

void guardar_paso(const float *grilla, int paso, int N) {
  char nombre[128];
  snprintf(nombre, sizeof(nombre), "output_frames/iter_%04d.bin", paso);

  FILE *f = fopen(nombre, "wb");
  if (f == NULL) {
    printf("Error al abrir el archivo %s para escritura.\n", nombre);
    return;
  }
  fwrite(&N, sizeof(int), 1, f);
  fwrite(grilla, sizeof(float), (size_t)N * N, f);
  fclose(f);
}

double dwalltime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + tv.tv_usec / 1000000.0;
}

#define HANDLE_ERROR(err) (HandleError(err, __FILE__, __LINE__))
static void HandleError(cudaError_t err, const char *file, int line) {
  if (err != cudaSuccess) {
    printf("%s in %s at line %d\n", cudaGetErrorString(err), file, line);
    exit(EXIT_FAILURE);
  }
}

__device__ bool es_fuente(int col, int fila, int N, int distancia) {
  int dc = col - N / 2;
  int df = fila - N / 2;

  bool es_centro = dc == 0 && df == 0;
  bool es_diagonal = (dc == distancia || dc == -distancia) &&
                     (df == distancia || df == -distancia);
  return es_centro || es_diagonal;
}

__global__ void difusion(float *d_grilla, float *d_nueva, int N,
                         int distancia, int fila_inicio, int fila_fin) {
  extern __shared__ float tile[];

  int ancho_bloque = blockDim.x;
  int alto_bloque = blockDim.y;
  int col_bloque = threadIdx.x;
  int fila_bloque = threadIdx.y;

  int col = blockIdx.x * ancho_bloque + col_bloque;
  int fila_banda = blockIdx.y * alto_bloque + fila_bloque;
  int fila = fila_inicio + fila_banda;
  int idx = fila_banda * N + col;

  int ancho_tile = ancho_bloque + 2;
  int col_tile = col_bloque + 1;
  int fila_tile = fila_bloque + 1;

  bool dentro_grilla = col < N && fila < N;
  bool frontera = col == 0 || col >= N - 1 || fila == 0 || fila >= N - 1;
  if (dentro_grilla) {
    tile[fila_tile * ancho_tile + col_tile] = d_grilla[idx];

    if (fila_bloque == 0 && fila > 0)
      tile[0 * ancho_tile + col_tile] = d_grilla[idx - N];
    if (fila_bloque == alto_bloque - 1 && fila < N - 1)
      tile[(alto_bloque + 1) * ancho_tile + col_tile] = d_grilla[idx + N];
    if (col_bloque == 0 && col > 0)
      tile[fila_tile * ancho_tile + 0] = d_grilla[idx - 1];
    if (col_bloque == ancho_bloque - 1 && col < N - 1)
      tile[fila_tile * ancho_tile + (ancho_bloque + 1)] = d_grilla[idx + 1];
  }

  __syncthreads();

  if (!frontera && fila < fila_fin) {
    int int_es_fuente = es_fuente(col, fila, N, distancia);

    float centro = tile[fila_tile * ancho_tile + col_tile];
    float arriba = tile[(fila_tile - 1) * ancho_tile + col_tile];
    float abajo = tile[(fila_tile + 1) * ancho_tile + col_tile];
    float izq = tile[fila_tile * ancho_tile + (col_tile - 1)];
    float der = tile[fila_tile * ancho_tile + (col_tile + 1)];

    float suma_vecinos = arriba + abajo + izq + der;

    d_nueva[idx] =
        (centro + DIFUSION * (suma_vecinos - 4 * centro)) * !int_es_fuente +
        TEMP_FUENTE * int_es_fuente;
  }
}

int main(int argc, char *argv[]) {
  if (!validar_parametros(argc, argv)) {
    return 1;
  }

  int N = atoi(argv[1]);
  int pasos = atoi(argv[2]);
  int hilosXBloque = atoi(argv[3]);
  int distancia = N * DISTANCIA_REFERENCIA / N_REFERENCIA;

  size_t bytes = (size_t)N * N * sizeof(float);
  float *h_grilla[2];
  HANDLE_ERROR(cudaMallocHost(&h_grilla[0], bytes));
  HANDLE_ERROR(cudaMallocHost(&h_grilla[1], bytes));

  float *d_grilla[2];
  HANDLE_ERROR(cudaMalloc(&d_grilla[0], bytes));
  HANDLE_ERROR(cudaMalloc(&d_grilla[1], bytes));

  cudaStream_t streams[STREAMS];
  cudaEvent_t ev_inicio_kernel[STREAMS], ev_fin_kernel[STREAMS],
      ev_fin_copia[STREAMS];
  for (int i = 0; i < STREAMS; i++) {
    HANDLE_ERROR(cudaStreamCreate(&streams[i]));
    HANDLE_ERROR(cudaEventCreate(&ev_inicio_kernel[i]));
    HANDLE_ERROR(cudaEventCreate(&ev_fin_kernel[i]));
    HANDLE_ERROR(cudaEventCreate(&ev_fin_copia[i]));
  }

  float ms, t_kernels = 0.0f;
  double t, t_d2h = 0.0, t_disco = 0.0, t_espera = 0.0;

  mkdir("output_frames", 0777);
  double t_inicio = dwalltime();

  HANDLE_ERROR(cudaMemset(d_grilla[0], 0, bytes));
  HANDLE_ERROR(cudaMemset(d_grilla[1], 0, bytes));

  inicializar_fuentes_de_calor<<<1, 1>>>(d_grilla[0], N, distancia);
  HANDLE_ERROR(cudaPeekAtLastError());
  HANDLE_ERROR(
      cudaMemcpy(h_grilla[0], d_grilla[0], bytes, cudaMemcpyDeviceToHost));

  t = dwalltime();
  ubicar_fuentes_de_calor(h_grilla[0], N);
  double t_depuracion = dwalltime() - t;

  dim3 bloque(ANCHO_BLOQUE, hilosXBloque / ANCHO_BLOQUE);
  dim3 grid((N + bloque.x - 1) / bloque.x, (N + bloque.y - 1) / bloque.y);
  size_t bytes_compartidos = (bloque.x + 2) * (bloque.y + 2) * sizeof(float);

  for (int paso = 0; paso < pasos; paso++) {
    int actual = paso % 2;
    int siguiente = (paso + 1) % 2;
    bool hay_siguiente = paso + 1 < pasos;

    if (hay_siguiente) {
      for (int i = 0; i < STREAMS; i++) {
        int fila_inicio = i * N / STREAMS;
        int fila_fin = (i + 1) * N / STREAMS;
        size_t offset = (size_t)fila_inicio * N;
        size_t bytes_banda = (size_t)(fila_fin - fila_inicio) * N * sizeof(float);
        dim3 grid_banda(grid.x, (fila_fin - fila_inicio + bloque.y - 1) / bloque.y);

        HANDLE_ERROR(cudaEventRecord(ev_inicio_kernel[i], streams[i]));
        difusion<<<grid_banda, bloque, bytes_compartidos, streams[i]>>>(
            &d_grilla[actual][offset], &d_grilla[siguiente][offset], N,
            distancia, fila_inicio, fila_fin);
        HANDLE_ERROR(cudaPeekAtLastError());
        HANDLE_ERROR(cudaEventRecord(ev_fin_kernel[i], streams[i]));
        HANDLE_ERROR(cudaMemcpyAsync(&h_grilla[siguiente][offset], &d_grilla[siguiente][offset], bytes_banda,
                                     cudaMemcpyDeviceToHost, streams[i]));
        HANDLE_ERROR(cudaEventRecord(ev_fin_copia[i], streams[i]));
      }
    }

    t = dwalltime();
    guardar_paso(h_grilla[actual], paso, N);
    t_disco += dwalltime() - t;

    t = dwalltime();
    HANDLE_ERROR(cudaDeviceSynchronize());
    t_espera += dwalltime() - t;

    if (hay_siguiente) {
      for (int i = 0; i < STREAMS; i++) {
        HANDLE_ERROR(cudaEventElapsedTime(&ms, ev_inicio_kernel[i], ev_fin_kernel[i]));
        t_kernels += ms;
        HANDLE_ERROR(cudaEventElapsedTime(&ms, ev_fin_kernel[i], ev_fin_copia[i]));
        t_d2h += ms / 1000.0;
      }
    }
  }

  double t_total = dwalltime() - t_inicio - t_depuracion;
  int pasos_calculados = pasos > 1 ? pasos - 1 : 1;

  printf("Tiempo total             : %.4f s\n", t_total);
  printf("Tiempo en kernels        : %.4f s (%.4f ms por paso)\n",
         t_kernels / 1000.0, t_kernels / pasos_calculados);
  printf("Tiempo en copias D2H     : %.4f s\n", t_d2h);
  printf("Tiempo escribiendo disco : %.4f s\n", t_disco);
  printf("Tiempo esperando GPU     : %.4f s\n", t_espera);
  printf("Ancho de banda efectivo  : %.1f GB/s\n",
         2.0 * bytes * pasos_calculados / (t_kernels / 1000.0) / 1e9);

  for (int i = 0; i < STREAMS; i++) {
    HANDLE_ERROR(cudaStreamDestroy(streams[i]));
    HANDLE_ERROR(cudaEventDestroy(ev_inicio_kernel[i]));
    HANDLE_ERROR(cudaEventDestroy(ev_fin_kernel[i]));
    HANDLE_ERROR(cudaEventDestroy(ev_fin_copia[i]));
  }
  for (int i = 0; i < 2; i++) {
    HANDLE_ERROR(cudaFree(d_grilla[i]));
    HANDLE_ERROR(cudaFreeHost(h_grilla[i]));
  }
  return 0;
}