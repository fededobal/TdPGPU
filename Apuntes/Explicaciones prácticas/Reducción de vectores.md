![[Pasted image 20260904093340.png]]
# Estrategia
- Implementación basada en árbol.
- Se requieren varias iteraciones, en cada iteración se realiza una nueva llamada al kernel y se aprovecha el hecho de que los valores de las variables en memoria global no cambian entre llamados al kernel.
![[Pasted image 20260904093431.png]]
- Para la 1ra iter. se crean N/2 hilos.
- Cada hilo suma su posición y la siguiente.
	![[Pasted image 20260904093558.png]]
- Para minimizar el espacio de almacenamiento, el resultado de cada suma parcial se deja en la posición del primer operando.
	![[Pasted image 20260904093622.png]]
- Para la siguiente iteración se invoca nuevamente al kernel con la mitad de hilos de la iteración anterior y se sigue con la misma estrategia.
- En la última iteración se invoca al kernel con un sólo hilo, el resultado final queda en la primer posición del vector.
- 