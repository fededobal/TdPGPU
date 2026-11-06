![](../Imagenes/Pasted%20image%2020260904093340.png)
# Estrategia
- Implementación basada en árbol.
- Se requieren varias iteraciones, en cada iteración se realiza una nueva llamada al kernel y se aprovecha el hecho de que los valores de las variables en memoria global no cambian entre llamados al kernel.
![](../Imagenes/Pasted%20image%2020260904093431.png)
- Para la 1ra iter. se crean N/2 hilos.
- Cada hilo suma su posición y la siguiente.
	![](../Imagenes/Pasted%20image%2020260904093558.png)
- Para minimizar el espacio de almacenamiento, el resultado de cada suma parcial se deja en la posición del primer operando.
	![](../Imagenes/Pasted%20image%2020260904093622.png)
- Para la siguiente iteración se invoca nuevamente al kernel con la mitad de hilos de la iteración anterior y se sigue con la misma estrategia.
- En la última iteración se invoca al kernel con un sólo hilo, el resultado final queda en la primer posición del vector.
# Alternativa
Una alternativa, que mejora el acceso a memoria, es utilizar un patrón de acceso a posiciones contiguas.
![](../Imagenes/Pasted%20image%2020260904093802.png)
![](../Imagenes/Pasted%20image%2020260904093813.png)
# CUDA
![](../Imagenes/Pasted%20image%2020260904093839.png)