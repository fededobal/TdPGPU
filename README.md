# TdPGPU

Apuntes, teorías y prácticas de la materia **Taller de Programación en GPU** (UNLP).

## Teorías

Diapositivas de la cátedra y, cuando los hay, mis apuntes de cada clase.

| Tema | Diapositivas | Apunte |
|---|---|---|
| Presentación de la materia | — | [Apunte](Apuntes/Teorías/0-%20Presentación.md) |
| 1. Introducción a HPC y GPGPU | [PDF](Teorías/Teoria-1---Introduccion-al-HPC-y-GPGPU.pdf) | [Apunte](Apuntes/Teorías/1-%20Introducción%20a%20HPC%20y%20GPGPU.md) |
| 2. Arquitecturas de GPU | [PDF](Teorías/Teoria-2---GPU-Arquitecturas.pdf) | [Apunte](Apuntes/Teorías/2-%20Arquitecturas%20GPU.md) |
| 3. Modelo de programación CUDA | [PDF](Teorías/Teoria-3---Modelo-de-Programacion-CUDA.pdf) | [Apunte](Apuntes/Teorías/3-%20Programación%20CUDA.md) |
| 4. Jerarquía de memoria | [PDF](Teorías/Teoria-4---Jerarquia-de-memoria-Nvidia.pdf) | — |
| 5. Optimizaciones en CUDA | [PDF](Teorías/Teoria-5---CUDA---Optimizaciones.pdf) | — |
| 6. CUDA Streams | [PDF](Teorías/Teoria-6---CUDA-Streams.pdf) | — |
| 7. Multi-GPU y modelos híbridos | [PDF](Teorías/Teoria-7---MultiGPUs-y-modelos-hbridos.pdf) | — |

### Ejemplos de aplicaciones

| Problema | Sin optimizar | Optimizado | Apunte |
|---|---|---|---|
| Multiplicación de matrices | [PDF](Teorías/Ejemplo-de-aplicaciones---Multiplicacion-de-matrices---Sin-optimizar.pdf) | [PDF](Teorías/Ejemplo-de-aplicaciones---Multiplicacion-de-matrices---Optimizado.pdf) | [Apunte](Apuntes/Explicaciones%20prácticas/Multiplicación%20de%20matrices.md) |
| Reducción de vectores | [PDF](Teorías/Ejemplo-de-aplicaciones---Reduccion---Sin-optimizar.pdf) | [PDF](Teorías/Ejemplo-de-aplicaciones---Reduccion---Optimizado.pdf) | [Apunte](Apuntes/Explicaciones%20prácticas/Reducción%20de%20vectores.md) |

## Prácticas

### [TP1 – CUDA básico](Prácticas/TP1/)

Ejercicios introductorios de CUDA. Consigna: [Practica-1---CUDA-basico.pdf](Prácticas/TP1/Practica-1---CUDA-basico.pdf).

| Archivo | Qué hace |
|---|---|
| [punto1a.cu](Prácticas/TP1/punto1a.cu) y [punto1b.cu](Prácticas/TP1/punto1b.cu) | Multiplica un vector por una constante; en 1b, C y N van en memoria de constantes |
| [punto2.cu](Prácticas/TP1/punto2.cu) | Suma de vectores |
| [punto3.cu](Prácticas/TP1/punto3.cu) | Suma de matrices N×N |
| [punto4.cu](Prácticas/TP1/punto4.cu) | Multiplicación de matrices N×N |
| [punto5.cu](Prácticas/TP1/punto5.cu) | Máximo y mínimo de un vector |
| [punto6.cu](Prácticas/TP1/punto6.cu) | Sumatoria de los desvíos al cuadrado respecto del promedio |
| [punto7.cu](Prácticas/TP1/punto7.cu) | Cantidad de ocurrencias de un valor, con una reducción en GPU |
| [punto8.cu](Prácticas/TP1/punto8.cu) | Ordenamiento par-impar (brick sort) en GPU; [brick_sort.c](Prácticas/TP1/brick_sort.c) es la versión secuencial |

## [TP final – Difusión de calor](TP%20final/)

Simulación de la difusión de calor en una grilla N×N, paralelizada con CUDA y comparada contra la versión secuencial de la cátedra.

- **Consigna:** [Enunciado](TP%20final/Enunciado.pdf) · [Explicación del problema](TP%20final/Ejemplo-de-aplicaciones---Difusion-de-calor.pdf)
- **Informe:** [Informe.pdf](TP%20final/Informe.pdf)
- **Código:**
  - [Secuencial/](TP%20final/Secuencial/): algoritmo secuencial de la cátedra, con medición de tiempos
  - [difusion_calor_cuda.cu](TP%20final/Paralelo/difusion_calor_cuda.cu): versión CUDA con memoria compartida y accesos coalescentes
  - [difusion_calor_cuda_streams.cu](TP%20final/Paralelo/difusion_calor_cuda_streams.cu): versión que solapa cálculo y copias con streams
- **Resultados:** [resultados/](TP%20final/resultados/) tiene los tiempos medidos en el cluster

En el [README del TP](TP%20final/README.md) está cómo compilar, ejecutar y medir.
