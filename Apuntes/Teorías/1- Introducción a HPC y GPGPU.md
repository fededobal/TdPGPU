# High Performance Computing
> [!NOTE] Definición
> Práctica de sumar potencia de cómputo con el fin de alcanzar mayor rendimiento en la ejecución de programas que resuelven problemas complejos o de gran tamaño de la ciencia, ingeniería o negocios.
## Sistema Paralelo
>[!NOTE] Definición
>Sistema organizado de hardware y software paralelos que permite ejecutar múltiples tareas de manera simultánea. Su objetivo es mejorar el rendimiento respecto a un algoritmo secuencial, ya sea reduciendo el tiempo de ejecución, aumentando la eficiencia energética o logrando ambos beneficios.

Este sistema está compuesto por dos componentes principales y un objetivo fundamental:
- Software paralelo (algoritmo): Conjunto de hilos o procesos que cooperan en la resolución de un problema.
- Hardware paralelo (arquitectura): Conjunto de unidades de procesamiento que permiten la ejecución simultánea de los hilos o procesos del software paralelo.
- Objetivo: Mejorar el rendimiento respecto a la ejecución secuencial del problema.
## Graphics Processing Unit
>[!NOTE] Definición
>Coprocesador creado para procesamiento gráfico y liberar a la CPU del renderizado.

- Actualmente se utiliza para procesamiento de propósito general (GPGPU) no gráfico.
- Una GPU se conecta vía puerto PCI Express aunque los modelos de CPUs nuevos incorporan una GPU dentro del circuito integrado (Intel y AMD).
### Clasificación
- Mecanismos de control (Taxonomía de Flynn).
- Modelo de comunicación (relacionado con la memoria).
- Granularidad (relacionado con el número y potencia de las unidades de procesamiento).
#### Taxonomía de Flynn
Basada en dos aspectos:
- Flujo de instrucciones concurrentes (control).
- Flujo de datos.

|                     | Una instrucción | Múltiples instrucciones |
| ------------------- | --------------- | ----------------------- |
| **Un dato**         | SISD            | MISD                    |
| **Múltiples datos** | SIMD            | MIMD                    |
- Single Instruction Single Data: Un único flujo de instrucciones y un único flujo de datos.
	- Arquitectura correspondiente al modelo secuencial tradicional.
	- Ejemplo: Monoprocesadores (la mayoría de las PCs del siglo XX)
![[Pasted image 20260821085851.png]]

- Single Instruction Multiple Data: Un único flujo de instrucciones y múltiples flujos de datos.
	- Arquitectura donde la misma operación se ejecuta en paralelo sobre diferentes datos.
	- Ejemplos: GPUs y unidades vectoriales SSE o AVX.
![[Pasted image 20260821085935.png]]

- Multiple Instruction Single Data: Múltiples flujos de instrucciones y un único flujo de datos.
	- Modelo de arquitectura poco común. Aplica distintas operaciones sobre los mismos datos.
	- Ejemplos asociados pero no reales: Sistemas redundantes tolerantes a fallos o Hacking de un mensaje codificado.
![[Pasted image 20260821090012.png]]

- Multiple Instruction Multiple Data: Múltiples flujos de instrucciones y múltiples flujos de datos.
	- Arquitectura donde cada unidad de procesamiento puede ejecutar su propio programa y trabajar sobre datos distintos.
	- Pueden ser de memoria compartida o distribuida.
	- Ejemplos: Multiprocesadores, Multicores, Clusters, Grid.
![[Pasted image 20260821090059.png|700]]
## Modelos de comunicación
### Multiprocesadores de memoria compartida
- UMA (Uniform Memory Access).
	- Cuando todos los procesadores acceden de forma uniforme a la memoria.
	- El costo siempre es el mismo.
	![[Pasted image 20260821091246.png|349]]
- NUMA (Non-Uniform Memory Access).
	- Cuando cada procesador tiene acceso a determinados bancos de memoria.
	- Al mejorar la localidad, mejora el rendimiento.
	- Común en servidores.
	- De todas formas, cada CPU puede acceder a cualquier banco de memoria.
	![[Pasted image 20260821091319.png|349]]
	
![[Pasted image 20260821091340.png]]
En los dos modelos anteriores, la memoria es la misma.
- Jerarquía de memoria
	- Generalmente con dos o más niveles de caché (L1, L2, L3, L4).
	- Según la arquitectura, los niveles 2, 3 y 4 suelen estar compartidos entre cores.
	- Las GPUs poseen una jerarquía de memoria más compleja.
		![[Pasted image 20260821091438.png|352]]
### Multiprocesadores de memoria distribuida
- Cada máquina tiene su propia memoria y se comunican mediante pasaje de mensajes.
- Para simplificar se asumen varias PCs independientes con una CPU por PC.
![[Pasted image 20260821091529.png]]
### Híbrido
Es posible tener ambos modelos.
![[Pasted image 20260821092613.png]]
### Granularidad
En hardware, se refiere al número y la potencia de las unidades de procesamiento.
#### Grano fino
Muchas unidades de procesamiento poco potentes (GPUs).
#### Grano grueso
Pocas unidades de procesamiento muy potentes.
## Descomposición de problemas
- Para desarrollar un algoritmo paralelo el primer paso es descomponer el problema en sus partes concurrentes (tareas).
- Se trata de definir un gran número de pequeñas tareas (descomposición de grano fino), para brindar la mayor flexibilidad a los “potenciales” algoritmos paralelos.
- Se ignoran cuestiones como el número de unidades de procesamiento y aspectos específico en la máquina de destino.
- La atención se centra en reconocer oportunidades de ejecución paralela.
![[Pasted image 20260821092826.png|557]]

![[Pasted image 20260821092856.png|700]]

- La descomposición de datos o de dominio, también conocida como paralelismo de datos, se caracteriza por la ejecución simultanea de la misma operación sobre diferentes elementos de datos.
- Es más adecuado para arquitecturas de tipo SIMD.
- Los datos pueden tener estructuras:
	- Regulares (arreglos, matrices).
		- Las GPUs se suelen adaptar mejor acá.
	- Irregulares (grafos).
### Comportamiento de las aplicaciones
- Intensivas en cómputo (CPU bound).
	- Aplicaciones científicas.
	- Se benefician más de las GPUs.
- Intensivas en memoria.
	- Ordenación.
	- Búsquedas.
	- Se benefician también de las GPUs pero no igualmente. Por ejemplo, ordenar un array en una GPU es deficiente por la conexión con la GPU.
- Intensivas en E/S.
	- Simulación.
	- Big data.
	- Las GPUs no pueden hacer operaciones de E/S.
- Híbridos: la aplicación presenta distintas fases intensivas.
#### Latencias
Distintos eventos relacionados al cómputo requieren de un tiempo específico (Latencias).
![[Pasted image 20260821093415.png]]
## Herramientas de software para paralelismo
- Para memoria compartida:
	- Pthreads.
	- OpenMP.
	- ***CUDA sobre GPUs. Usaremos este.***
	- Otros (OpenCL, Cilk, Sycl...).
- Para memoria distribuida:
	- PVM.
	- MPI.
	- Otros (RMI, Sockets, RPC...).
- Híbrido (ej. MPI + OpenMP + CUDA).
## Relación arquitectura - programación
![[Pasted image 20260821094338.png]]

# Resumen
## Extendido
**1. Arquitectura de memoria compartida.** Los hilos se comunican leyendo y escribiendo memoria, no por pasaje de mensajes. Por eso se programa con CUDA/OpenCL y no con MPI. La jerarquía es más compleja que en un multicore: registros y memoria local (por hilo), memoria compartida (por SM), memoria global, y caches de constantes y texturas.

**2. Modelo SIMD – SIMT.** En Flynn es SIMD: una única unidad de control manda **la misma instrucción** a muchas UPs, cada una operando sobre **sus** datos. SIMT es el refinamiento de NVIDIA: los hilos se agrupan en _warps_ (32) que comparten el contador de programa, pero cada hilo tiene registros propios y puede tomar otro camino en un `if`. Cuando eso pasa hay **divergencia** y las ramas se ejecutan en serie, con pérdida de rendimiento.

**3. Arquitectura de grano fino.** Muchísimas unidades de procesamiento poco potentes (_manycore_), al revés de la CPU (grano grueso: pocas UPs muy potentes). El rendimiento no sale de la velocidad individual sino del volumen: hay que **saturarla de hilos**, y la latencia de memoria se oculta con concurrencia masiva, no con caches grandes.

**4. Se adapta mejor al paralelismo de datos sobre estructuras regulares.** La descomposición de datos consiste en ejecutar la misma operación sobre distintos elementos, que es justo lo que pide SIMD (a diferencia de la descomposición funcional, de código disjunto). Con arreglos y matrices el índice del hilo mapea directo al dato y los accesos son contiguos; con grafos aparecen accesos dispersos, carga desbalanceada y divergencia.

**5. Adecuada para aplicaciones intensivas en CPU.** Las _CPU bound_ (cómputo científico) son el caso ideal. Las _memory bound_ (ordenación, búsquedas) se benefician menos, porque el límite pasa a ser el movimiento de datos más las transferencias por PCIe. Las _I/O bound_ son un problema: **la GPU no hace entrada-salida** y depende del host. El criterio es la intensidad aritmética: si hay poco cómputo por dato, gana la copia.

**6. Modelos híbridos.** Hoy las arquitecturas son combinaciones de memoria compartida y distribuida, y cada herramienta cubre un nivel: máquinas Multi-GPU; multicore/multi-GPU (OpenMP–CUDA, Pthreads–CUDA); cluster de multicore/multi-GPU (OpenMP–MPI–CUDA). Se juntan la facilidad de acceso a memoria del modelo compartido con la escalabilidad y tolerancia a fallos del distribuido.
## Breve
- Una GPU es una Arquitectura de memoria compartida.
- Una GPU sigue un Modelo SIMD - SIMT.
- Una GPU es una Arquitectura de grano fino.
- Una GPU se adapta mejor a paralelismo de datos (regulares).
- Una GPU es adecuada para aplicaciones intensivas en CPU.
- Es posible generar Modelos híbridos de gran potencia de cómputo:
	- Máquinas Multi-GPU.
	- Maquinas Multicore/MultiGPU (OpenMP – Cuda, Pthreads – Cuda, etc).
	- Cluster de Multicore/MultiGPU (OpenMP – MPI – Cuda, Pthreads – MPI – Cuda, etc).