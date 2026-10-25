# Integración pendiente de Acción 10

Este documento describe el cambio deliberadamente no aplicado a `main.m`,
`+post/export_all.m` y `+io/save_results.m` mientras se integra la Acción 09.
Debe aplicarse después de fijar el esquema final de `results.action09`.

## 1. Configuración canónica

`cases/config_action10_full_acceptance.m` ya fija la corrida aceptada
`run_20260831_163238_997_action09_seismic_newmark`. No sustituirla por una
búsqueda automática de “la última corrida”: la ruta resuelta debe quedar
persistida en `configuration.mat`. Mantener `requireHashes=true`; la suite calcula SHA-256
de `results.mat`, `manifest.mat` y `actionNN_matrices.mat` para cada corrida.

## 2. Rama coordinadora en `main.m`

1. Añadir `action10Only` junto a los demás selectores:

```matlab
action10Only=any(analysisType==["action10", ...
    "action10_full_acceptance","integral_acceptance"]);
```

2. La rama debe construir masa, `Tc`, equilibrio y operadores una sola vez.
   Debe conservar `elementCache` y todos los componentes de `ops`.
3. Antes de ejecutar modal/Newmark:

```matlab
results.validationPreflight=validation.run_validation_suite( ...
    modelData,ops,results,cfg,"preflight");
```

   Con `failOnCritical=true`, esta llamada detiene el proceso antes del solve.
4. Ejecutar el bloque modal de Acción 08 y el bloque sísmico de Acción 09. La
   Acción 10 no debe ejecutar de nuevo las suites 02–07: las recarga desde las
   rutas canónicas declaradas y registra `source="canonical_run"`.
5. Después de recuperar cinemática, reacciones y fuerzas internas:

```matlab
evidence=struct('runFolders',cfg.action10.canonicalRuns);
results.action10=validation.run_integral_acceptance_suite( ...
    modelData,ops,results,cfg,evidence);
results.meta.analysisScope= ...
    "integral_preflight_postflight_and_canonical_evidence_audit";
```

La rama solo debe llamar la suite integral después de crear
`results.action08`, `results.action09`, `results.modal` y `results.time`, o
dejar que esos datos se recarguen desde las corridas explícitas. Nunca crear
estructuras `passed=true` sintéticas para satisfacer cobertura.

## 3. Exportación

En `+post/export_all.m`, inicializar `artifacts.action10=struct()` y añadir:

```matlab
if isfield(results,'action10')&&~isempty(results.action10)
    artifacts.action10=post.export_action10(run,results.action10);
end
```

Esto produce:

- `action10_requirement_matrix.csv`;
- `action10_matrix_properties.csv`;
- `action10_evidence.csv`;
- `action10_artifacts.csv` (incluye los tres SHA-256 por acción).

## 4. Persistencia y manifiesto

En `+io/save_results.m`, guardar sin reensamblar:

```matlab
if isfield(results,'action10')&&~isempty(results.action10)
    Tanalysis=ops.reduced.Tc; %#ok<NASGU>
    action10Results=results.action10; %#ok<NASGU>
    schemaVersion="1.0.0"; %#ok<NASGU>
    save(fullfile(run.folder,'action10_matrices.mat'), ...
        'schemaVersion','Tanalysis','action10Results','-v7.3');
end
```

Añadir al manifiesto:

```matlab
manifest.hasAction10=isfield(results,'action10')&&~isempty(results.action10);
if manifest.hasAction10
    manifest.action10Passed=logical(results.action10.passed);
end
```

Una corrida de Acción 10 todavía no puede auditar su propio `SUCCESS` antes de
terminar. Tras `io.mark_run_success`, una recarga independiente debe verificar
su `SUCCESS`, manifiesto, MAT y hashes; esa auditoría externa es requisito del
informe de aceptación, no una puerta circular dentro de la misma corrida.

## 5. Verificación posterior a la integración

1. Ejecutar `tests/test_action10_integral_validation.m`.
2. Ejecutar la regresión completa.
3. Ejecutar `main('cases/config_action10_full_acceptance.m')`.
4. Recargar `results.mat` y `action10_matrices.mat` desde otro proceso MATLAB.
5. Confirmar que las acciones 02–09 tienen origen, suite, artefactos y hashes
   verificables y que no queda ningún estado crítico `unverified`.
6. Solo entonces redactar `docs/ACTION10_ACCEPTANCE_REPORT.md`.
