# Informe de implementación y aceptación

Fecha de actualización: 31 de agosto de 2026. MATLAB usado para aceptación:
R2026a Update 4.

La aceptación vigente de la Acción 02 está documentada en
`docs/ACTION02_ACCEPTANCE_REPORT.md`. Esta actualización fija la semántica del
punto auxiliar como eje local 3 y la regla explícita de inercia longitudinal de
las palas.

## Correspondencia con el plan director

1. **Base y benchmark.** `legacy/` contiene una copia de solo lectura y
   manifiestos SHA-256 de `Codigos_sergio`. `data/` contiene geometría,
   secciones y 20 frecuencias de Version 0 con precisión completa. La fuente
   conserva 138 nodos/137 elementos; el modelo flexible nuevo contiene 133 al
   retirar los cuatro conectores tipo 3. Los auxiliares P1/P2/P3 se importan
   por separado.
2. **Timoshenko 3D.** `+elements/` implementa extensión, torsión, flexión en
   ambos planos, cortante e inercia rotacional con masa consistente. Las
   pruebas cubren tracción, torsión, dos flexiones, límite Euler-Bernoulli,
   transformación local/global, seis modos rígidos y convergencia de malla.
3. **Restricciones exactas.** `+rigid/rigid_constraint_matrix.m` construye
   `q=Tc*qbar`; 130 gobierna 21/57/93 y 129 permanece independiente. El error
   cinemático se verifica numéricamente.
4. **Masas rígidas.** La masa espacial 6×6 conserva offset, orientación y
   tensor completo. `compute_mass_properties` recupera masa, CG e inercia y
   verifica conservación por congruencia.
5. **Masa consistente.** Es la opción predeterminada. Una diagonalización por
   suma de filas existe solo como opción explícita y rechaza diagonales
   negativas; nunca usa `abs`. Las masas rígidas se agregan después.
6. **Equilibrio y centrifugación.** `+equilibrium/` integra gravedad y cargas
   centrífugas, resuelve Newton por continuación de RPM, recupera axiales y
   ensambla `Kg`; `KOmega` se anula cuando el término ya está en `Kg`.
7. **Giroscopía/amortiguamiento/aerodinámica.** Se separan Rayleigh,
   cimentación, tren de potencia y aerodinámica. `G` es antisimétrica y cambia
   de signo con RPM. Las tangentes aerodinámicas pueden entregarse directamente,
   mediante función analítica o por diferencias finitas; no se simetrizan.
8. **MBC/QEP/Campbell.** Se implementan `T/Tinv/Tdot/Tddot`, verificación por
   diferencias finitas, formulaciones congelada/promedio azimutal, QEP
   generalizado, pares complejos/raíces sobreamortiguadas, MAC y seguimiento de
   ramas. El postproceso crea `campbell.png` y CSV.
9. **Sismo/Newmark.** Aceptado en
   `run_20260831_163238_997_action09_seismic_newmark`: proyección de masa
   completa, influencias cinemática/efectiva separadas, recuperación absoluta,
   restricciones, reacciones, fuerzas internas y convergencia temporal.
10. **Validación automática.** Aceptada en
    `run_20260831_165045_307_action10_full_acceptance`: preflight/postflight,
    649 requisitos, recarga de ocho suites y ocho artefactos con SHA-256.

## Cierre de las Acciones 09–10

- Acción 09: 30/30 puertas críticas; orden temporal del modelo `2.0017`;
  diferencia relativa fina `3.0719e-4`; residuo dinámico `6.1205e-13`.
- Acción 10: 649/649 requisitos aprobados, 620 verificaciones matriciales,
  8/8 suites y 8/8 artefactos completos, cero estados `unverified`.
- Regresión final: **126 aprobadas, 0 fallidas, 0 incompletas**.
- La recarga y regeneración de tablas/figuras se verificó desde MAT sin
  reensamblaje.

## Resultados de aceptación de la Acción 02

- Suite MATLAB vigente: **70 aprobadas, 0 fallidas, 0 incompletas**.
- Suite especializada: **31/31 verificaciones críticas aprobadas**.
- Ensamblaje flexible: matrices `M` y `Ke` dispersas de `828×828`, finitas y
  simétricas.
- Convergencia a 64 elementos: errores relativos `6.103e-5` en desplazamiento,
  `3.643e-5` en la primera frecuencia y `5.838e-4` en la segunda, todos por
  debajo de `1e-3`.
- Primeras frecuencias aisladas: torre `0.7196683 Hz`; palas entre
  `0.4194551 Hz` y `0.4194880 Hz`.
- Corrida canónica:
  `runs/run_20260826_210833_538_action02_timoshenko`.

## Resultados históricos de integración

Los valores siguientes corresponden a la aceptación del 25 de agosto previa a
la corrección de ejes e inercia seccional de la Acción 02. Se conservan como
trazabilidad, pero deben regenerarse en las acciones posteriores antes de ser
interpretados como resultados vigentes del modelo integrado.

- Suite MATLAB en ese cierre: **61 aprobadas, 0 fallidas, 0 incompletas**.
- Benchmark legado: primera frecuencia `0.19173102440399947 Hz`; 20 valores
  reproducidos y almacenados.
- Modelo integrado: 828 GDL completos, 810 independientes por `Tc` y 804
  libres con base fija.
- Masa recuperada del caso estacionario: `2,601,611.15 kg`, CG global
  `[0.460663, 0.000002, 113.886566] m`; error de conservación por `Tc`
  `2.58e-18`.
- Libre-libre completo: exactamente seis modos rígidos.
- Modal estacionario demostrativo: `f1 = 0.161126 Hz` y 20 modos resueltos.
- Campbell: 3 velocidades (0/6/12 RPM) × 12 ramas, MBC/QEP finitos.
- Caso rotante 12 RPM: residuo de equilibrio del orden de `1.3e-12` y `G`
  antisimétrica a precisión numérica.
- Sismo: 201 pasos, 804 GDL, respuesta finita y error energético máximo
  `0.08557`, menor que la tolerancia configurada de 0.10.
- Cimentación flexible: caso legado blando completado; `f1 = 0.1464 Hz`.
- Regeneración de tablas y figuras desde resultados guardados comprobada sin
  reensamblaje.

## Alcance físico de los casos demostrativos

Los archivos heredados no contienen una rigidez física verificada del tren
129–130 ni tangentes aerodinámicas calibradas. Por esa razón:

- `config_default.m` ejecuta geometría/validación y no inventa esos datos;
- los casos de `cases/` declaran explícitamente una rigidez de tren ilustrativa,
  marcada como no calibrada;
- `Kaero/Caero` son cero si el usuario no aporta matrices o funciones;
- la giroscopía rígida del cubo está activa; una contribución distribuida de
  pala puede entregarse por elemento cuando la formulación de investigación la
  requiera;
- el equilibrio predeterminado es lineal elástico con iteración Newton; existen
  interfaces explícitas para fuerza interna y tangente no lineales;
- MBC ofrece sistema congelado y promedio azimutal, no un análisis de Floquet
  periódico completo.

Estas decisiones aparecen en configuración, diagnósticos y manifiestos; no son
supuestos ocultos. Los resultados demostrativos prueban el solver, pero no deben
publicarse como predicción calibrada de la turbina hasta sustituir los datos
ilustrativos.
