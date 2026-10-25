# Diagnóstico y plan de sensibilidad — 5 de octubre de 2026

## Versión auditada

Fuente activa: `/Users/nuseche/Desktop/Tesis_codigos`, revisión energética del 19 de septiembre. La copia en `Tesis/tmp/gyro_revision_20260919_tNQzVp/baseline` es histórica y no debe emplearse como solver actual. No existe repositorio Git en la raíz del solver; se usarán SHA-256 de fuentes y datos, además de snapshot. Se conserva el código central y las corridas anteriores.

Evidencia previa: `docs/GYROSCOPIC_REVISION_20260919.md`, regresión de 143 pruebas y corridas corregidas `run_20260919_182410_438_gyro_energy_corrected_20260919` y `run_20260919_183052_480_gyro_corrected_seismic_20260919`. Son antecedentes a reproducir, no verificaciones nuevas. Las aceptaciones integrales de agosto anteceden la revisión energética. El README de raíz todavía cita 126 pruebas; prevalece la evidencia de septiembre.

## Ecuaciones efectivamente implementadas

El equilibrio resuelve `Tc'*(f_ext(q)-f_int(q))=0` por Newton con búsqueda de línea y continuación desde rotor detenido. La rutina llamada `total_lagrangian_internal_force` describe energía corrotacional de pequeñas deformaciones; el nombre no demuestra una formulación geométricamente exacta. La masa y la inercia se mantienen en la configuración de referencia. La tangente del equilibrio incluye contribuciones inerciales asociadas al giro de orden Omega². Su almacenamiento en Kg evita contarlas otra vez: KOmega=0 cuando ya están incluidas.

En coordenadas físicas de referencia: `M qdd + D qd + K q = f`, con `D=C+G+massRate` y `K=Ke+Kg+KOmega+Kaero+Ktransport`. G es antisimétrica; massRate es un término de transporte, no amortiguamiento material. En coordenadas reducidas, para `q=T(t)z`, se añaden `2 T' M Tdot` en D y `T'*(D Tdot+M Tddot)` en K. La transformación homóloga y MBC también conserva sus derivadas. El QEP resuelve `(lambda² M + lambda D + K) phi=0` en los operadores transformados.

La velocidad nominal es constante por caso alrededor del vector 129→130. No hay guiñada nominal. El análisis modal usa azimut fijo; no integra coeficientes periódicos ni calcula multiplicadores de Floquet. Con `exp(lambda t)`, sigma=Re(lambda) es tasa de crecimiento [s^-1], fd=abs(Im(lambda))/(2 pi) [Hz] y zeta=-Re(lambda)/abs(lambda) para raíces oscilatorias. El espectro calculado con eigs es parcial.

## Topología, datos y capacidades

- Vigas Timoshenko 3D, seis GDL por nodo en ejes globales; masa consistente y alternativa HRZ explícita.
- Maestros independientes 129 (góndola) y 130 (cubo); raíces 21/57/93 vinculadas exactamente al cubo. La unión 129–130 usa rigideces ilustrativas, no identificadas experimentalmente. La base fija restringe los seis GDL del nodo 1. Hay una configuración heredada de apoyo flexible con matrices M/K/C explícitas.
- Secciones 1–20: torre/transición, acero heredado E=210 GPa, nu=0.3, rho=7850 kg/m³. Secciones 21–55: rigideces generalizadas y propiedades de masa heredadas de palas; no hay E, A y geometría verificables para reconstruirlas. Jx=Jy+Jz es la regla explícita existente. Offsets seccionales cero y cuerpos colocalizados en maestros son limitaciones de los datos.
- Giro: contribuciones distribuidas de palas y tensor completo del cubo, transporte inercial, restricciones móviles y transformación MBC; la torre y la góndola no reciben un giro nominal artificial.
- Sismo multicomponente sintético disponible, carga `-T' M R ag`, Newmark, recuperación física con Tdot/Tddot, respuesta absoluta, apoyos y fuerzas incrementales. Es integración de un punto operativo congelado, no evolución del rotor durante el registro.
- Aerodinámica: interfaz para cargas y tangentes proporcionadas por el usuario. Sin datos físicos, las contribuciones son cero. No se estudiarán parámetros aerodinámicos ni se atribuirá al solver un modelo BEM.

## Preguntas y campaña inicial acotada

1. ¿Cómo responden las ramas y sus grupos a velocidad, masa e inercia vinculadas, rigideces y amortiguamiento?
2. ¿Qué efecto tiene incluir el cambio del equilibrio? Todas las evaluaciones recalculan equilibrio; no se fijará artificialmente.
3. ¿La derivada es estable al reducir la perturbación y cambiar tolerancias del solve?
4. ¿Qué aporta el apoyo flexible ya declarado y cuánto depende su respuesta de K y C?
5. ¿Son las tendencias locales lineales y aparecen interacciones detectables entre los factores dominantes?

Se usarán factores positivos adimensionales de valor nominal 1. Los pasos relativos 0.02, 0.01 y 0.005 son perturbaciones exploratorias de diferenciación, NO intervalos experimentales, tolerancias de fabricación ni distribuciones. No permiten conclusiones sobre incertidumbre real. Se vincularán m y todas las inercias cuando se escale densidad a geometría fija. Un factor de rigidez común representa un cambio proporcional de la matriz seccional existente, sin inventar geometría. Los datos detallados se exportan por sección/cuerpo/conexión.

Orden: reproducir el punto nominal corregido y el detenido, medir costo; ejecutar regresión; comparar una repetición y solve más estricto; calcular diferencias centrales de ocho factores con tres pasos (48 casos + nominal); interpretar grupos por centroides y ángulos principales; reutilizar puntos locales para barridos cortos; cuatro combinaciones de los dos factores dominantes; campaña pequeña de apoyo flexible y comprobación temporal del sismo disponible. La convergencia espacial se estudia aparte subdividiendo elementos con propiedades constantes y manteniendo nodos y conexiones originales, primero con rotor detenido. No se tratará la malla como parámetro físico.

## Condiciones de aceptación y límites

Guardado independiente por caso, estados fallidos explícitos y reanudación solo con huella idéntica de configuración, código y datos. Métrica MAC de masa nominal en un mismo espacio físico completo, asignación global, distancia compleja de autovalores y comprobación subespacial de grupos próximos. Si la correlación es insuficiente o la identidad individual ambigua, no se publica una sensibilidad individual como inequívoca. No se identifican movimientos rígidos únicamente por frecuencia: se contrasta la forma con el espacio cinemático de seis movimientos rígidos, compatibilidad con apoyos y energía elástica.

Los residuos y repetición/solve estricto estiman precisión algebraica; la convergencia espacial/temporal estima error de discretización y no se confunde con esos residuos. Si las diferencias físicas no superan la estimación numérica, la tabla las etiqueta como no resueltas. Una precisión insuficiente de malla limita las conclusiones a la discretización heredada.

Morris puede ser conveniente como cribado posterior con costo r(k+1); Sobol necesita definición del dominio, medida de entrada y convergencia de estimadores con costo mayor. Esta campaña local no es global. No se ejecutará campaña global ni barrido amplio hasta una decisión del autor sobre rangos y costo. No se introducirán nuevas hipótesis de base, aerodinámica, offsets o conexiones para completar artificialmente entregables.

## Referencias metodológicas

Tisseur y Meerbergen (2001), *The Quadratic Eigenvalue Problem*, SIAM Review 43(2), 235–286, DOI https://doi.org/10.1137/S0036144500381988. Allemang (2003), *The Modal Assurance Criterion: Twenty Years of Use and Abuse*, Sound and Vibration 37(8), 14–23, https://www.sandv.com/downloads/0308alle.pdf. Morris (1991), *Factorial Sampling Plans for Preliminary Computational Experiments*, Technometrics 33(2), 161–174, DOI https://doi.org/10.1080/00401706.1991.10484804.

## Ajuste tras el piloto y ejecución

La comparación nueva contra septiembre, empleando su continuación de nueve velocidades, reprodujo las doce frecuencias con diferencia relativa máxima 6.4e-15. El salto directo de 0 a 12 rpm conserva un residuo aceptado, pero cambia las frecuencias hasta aproximadamente 0.3 %. Se incorpora ese contraste como estimación conservadora de ruido; no es error físico frente a una solución exacta. El intento de equilibrio a 1e-10 falló por búsqueda de línea y se documenta por separado. La opción `strict` de la campaña aprieta únicamente el QEP; no se atribuye a ella una precisión de equilibrio mayor.

Se ejecutaron también diez casos de rigidez del tren, cuatro combinaciones densidad/rigidez de pala y una campaña temporal pequeña de esos dos factores. La regresión final nueva dio 155/155; el snapshot de septiembre confirma que las 148 fuentes MATLAB anteriores no se modificaron. Los resultados cuantitativos y la discusión final se documentan en `RESULTADOS_Y_DISCUSION.md`.
