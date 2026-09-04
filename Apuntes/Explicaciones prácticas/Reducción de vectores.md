![[Pasted image 20260904093340.png]]
# Estrategia
- Implementación basada en árbol.
- Se requieren varias iteraciones, en cada iteración se realiza una nueva llamada al kernel y se aprovecha el hecho de que los valores de las variables en memoria global no cambian entre llamados al kernel.
![[Pasted image 20260904093431.png]]
- Para la 1ra iter. se crean N/2 hilos.
- 