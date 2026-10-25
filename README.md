# Solver MATLAB del aerogenerador

Este directorio contiene el reemplazo modular del modelo heredado. El punto de
entrada es `main.m`; las fuentes originales permanecen en `Codigos_sergio/` y
su copia congelada y verificable se conserva en `legacy/`.

## Ejecución

Se requiere MATLAB R2026a o una versión compatible con paquetes, `eigs`,
`readtable` y MATLAB Unit Test.

```matlab
cd('/Users/nuseche/Desktop/Tesis_codigos')
results = main();                         % geometría + validación segura
cfg = config_default();
cfg.analysis.type = "stationary_modal";
cfg.modal.enabled = true;
cfg.drivetrain.stiffness = [1e9 1e9 1e9 1e10 1e10 1e10];
results = main(cfg);                      % estructura explícita
```

Para ejecutar y aceptar de forma aislada el elemento Timoshenko 3D de la
Acción 02:

```matlab
result = main('cases/config_action02_timoshenko.m');
```

Los cierres sísmico e integral se reproducen con:

```matlab
result09 = main('cases/config_action09_seismic_newmark.m');
result10 = main('cases/config_action10_full_acceptance.m');
```

`main` acepta una estructura, un archivo `.m` que devuelva una estructura o un
archivo `.mat`/`.json`. Ninguna función depende del directorio activo. Cada
ejecución crea `runs/run_...` con configuración, snapshot del modelo, estado de
equilibrio, operadores, resultados, validaciones, tablas, figuras y log.

Para regenerar tablas y figuras sin reensamblar:

```matlab
regenerate_outputs("/ruta/al/run_guardado")
```

Para ejecutar la suite completa:

```matlab
addpath(pwd)
addpath(fullfile(pwd,'tests'))
results = run_all_tests();
```

También puede usarse:

```bash
/Applications/MATLAB_R2026a.app/bin/matlab -batch \
  "cd('/Users/nuseche/Desktop/Tesis_codigos'); addpath('tests'); run_all_tests"
```

## Casos soportados

- geometría solamente y validación de datos;
- modal estacionario conservativo, con base fija o flexible;
- modal rotante con equilibrio por continuación, rigidez geométrica,
  giroscopía, MBC, QEP y barrido Campbell;
- respuesta sísmica estacionaria o rotante mediante Newmark promedio constante;
- masa consistente o diagonalización explícita seleccionada por configuración.

Las interfaces aerodinámicas están implementadas como tangentes explícitas. Si
no se proporcionan matrices o funciones de usuario verificadas, sus valores son
cero y esa decisión queda registrada; el solver no inventa coeficientes
aerodinámicos. Lo mismo aplica a offsets/productos de inercia no presentes en
las fuentes heredadas: se usan los valores documentados en los datos, no valores
supuestos silenciosamente.

Las convenciones completas están en `docs/CONVENTIONS.md`.
La trazabilidad de cada acción y los resultados de aceptación están en
`docs/IMPLEMENTATION_REPORT.md`.
El detalle numérico e interpretación de la Acción 02 están en
`docs/ACTION02_ACCEPTANCE_REPORT.md`.
Los cierres de operadores dinámicos y MBC/QEP/Campbell están en
`docs/ACTION07_ACCEPTANCE_REPORT.md` y
`docs/ACTION08_ACCEPTANCE_REPORT.md`, respectivamente.
Los cierres sísmico e integral están en
`docs/ACTION09_ACCEPTANCE_REPORT.md` y
`docs/ACTION10_ACCEPTANCE_REPORT.md`.

La regresión final del 31 de agosto de 2026 contiene **126 pruebas aprobadas,
0 fallidas y 0 incompletas**. Las corridas canónicas finales son
`run_20260831_163238_997_action09_seismic_newmark` y
`run_20260831_165045_307_action10_full_acceptance`.

Los casos funcionales completos están en `cases/`. Sus rigideces de tren de
potencia son ilustrativas y están marcadas como no calibradas; la ejecución
predeterminada no inventa el dato ausente y, por ello, se limita a validar la
geometría.

## Sensibilidad local — octubre de 2026

El paquete `+sensitivity` incorpora perturbaciones vinculadas de masa/inercia,
seguimiento modal complejo y subespacial, control del paso de diferenciación,
campañas reanudables con huellas SHA-256 y exportación independiente. Parte de
la revisión energética de septiembre; las 148 fuentes MATLAB previas se
conservan intactas. La regresión final nueva contiene 155 pruebas aprobadas.

El diagnóstico, la metodología, los límites de interpretación, las fuentes
LaTeX y los scripts de reproducción están en
`docs/sensibilidad_20261005/LEEME.md`. La campaña inicial se conserva en
`runs/sensitivity/initial_20261005/`. Los intervalos locales son exploratorios;
los barridos amplios y la sensibilidad global requieren definir dominio y costo.

## Morris exploratorio aprobado — 6 de octubre de 2026

El autor aprobó factores 0.90–1.10 para masa e inercias de palas, rigideces
seccionales de palas y velocidad del rotor (10.8–13.2 rpm), con presupuesto
de treinta minutos. `cases/config_sensitivity_morris_approved.m` configura
cuarenta trayectorias, semilla guardada y comparación de prefijos 10/20/40.
Se incluyen controles en el nominal y dos esquinas, seguimiento de grupos
completos y criterios separados de ruido y estabilización para la influencia
media y su dispersión. Los límites son escenarios exploratorios aprobados.

La reproducción y discusión de esta etapa están en
`docs/sensibilidad_morris_20261006/ENTREGA.md`; los estados y resultados crudos,
en `runs/sensitivity/morris_20261006/`. La entrega local anterior y sus
snapshots se conservan. La ficha antigua
`config_sensitivity_extended_pending.m` permanece como propuesta histórica;
use el nuevo caso aprobado para esta etapa.

## Comparación de entradas medidas — 20 de octubre de 2026

`docs/entradas_reales_20261020/LEEME.md` documenta registros sísmicos
procesados sin escalar, viento medido de DTU y la aproximación autorizada de
empuje axial con media libre. Se conservaron 114 evaluaciones comparativas
y 54 verificaciones adicionales de la Hessiana, sin modificar las 175
fuentes congeladas. Los archivos de diagnóstico conservan también un fallo
de convergencia; no se sustituyó por un resultado ficticio.

La comparación temporal usa operadores congelados. Las sensibilidades a
amplitudes y los máximos combinados se distinguen de las derivadas respecto
de propiedades mecánicas: 22 pendientes son estables frente a los pasos
examinados y una supera además la envolvente conservadora completa. El
estudio no establece una clasificación mecánica temporal global ni una
demanda eólica calibrada de servicio. Las fuentes, tablas, figuras,
verificaciones y comandos de reproducción se detallan en esa carpeta.
