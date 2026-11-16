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

  if (hilosXBloque < ANCHO_BLOQUE || hilosXBloque > 1024 || hilosXBloque % ANCHO_BLOQUE != 0) {
    printf("Error: los hilos por bloque deben ser multiplo de %d, entre %d y 1024.\n", ANCHO_BLOQUE, ANCHO_BLOQUE);
    return false;
  }

  return true;
}

__global__ void inicializar_fuentes_de_calor(float *grilla, int N, int distancia) {
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
  bool es_diagonal = (dc == distancia || dc == -distancia) && (df == distancia || df == -distancia);
  return es_centro || es_diagonal;
}

__global__ void difusion(float *d_grilla, float *d_nueva, int N, int distancia) {
  extern __shared__ float tile[];

  int ancho_bloque = blockDim.x;
  int alto_bloque = blockDim.y;
  int col_bloque = threadIdx.x;
  int fila_bloque = threadIdx.y;

  int col = blockIdx.x * ancho_bloque + col_bloque;
  int fila = blockIdx.y * alto_bloque + fila_bloque;
  int idx = fila * N + col;

  int ancho_tile = ancho_bloque + 2;
  int col_tile = col_bloque + 1;
  int fila_tile = fila_bloque + 1;

  bool dentro_grilla = col < N && fila < N;
  bool frontera = col == 0 || col >= N - 1 || fila == 0 || fila >= N - 1;
  if (dentro_grilla) {
    tile[fila_tile * ancho_tile + col_tile] = d_grilla[idx];

    if (fila_bloque == 0 && fila > 0)
      tile[0 * ancho_tile + col_tile] = d_grilla[(fila - 1) * N + col];
    if (fila_bloque == alto_bloque - 1 && fila < N - 1)
      tile[(alto_bloque + 1) * ancho_tile + col_tile] = d_grilla[(fila + 1) * N + col];
    if (col_bloque == 0 && col > 0)
      tile[fila_tile * ancho_tile + 0] = d_grilla[fila * N + (col - 1)];
    if (col_bloque == ancho_bloque - 1 && col < N - 1)
      tile[fila_tile * ancho_tile + (ancho_bloque + 1)] = d_grilla[fila * N + (col + 1)];
  }

  __syncthreads();

  if (!frontera) {
    int int_es_fuente = es_fuente(col, fila, N, distancia);

    float centro = tile[fila_tile * ancho_tile + col_tile];
    float arriba = tile[(fila_tile - 1) * ancho_tile + col_tile];
    float abajo = tile[(fila_tile + 1) * ancho_tile + col_tile];
    float izq = tile[fila_tile * ancho_tile + (col_tile - 1)];
    float der = tile[fila_tile * ancho_tile + (col_tile + 1)];

    float suma_vecinos = arriba + abajo + izq + der;

    d_nueva[idx] = (centro + DIFUSION * (suma_vecinos - 4 * centro)) * !int_es_fuente + TEMP_FUENTE * int_es_fuente;
  }
}

int main(int argc, char *argv[]) {
  if (!validar_parametros(argc, argv)) {
    return 1;
  }

  int N = atoi(argv[1]);
  int pasos = atoi(argv[2]);
  int hilosXBloque = atoi(argv[3]);
  int distancia = N * DISTANCIA_REFERENCIA / N_REFERENCIA; // distancia proporcional entre la fuente de calor central y las demás

  size_t bytes = (size_t)N * N * sizeof(float);
  float *h_grilla = (float *)malloc(bytes); // reserva de memoria para la grilla del host

  float *d_grilla;
  HANDLE_ERROR(cudaMalloc(&d_grilla, bytes)); // reserva de grilla para el paso actual (la lee el kernel)
  float *d_nueva;
  HANDLE_ERROR(cudaMalloc(&d_nueva, bytes)); // reserva de grilla para el paso siguiente (la escribe el kernel)

  cudaEvent_t ev_inicio, ev_fin; // eventos para calcular la duración del kernel principal (difusion) ya que no se puede usar dwalltime porque el lanzamiento en el host es asíncrono
  HANDLE_ERROR(cudaEventCreate(&ev_inicio));
  HANDLE_ERROR(cudaEventCreate(&ev_fin));

  float ms, t_kernels = 0.0f;
  double t, t_d2h = 0.0, t_disco = 0.0;

  mkdir("output_frames", 0777);
  double t_inicio = dwalltime(); // marca temporal de inicio

  HANDLE_ERROR(cudaMemset(d_grilla, 0, bytes));
  HANDLE_ERROR(cudaMemset(d_nueva, 0, bytes)); // inicializo las grillas del device en 0

  inicializar_fuentes_de_calor<<<1, 1>>>( d_grilla, N, distancia); // kernel de un solo hilo para inicializar en 100 las fuentes de calor
  HANDLE_ERROR(cudaPeekAtLastError());
  HANDLE_ERROR(cudaMemcpy(h_grilla, d_grilla, bytes, cudaMemcpyDeviceToHost)); // copia D2H de la grilla inicializada

  t = dwalltime();
  ubicar_fuentes_de_calor(h_grilla, N); // solo para depurar que las fuentes esten bien ubicadas
  double t_depuracion = dwalltime() - t;

  dim3 bloque(ANCHO_BLOQUE, hilosXBloque / ANCHO_BLOQUE); // dimensiones del bloque (32 x hilosXBloque / 32)
  dim3 grid((N + bloque.x - 1) / bloque.x, (N + bloque.y - 1) / bloque.y);
  size_t bytes_compartidos = (bloque.x + 2) * (bloque.y + 2) * sizeof(float); // peso del tile

  for (int paso = 0; paso < pasos; paso++) {
    t = dwalltime();
    guardar_paso(h_grilla, paso, N); // se guarda cada paso en disco (al principio es la grilla con las fuentes de calor en 100)
    t_disco += dwalltime() - t;

    HANDLE_ERROR(cudaEventRecord(ev_inicio));
    difusion<<<grid, bloque, bytes_compartidos>>>(d_grilla, d_nueva, N, distancia); // kernel principal que actualiza la grilla
    HANDLE_ERROR(cudaPeekAtLastError());
    HANDLE_ERROR(cudaEventRecord(ev_fin));
    HANDLE_ERROR(cudaDeviceSynchronize()); // barrera para esperar que el kernel termine
    HANDLE_ERROR(cudaEventElapsedTime(&ms, ev_inicio, ev_fin));
    t_kernels += ms;

    float *aux = d_grilla; // intercambio de punteros
    d_grilla = d_nueva;
    d_nueva = aux; // la grilla nueva pasa a ser la grilla de entrada para el próximo paso

    if (paso + 1 < pasos) { // si no es el último paso...
      t = dwalltime();
      HANDLE_ERROR(cudaMemcpy(h_grilla, d_grilla, bytes, cudaMemcpyDeviceToHost)); // copio al host la grilla recién calculada para guardarla en disco en la próxima vuelta
      t_d2h += dwalltime() - t;
    }
  }

  double t_total = dwalltime() - t_inicio - t_depuracion;

  printf("Tiempo total             : %.4f s\n", t_total);
  printf("Tiempo en kernels        : %.4f s (%.4f ms por paso)\n", t_kernels / 1000.0, t_kernels / pasos);
  printf("Tiempo en copias D2H     : %.4f s\n", t_d2h);
  printf("Tiempo escribiendo disco : %.4f s\n", t_disco);
  printf("Ancho de banda efectivo  : %.1f GB/s\n", 2.0 * bytes * pasos / (t_kernels / 1000.0) / 1e9);

  HANDLE_ERROR(cudaEventDestroy(ev_inicio));
  HANDLE_ERROR(cudaEventDestroy(ev_fin));
  HANDLE_ERROR(cudaFree(d_grilla));
  HANDLE_ERROR(cudaFree(d_nueva));
  free(h_grilla);
  return 0;
}
