# Informe de aceptación — Acción 10: validación integral

**Fecha:** 31 de agosto de 2026  
**Entorno:** MATLAB R2026a Update 4, MACA64  
**Corrida canónica:** `runs/run_20260831_165045_307_action10_full_acceptance`  
**Estado:** aceptada como auditoría integral del solver y sus benchmarks.

## 1. Alcance ejecutado

La corrida reconstruye masa, restricciones, equilibrio y nueve puntos
operativos entre 0 y 12 RPM. Ejecuta un preflight antes de los solves modal y
temporal, vuelve a calcular en memoria las suites 08 y 09, y recarga las
corridas canónicas 02–09 declaradas explícitamente. Cada corrida recargada se
audita por `SUCCESS`, manifiesto, esquema, MAT especializado y tres hashes
SHA-256.

La suite distingue `passed`, `failed`, `not_applicable` y `unverified`. La
ausencia de evidencia crítica no puede convertirse en aprobación.

## 2. Resultados

- preflight global: aprobado;
- validación global posterior: aprobada;
- suite 08 recalculada: aprobada;
- suite 09 recalculada: 30/30 puertas aprobadas;
- matriz integral: **649/649 requisitos en estado `passed`**;
- propiedades matriciales: 620 verificaciones;
- suites especializadas disponibles y aprobadas: 8/8;
- artefactos canónicos completos y con hash: 8/8;
- estados `unverified`: 0;
- estados `failed`: 0;
- transformación de análisis persistida: `828×804`, dispersa.

La matriz auditó `M`, `C`, `D`, `G`, `Ke`, `Kg`, `KOmega`, `Kaero`,
`Caero`, `K` y `Tc` en el punto primario y en los nueve puntos del barrido.
Se comprobó `D=C+G`, con `Caero` ya incluido en `C`, sin simetrizar tangentes
aerodinámicas no simétricas.

## 3. Recarga y postproceso

Desde un segundo proceso MATLAB se recargaron `results.mat`,
`action10_matrices.mat` y `manifest.mat`. Se verificaron el marcador `SUCCESS`,
`manifest.hasAction10=true`, `manifest.action10Passed=true`, los 649 checks, las
ocho filas de evidencia/artefactos y la dispersidad de `Tanalysis`.

Después se ejecutó `regenerate_outputs` sin reensamblar. Los cuatro CSV de
Acción 10 y las figuras Campbell/sísmica se regeneraron correctamente. Las
figuras fueron inspeccionadas visualmente y se exportaron con fondo blanco,
unidades y leyendas legibles.

## 4. Regresión final

La regresión completa posterior pasó **126/126**, con cero fallos y cero
pruebas incompletas. El test canónico de Acción 09 usa un directorio temporal
con limpieza automática y no deja corridas pesadas dentro de `runs/`.

## 5. Hashes de cierre

| Archivo | SHA-256 |
|---|---|
| `results.mat` | `b655836d30cd1992c9f96bb94653ecd106c52580b15ed712a1d12728e01fe639` |
| `action10_matrices.mat` | `e4b7b8d1c22c0d708fa3044d0bda71c81c0e2dcb2b765f97d0094dd51dfdfd5a` |
| `manifest.json` | `e5e8a79ac383b2feb53578abff859093de4e4eb4c4cdd794f5f737737c926136` |
| `action10_requirement_matrix.csv` | `b8b9a995bd282730a6f053c6b2ce9615a21bbbbecf914291bbcc992eb36b4aaa` |
| `action10_artifacts.csv` | `c028a45444fb1d295706d41dcad95797fc4af5b31bf124be4e8d7592988abdbd` |
| `tests/latest_results.mat` | `65873aa621ce5295a41447706f11dc470ac39773eb81a2c9bd7434dea9c1267b` |

## 6. Alcance físico

La aceptación demuestra consistencia del solver, continuidad numérica,
persistencia y trazabilidad. No convierte en datos físicos los parámetros del
tren, Rayleigh, offsets de masa, aerodinámica o movimiento sísmico sintético.
El Campbell permanece congelado en azimut y con espectro objetivo parcial; la
respuesta temporal no es una combinación normativa de diseño.

Con estas limitaciones explícitas, la Acción 10 queda aceptada y cierra la
implementación numérica prevista por el plan director.
