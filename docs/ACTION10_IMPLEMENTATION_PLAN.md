# Plan de implementación de la Acción 10 — validación integral

**Estado:** implementación en curso; no constituye aceptación.  
**Fecha:** 31 de agosto de 2026.  
**Dependencia crítica satisfecha durante la implementación:** la Acción 09
aportó la corrida aceptada
`run_20260831_163238_997_action09_seismic_newmark`; la Acción 10 todavía debe
integrarse en el coordinador y producir su propia corrida recargable.

## 1. Alcance

La Acción 10 convierte las puertas especializadas de las Acciones 02–09 en una
auditoría única, trazable y reproducible. La auditoría debe distinguir:

- `preflight`: propiedades que deben fallar antes de ejecutar un solve;
- `postflight`: residuos, modalidades, dinámica temporal y persistencia;
- `passed`, `failed`, `not_applicable` y `unverified` como estados diferentes;
- evidencia numérica de una hipótesis o benchmark físico calibrado.

La ausencia de un resultado, archivo o campo obligatorio se registra como
`unverified` y falla si el requisito es crítico. Las matrices aerodinámicas no
simétricas se inspeccionan sin alterarlas.

## 2. Contrato de la suite

`validation.run_integral_acceptance_suite(modelData,ops,results,cfg,evidence)`
recibirá el estado ensamblado y, opcionalmente, evidencia recargada de corridas.
Entregará:

- `checks`: registros con identificador estable, fase, estado, medición,
  tolerancia, criticidad, mensaje, acción recomendada y artefacto;
- `requirementTable`: matriz global exportable;
- `matrixTable`: propiedades de matrices completas y reducidas;
- `evidenceTable`: cobertura y estado de las suites 02–09;
- `artifactTable`: existencia, marcador `SUCCESS`, esquema y coherencia de los
  artefactos declarados;
- `passed` y `criticalFailures`.

El quinto argumento podrá omitirse para pruebas unitarias. La ejecución
canónica deberá proporcionar un inventario de corridas 02–09 o resultados de
las suites ejecutadas en memoria.

## 3. Matriz requisito–prueba–artefacto–tolerancia

| ID | Fase | Prueba directa | Evidencia/artefacto | Puerta |
|---|---|---|---|---:|
| A10-PRE-001 | preflight | entradas y modelo validados | `results.input.validation` | todas las puertas críticas aprobadas |
| A10-PRE-002 | preflight | finitud y dispersidad de operadores | `matrixTable` | todos finitos y dispersos |
| A10-PRE-003 | preflight | simetría mecánica pasiva | `M`, `C`, `Ke`, `Kg`, `KOmega` | residual `<=1e-9` |
| A10-PRE-004 | preflight | antisimetría giroscópica | `G` | residual `<=1e-9` |
| A10-PRE-005 | preflight | amortiguamiento pasivo semidefinido positivo | `C` reducida | `lambda_min >= -1e-10 ||C||_1` |
| A10-PRE-006 | preflight | identidades de operadores | `D=C+G`, `K=Ke+Kg+KOmega+Kaero` (`C` ya contiene `Caero`) | residual `<=1e-12` |
| A10-PRE-007 | preflight | masa reducida definida positiva | `M` reducida | Cholesky exitosa |
| A10-PRE-008 | preflight | rango y condicionamiento numérico de `Tc` | `Tc` | rango completo; `rcond(Tc'*Tc)>=1e-12` |
| A10-INT-002..008 | postflight | suites especializadas 02–08 | campo `results.actionNN` o evidencia recargada | `passed=true` y checks críticos aprobados |
| A10-INT-009 | postflight | suite sísmica/Newmark | `results.action09` o evidencia recargada | `passed=true`; ausencia=`unverified` |
| A10-MOD-001 | postflight | finitud y clasificación modal | `results.modal` | todas finitas y etiquetas no vacías |
| A10-MOD-002 | postflight | QEP derecho/izquierdo, pares y biortogonalidad | suite 08 | residuos `<=1e-8`, biortogonalidad `<=1e-6` |
| A10-MOD-003 | postflight | continuidad Campbell individual/subespacial | suite 08 | MAC efectivo `>=0.8`, subespacial `>=0.95` |
| A10-MOD-004 | postflight | equivalencia conservativa a 0 RPM | suite 08 | error relativo `<=1e-6` |
| A10-MOD-005 | postflight | alcance del espectro | solución modal persistida | `spectrumComplete` explícito; parcial permitido y declarado |
| A10-TIM-001 | postflight | finitud de `q`, `qd`, `qdd` | `results.time` | sin NaN/Inf |
| A10-TIM-002 | postflight | cinemática absoluta, restricciones y reacciones | suite 09 | residuo `<=1e-9` |
| A10-TIM-003 | postflight | fuerzas internas local/global y ensamblaje | suite 09 | error hacia atrás y ensamblaje `<=1e-12` |
| A10-TIM-004 | postflight | energía | suite 09/`results.time.energy` | modelo completo `<=1e-6`; crítica cuando se declara |
| A10-TIM-005 | postflight | convergencia temporal | suite 09 | orden `>=1.8`; mallas finas `<=1e-3` |
| A10-ART-001 | postflight | marcador de éxito | cada corrida canónica | archivo `SUCCESS` presente |
| A10-ART-002 | postflight | recarga sin reensamblaje | MAT requeridos | carga completa y esquema compatible |
| A10-ART-003 | postflight | coherencia de manifiesto | `manifest.mat/json` | acción presente y aprobada |
| A10-ART-004 | postflight | trazabilidad física | configuración/manifiesto | estados de calibración explícitos |

Los requisitos temporales son `not_applicable` únicamente cuando la
configuración declara que no ejecuta dinámica temporal. En el caso integral
canónico son críticos y no pueden omitirse.

## 4. Cambios previstos

1. Ampliar `validation.check_matrix_properties` para `C`, `D`, `K`, `Kaero`,
   `Caero`, identidades, dispersidad, positividad y diagnóstico numérico de
   `Tc`, conservando compatibilidad con las pruebas existentes.
2. Dar a `validation.run_validation_suite` una fase explícita opcional y hacer
   crítico el balance energético cuando `cfg.validation.requireEnergyBalance`
   sea verdadero.
3. Crear `validation.run_integral_acceptance_suite` con normalización de checks
   heredados y estados de cobertura explícitos.
4. Crear `cases/config_action10_full_acceptance.m` con todos los criterios,
   etiquetas de benchmark y referencias a las corridas canónicas.
5. Crear `post.export_action10` para exportar las tres tablas de auditoría sin
   reensamblar.
6. Crear pruebas unitarias de matrices, evidencia ausente, propagación de
   fallos, estados no aplicables, exportación y un fixture integral positivo.

## 5. Integración coordinada pendiente

Para evitar conflictos con la implementación simultánea de la Acción 09, esta
tarea no modifica `main.m`, `+post/export_all.m` ni `+io/save_results.m`. Al
terminar se dejará un parche/instrucción de integración que deberá:

- añadir la rama `action10_full_acceptance` después de que Acción 09 esté
  disponible;
- ejecutar preflight antes de modal/tiempo e integral postflight al final;
- almacenar `results.action10` y `action10_matrices.mat`;
- exportar `action10_requirement_matrix.csv`, `action10_matrix_properties.csv`,
  `action10_evidence.csv` y `action10_artifacts.csv`;
- añadir `manifest.hasAction10` y `manifest.action10Passed`.

## 6. Verificación y criterio de cierre

La implementación se verificará primero con
`tests/test_action10_integral_validation.m` y después con las pruebas globales
afectadas. No se redactará `ACTION10_ACCEPTANCE_REPORT.md` ni se declarará la
Acción 10 aceptada hasta contar con Acción 09 aceptada, corrida canónica 10 con
`SUCCESS`, recarga independiente, regresión completa verde y auditoría visual
de sus artefactos.
