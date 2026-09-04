# Gestión de hilos
Cuando ejecute un programa en CUDA, lo voy a parametrizar con los parámetros del programa (ej. el tamaño del problema) y la cantidad de hilos por bloque.
```
./miPrograma N threadsPerBlock
```
## Kernel

> [!NOTE] Title
> Se denomina **kernel** a la función que ejecutarán todos los hilos del grid.

