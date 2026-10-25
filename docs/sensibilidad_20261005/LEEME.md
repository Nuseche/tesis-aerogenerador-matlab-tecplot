# Estudio de sensibilidad del solver actual

El módulo `+sensitivity` trabaja sobre la revisión energética de septiembre de 2026. No modifica `main.m` ni las rutinas físicas existentes. Las campañas son escenarios numéricos exploratorios y no una calibración o análisis probabilístico de la turbina.

## Ejecución reproducible

En MATLAB, desde cualquier directorio:

```matlab
root = '/Users/nuseche/Desktop/Tesis_codigos';
addpath(root); addpath(fullfile(root,'cases')); addpath(fullfile(root,'tests'));
folder = fullfile(root,'runs','sensitivity','mi_estudio');
sensitivity.run_initial_study(folder,'local');
sensitivity.run_initial_study(folder,'verification'); % malla, rotor detenido
sensitivity.run_initial_study(folder,'seismic');      % sismo sintético 0--1 s
sensitivity.run_initial_study(folder,'foundation');   % apoyo flexible heredado
sensitivity.run_initial_study(folder,'interactions'); % tras la clasificación aceptada
```

La fase local contiene 52 evaluaciones: nominal, repetición, QEP más estricto, continuación histórica y 48 perturbaciones centrales de ocho factores. El piloto tomó unos 9 s y la continuación histórica unos 26 s. Es un costo de varios minutos, sujeto al equipo. La fase de malla tiene tres casos; la sísmica seis; la de apoyo doce. Se incluye además una campaña local de diez casos para la rigidez del tren de potencia, definida en `run_connections.m`. Las interacciones contienen cuatro combinaciones de los dos factores con mayor sensibilidad frecuencial aceptada. No se seleccionan dominantes usando datos que fallen las puertas numéricas.

Para reanudar se usa exactamente la misma carpeta. Solo se reutilizan resultados con la misma huella de fuentes, datos, MATLAB, configuración y diseño. Los fallos guardados se mantienen; no se convierten en valores ficticios ni se reintentan silenciosamente. Si se corrige código o se quiere reintentar un fallo, se usa una nueva carpeta. `completed=true` significa que se intentaron todos los casos; el CSV de estados determina cuáles terminaron correctamente.

## Parámetros y consistencia

`parameter_table.m` documenta factores, procedencia y dependencias. `apply_parameters.m` escala propiedades antes de reconstruir el modelo. La densidad escala masa e inercias manteniendo geometría y centroide; los tensores rígidos se multiplican por un único factor positivo. Se mantiene la regla explícita Jx=Jy+Jz de las secciones. Las columnas heredadas `rawMassColumns` se conservan como procedencia: las columnas de torre son geométricas y no deben escalarse como si fueran masa.

Las rigideces seccionales se escalan proporcionalmente en las seis componentes de cada familia. Es un escenario constitutivo, no una modificación geométrica ni una identificación independiente de E, G y A. El amortiguamiento escala simultáneamente las dos razones objetivo del ajuste Rayleigh existente. Sus frecuencias objetivo permanecen fijas; las matrices C se reconstruyen cuando cambia M o Ke. El selector también admite rigidez del tren, K/C del apoyo y amplitud sísmica, sin inventar nuevos elementos.

Se exportan valores nominales por sección, cuerpo y conexión. EA/GA están en N; GJ/EI en N m²; masa lineal en kg/m; inercia seccional por unidad de longitud en kg m; masa rígida en kg e inercia rígida en kg m². K de conexión tiene componentes N/m y N m/rad. Las matrices generalizadas mezclan filas traslacionales y rotacionales: sus normas globales no representan una única magnitud física; la correlación modal usa una métrica de masa común.

## Seguimiento y respuestas

El QEP tiene 16 representantes para seguir 12 ramas. El margen permite detectar grupos que atraviesan la frontera espectral; se excluyen sus derivadas hasta seguir el grupo completo. En esta campaña la rama 12 está próxima a la 13 y queda excluida. La asignación maximiza globalmente una combinación de MAC complejo ponderado por la masa física nominal y proximidad de autovalores complejos. Los grupos próximos se detectan a ambos lados y se contrastan con ángulos principales. El umbral relativo 0.10 conserva el criterio de agrupamiento de Acción 08; es una decisión numérica conservadora, no una afirmación de multiplicidad exacta.

Una rama individual requiere MAC >=0.8 y margen de asignación >=0.05. Los grupos se interpretan mediante centroides de frecuencia/crecimiento/amortiguamiento y MAC subespacial mínimo >=0.95. Las derivadas individuales ambiguas son NaN y conservan una etiqueta. Los NaN de identidad no son corridas fallidas. Los movimientos rígidos se contrastan con los seis campos cinemáticos rígidos, la compatibilidad con apoyos y energía elástica.

Se usa exp(lambda t), frecuencia amortiguada abs(Im(lambda))/(2 pi), crecimiento Re(lambda) y zeta=-Re(lambda)/abs(lambda). No se normaliza el crecimiento por su valor nominal: se usa abs(lambda0), una escala de s^-1 que evita división por tasas pequeñas. Los desplazamientos estáticos se escalan con max(abs(q0),1 mm). Las frecuencias usan normalización relativa si no se anulan ni cambian de signo. Cada tabla guarda la escala y la convención empleadas.

Los canales temporales son desplazamientos relativos y aceleraciones absolutas en ejes globales: uy de los maestros 129/130 y uz de las puntas 56/92/128. La ventana es 0--1 s del registro analítico existente, con cinemáticas de suelo suministradas y Tdot/Tddot de un solo punto operativo. No se reconstruye una historia de orientación del rotor.

## Verificación y precisión

Las puertas incluyen masa reducida definida positiva, residuos de equilibrio y autovectores derechos/izquierdos, seguimiento, contraste de pasos y señal frente a ruido. El ruido algebraico se estima con repetición, QEP más estricto y cambio de continuación de equilibrio. La prueba piloto de equilibrio a 1e-10 falló por búsqueda de línea cerca de un piso 1e-9; se conserva la tolerancia original 1e-8. El QEP estricto no pretende resolver ese piso de la tangente numérica.

Los pasos 2 %, 1 % y 0.5 % permiten comprobar dependencia del cociente central. El criterio de concordancia es 2 % entre derivadas consecutivas, con piso absoluto documentado `1e-3*abs(scale)` en el denominador. La señal entre extremos debe ser diez veces mayor que el ruido nominal. Este filtro es conservador y no sustituye una cota rigurosa del error de derivada en todos los parámetros. Las tablas conservan también valores no aceptados para inspección.

El refinamiento divide cada miembro de propiedades constantes en 1/2/4 elementos, conserva los nodos y conexiones originales y no interpola propiedades inventadas. La comparación modal usa los nodos originales y la misma masa nominal. Es una verificación con rotor detenido, gravedad y azimut físico; no certifica por sí sola convergencia del QEP rotante. La fase sísmica compara pasos 0.01/0.005/0.0025/0.00125 s y verifica que escalar la amplitud produce la respuesta lineal esperada.

## Decisión pendiente sobre extensión

`cases/config_sensitivity_extended_pending.m` contiene una ficha deliberadamente no ejecutable: límites, fuentes, dependencias, medida de entrada y costo aún no definidos. Los puntos locales pueden graficarse como barridos cortos; no constituyen sensibilidad global. Morris sería una opción posterior de cribado sobre un dominio aprobado, con r(k+1) evaluaciones y comparación de estimadores entre números crecientes de trayectorias. Sobol requiere además una medida conjunta de entrada justificada y estimadores convergentes; no se asumirán independencia ni distribuciones experimentales ausentes.

Las figuras, CSV, MAT, logs, huellas y estados se guardan bajo la carpeta de campaña. El diagnóstico y la sección LaTeX de revisión están en este directorio. Los manuscritos previos no se modifican.

## Versiones de la evidencia

Las 99 evaluaciones se guardaron con el código inicial del módulo, congelado en `source_snapshot_20261005.tar.gz`. La revisión final de postprocesamiento añade la exclusión de grupos que atraviesan la frontera espectral y ordena primero los parámetros con indicadores aceptados. Los operadores y estados guardados no se recalcularon ni cambiaron. Las huellas del postprocesamiento están en `postprocessing_source_hashes.csv`, y la fuente final se congela por separado. La regresión final es 155/155, incluyendo doce pruebas del módulo y una específica para la frontera espectral.

Para reanudar las carpetas iniciales debe emplearse su snapshot de fuentes: el control de huella rechaza una revisión distinta. Para campañas nuevas se usa la versión final y una carpeta nueva. Los CSV conservan la notación de grupo `10+11`; al importarlos en MATLAB debe forzarse `modeOrGroup` a texto, o cargarse `summary.mat`, que conserva los tipos. Las figuras revisadas y verificadas están en `figures_revision/`.
