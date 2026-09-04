# Gestión de hilos
Cuando ejecute un programa en CUDA, lo voy a parametrizar con los parámetros del programa (ej. el tamaño del problema) y la cantidad de hilos por bloque.
```
./miPrograma N threadsPerBlock
```
# Kernel

> [!NOTE] Title
> Se denomina **kernel** a la función que ejecutarán todos los hilos del grid.

```c
__global__ void miFuncion( parámetros ) {
	…
}
```
- Global identifica a la función como kernel.
- No tiene valor de retorno.
- La invocación a un kernel es asíncrona.
- De esta forma, mientras la función del kernel se ejecuta, se puede continuar la ejecución en la CPU o en otras GPUs.
- Para que el proceso que llama al kernel se demore luego de la invocación es necesario hacer lo siguiente:
```c
…
…
dim3 bloque(N,N); //Bloque bidimensional de N*N hilos
dim3 grid(M,M); //Grid bidimensional de M*M bloques
miFuncion<<<grid, bloque>>>(parámetros);
cudaDeviceSynchronize();
…
```
# Modularidad
![[Pasted image 20260904085859.png]]
# Variables built-in
- Identificar hilos de bloque
	- threadidx.x
	- threadidx.y
	- threadidx.z
- Identificar bloques de grid
	- blockIdx.x
	- blockIdx.y
- Identificar dimensiones de un bloque
	- blockDim.x
	- blockDim.y
	- blockDim.z
- Identificar dimensiones de un grid
	- gridDim.x
	- gridDim.y

![[Pasted image 20260904090508.png]]
![[Pasted image 20260904090556.png]]
![[Pasted image 20260904090616.png]]
# Planificación
- Las GPUs no soportan afinidad, osea que el programador sólo define la organización de los hilos pero no puede decidir sobre la planificación.
- El estado de los warps se lleva en una tabla en hardware llamada scoreboarding (una por warp scheduling) que permite decidir que warp será el próximo en ejecutar.
![[Pasted image 20260904090948.png]]

![[Pasted image 20260904091310.png]]
## Fermi
![[Pasted image 20260904090728.png]]
## Volta
![[Pasted image 20260904090749.png]]
# Manejo de errores
- La mayoría de las funciones CUDA devuelven un código de error del tipo cudaError_t. Sino, devuelve cudaSuccess si tuvo éxito.
- Igualmente, un llamado al kernel no tiene valor de retorno.
- Para saber si salió con éxito