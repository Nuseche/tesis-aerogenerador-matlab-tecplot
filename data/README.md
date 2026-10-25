# Datos autocontenidos del modelo

Los archivos MAT de `geometry/`, `sections/` y `reference/`, junto con el JSON
declarativo de `rigid_bodies/`, son los únicos datos heredados consumidos por
el solver nuevo. Se verifican con `MANIFEST.sha256`:

```sh
cd /Users/nuseche/Desktop/Tesis_codigos
shasum -a 256 -c data/MANIFEST.sha256
```

El cargador `io.load_model_data` usa rutas resueltas desde `config_default.m`;
no ejecuta scripts, no añade `legacy/` al path y no depende de `pwd`.
