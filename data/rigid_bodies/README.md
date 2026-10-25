# Cuerpos rígidos Version 0

`legacy_rigid_bodies_v0.json` transcribe las masas e inercias de góndola y
cubo de `FrecuenciasTorreCompleta.m`, líneas 159–177 de Version 0. El archivo
es declarativo: cargarlo no ejecuta código heredado.

Los valores angulares `[90,-5,-90]` se almacenan explícitamente en grados y se
convierten una sola vez a radianes. El `rotmat` heredado tenía comentado
`*pi/180`, por lo que la ejecución histórica usó accidentalmente los números
como radianes. Ese comportamiento no satisface las convenciones SI del modelo
nuevo y no se reproduce como interpretación física.

La fuente no incluye posiciones de los centros de masa. Los offsets cero son
una hipótesis de colocalización en los nodos maestros 129 y 130, identificada
como tal en cada registro. Deben sustituirse cuando se disponga de datos del
aerogenerador real.
