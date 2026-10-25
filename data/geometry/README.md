# Geometría Version 0

`legacy_geometry_v0.mat` contiene únicamente datos extraídos del script
heredado `GeoTorre.m`: `coordinates` (138 x 3), `connectivity` (137 x 4) y
los tres arreglos auxiliares independientes `coorP1aux`, `coorP2aux` y
`coorP3aux` (36 x 3 cada uno). Version 0 utiliza las filas 1--35 para sus
35 elementos de cada pala; la fila 36 se conserva como dato heredado, pero no
se asigna artificialmente a ningún elemento.

La conectividad conserva los tipos heredados 1, 2, 3 y 4. La clasificación
y el retiro de los cuatro elementos tipo 3 ocurre de forma explícita en
`model.build_model`; los nueve elementos tipo 4 (IDs 125--133) se conservan.
