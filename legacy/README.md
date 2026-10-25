# Archivo heredado inmutable

`legacy/Codigos_sergio/` es una copia byte a byte del directorio original
`Codigos_sergio/` tomada el 25 de agosto de 2026. Los archivos de la copia se
marcaron como solo lectura y no forman parte del path ni de la ejecución del
solver nuevo.

`MANIFEST.sha256` registra SHA-256, tamaño y rutas de origen/destino. La copia
se verifica con:

```sh
cd /Users/nuseche/Desktop/Tesis_codigos
shasum -a 256 -c legacy/MANIFEST.sha256
```

El importador aislado `tools/import_legacy_version0.m` es el único componente
nuevo autorizado a ejecutar `GeoTorre.m` y `Secciones.m`; genera archivos MAT
autocontenidos bajo `data/`. El benchmark modal se ejecuta por separado con
`tools/run_legacy_v0_benchmark.m`, porque el script original borra su workspace.
