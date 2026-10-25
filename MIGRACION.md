# Migración de MATLAB y Tecplot

Repositorio privado: https://github.com/Nuseche/tesis-aerogenerador-matlab-tecplot

## Contenido

El clon incluye el solver MATLAB, paquetes, casos, pruebas, geometría, propiedades,
entradas medidas, scripts de campañas, documentos y 124 figuras Tecplot con sus
DAT, PLT, macros, LAY y LPK. Los capítulos que estaban fuera de esta carpeta se
copiaron a `docs/tesis_cinematica_20260929/`; los originales locales se conservan.

Las corridas completas y la carpeta `output/` se conservan byte por byte en los
archivos de la release `migration-data-20261025`. El manifiesto versionado
`migration/data_manifest.json` identifica cada archivo y cada paquete por SHA-256.
No se trasladan entornos virtuales, cachés, instaladores ni licencias. La licencia
completa debe estar configurada en el equipo de destino; no se copia desde este Mac.

## Clonar y preparar Python

Se requiere Python 3.11 o superior; se recomienda Python 3.12 y un entorno nuevo.
Comprobar primero `python --version` (el Python 3.9 del sistema macOS no sirve).
Desde una terminal:

```sh
git clone https://github.com/Nuseche/tesis-aerogenerador-matlab-tecplot.git
cd tesis-aerogenerador-matlab-tecplot
python -m venv .venv
# Linux/macOS:
source .venv/bin/activate
# Windows PowerShell, en su lugar:
# .venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python migration/preflight.py
```

El acceso requiere una cuenta autorizada al repositorio privado. La comprobación
no ejecuta el solver ni consulta una licencia: verifica importaciones, entradas y
los archivos nativos; informa por separado si faltan resultados históricos.
`requirements.txt` sustituye al antiguo `pip freeze` de la instalación local, que
contenía rutas `file://` y paquetes internos ajenos al proyecto.

## Ejecutar MATLAB

Instalar/activar MATLAB en el destino. La versión usada en el proyecto es R2026a.
Desde la raíz del clon, con `matlab` disponible en PATH:

```sh
matlab -batch "addpath(pwd); results = main();"
matlab -batch "addpath(pwd); addpath('tests'); run_all_tests();"
```

La primera orden valida geometría y datos; la segunda ejecuta la suite completa.
Para un caso estructural concreto, usar `main('cases/config_action02_timoshenko.m')`
o los demás casos documentados en `README.md` y `cases/README.md`. Las campañas de
sensibilidad son costosas: sus scripts no se lanzan al clonar ni al verificar.
Los casos nuevos deben construirse con `config_default()` en el destino. Los MAT
históricos conservan sus rutas originales como evidencia; no reutilizar a ciegas
una configuración absoluta guardada en otra máquina para iniciar una corrida nueva.

## Usar Tecplot con la licencia del equipo remoto

Configurar la ruta del ejecutable real, no la carpeta de instalación:

```sh
# Linux/macOS, ejemplo; sustituir por la ruta instalada:
export TESIS_TECPLOT='/ruta/tecplot360/bin/tec360'
# PowerShell, equivalente:
# $env:TESIS_TECPLOT = 'C:\ruta\Tecplot 360 EX\bin\tec360.exe'
```

Instalar Ghostscript y poner `gs` (o `gswin64c` en Windows) en PATH, o definir
`TESIS_GHOSTSCRIPT` con la ruta del ejecutable. Es necesario para convertir los
EPS vectoriales a PDF. Los PDF de escenas transparentes conservan el PNG nativo
sin pérdidas. El flujo de macros no requiere PyTecplot.

Primero comprobar una figura, después exportar la biblioteca:

```sh
python postprocessing/tecplot_20261007/scripts/regenerate.py --export-only --only concept_particula-seccion
python postprocessing/tecplot_20261007/scripts/regenerate.py --export-only
```

`--export-only` usa los DAT incluidos y reajusta las rutas de los macros al clon;
no requiere descargar las corridas. Los LPK incluyen sus datos y se pueden abrir
directamente en Tecplot. Los LAY conservan referencias relativas a los datasets.
Ejecutar los macros por el script para reajustar las rutas antes de abrirlos.
El comando escribe figuras y metadatos nuevos: es normal que Git muestre cambios.
La ejecución nativa con la licencia completa queda por comprobar en el destino.

## Restaurar todas las corridas y salidas guardadas

Con GitHub CLI autenticado, desde la raíz del clon:

```sh
gh release download migration-data-20261025 --repo Nuseche/tesis-aerogenerador-matlab-tecplot --pattern 'persisted-data-*.tar.gz' --dir .migration-cache
python migration/data_bundle.py restore --asset-dir .migration-cache
python migration/preflight.py
```

También pueden descargarse los mismos archivos desde la release y pasarse su
carpeta a `--asset-dir`. Reservar espacio para los paquetes y unos 5 GB adicionales
para los datos extraídos. La restauración verifica hashes, impide rutas fuera del
clon y rechaza archivos existentes diferentes: usar un clon limpio si ya hay
corridas locales. No elimina ni modifica resultados diferentes para hacerlos coincidir.

Con las corridas restauradas puede reconstruirse la conversión de datos:

```sh
python postprocessing/tecplot_20261007/scripts/regenerate.py --prepare-only
# Revisar datos y catálogo; después exportar con --export-only.
```

`--prepare-only` lee evidencia existente y crea DAT/macros; no ejecuta MATLAB.
No se ejecutaron campañas nuevas para esta migración.

## Documentación opcional

Para compilar LaTeX instalar Tectonic y definir `TESIS_TECTONIC` o ponerlo en PATH.
Para las revisiones de PDF se necesita Poppler (`pdftoppm`). La carpeta de capítulos
puede cambiarse mediante `TESIS_DOCUMENTS`. Los informes y manifiestos anteriores
mantienen rutas y hashes de su fecha original, no son una comprobación nueva del
host remoto. La documentación detallada de cada campaña conserva sus límites físicos.
