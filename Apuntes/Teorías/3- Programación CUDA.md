# Gestión de hilos
Cuando ejecute un programa en CUDA, lo voy a parametrizar con los parámetros del programa (ej. el tamaño del problema) y la cantidad de hilos por bloque.
```
./miPrograma N threadsPerBlock
```
## Kernel

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
## Modularidad
![[Pasted image 20260904085859.png]]
