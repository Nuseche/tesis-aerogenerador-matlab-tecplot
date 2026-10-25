"""Integrate the verified grid complement into the existing sensitivity source."""
from pathlib import Path
import csv, json, re, shutil, hashlib

ROOT=Path(__file__).resolve().parents[3];D=ROOT/'docs/sensibilidad_complementaria_20261014'
OLD=ROOT/'docs/sensibilidad_morris_20261006';P=OLD/'SECCION_MORRIS_REVISION.tex'
S=json.loads((D/'analysis_summary.json').read_text());source=P.read_text()
backup=D/'source_before_complement.txt'
if not backup.exists():backup.write_text(source)
target=OLD/'figures/actualizacion_20261014';target.mkdir(parents=True,exist_ok=True)
for p in (D/'figures').glob('*'):
    if p.suffix in ['.png','.pdf']:shutil.copy2(p,target/p.name)
source=source.replace(r'\date{Resultados del 6 de octubre de 2026; versión ilustrada para revisión}',
                      r'\date{Morris del 6 de octubre y comprobación complementaria del 14 de octubre de 2026}')
if r'\usepackage{placeins}' not in source:source=source.replace(r'\usepackage{graphicx}',r'\usepackage{graphicx}'+'\n'+r'\usepackage{placeins}')
if r'\hypersetup{hidelinks}' not in source:source=source.replace(r'\usepackage{hyperref}',r'\usepackage{hyperref}'+'\n'+r'\hypersetup{hidelinks}')
source=source.replace(r'\item Examinar la compensación masa--rigidez con combinaciones dirigidas y más de una respuesta; distinguir curvatura e interacción en 10+11.',
                      r'\item Ampliar la identificación masa--rigidez con otras respuestas y formas, partiendo de los contrastes ya comprobados en 10+11.')
source=source.replace('convergencia espacial en operación, comprobación de compensaciones o extensión periódica.',
                      'convergencia espacial en operación, identificación con múltiples respuestas o extensión periódica.')
source=re.sub(r'Las figuras se exportan desde Tecplot.*?para preparar las figuras\.',
              r'Las figuras históricas se exportaron desde Tecplot y se incluyen como PDF externos. Los datos, macros y paquetes nativos permanecen en su biblioteca. Las figuras nuevas y las adaptaciones para proyección se exportaron desde MATLAB con autorización del autor ante la licencia Tecplot vencida. Las fuentes originales se conservan en morris\\_estimators.csv, morris\\_sweeps.csv, morris\\_vertices.csv, report\\_data.json y modal\\_energy\\_evidence.csv. La comprobación adicional usa grid\\_responses.csv y sus tablas de contrastes. No se reemplazaron casos fallidos; los nueve casos nuevos se registran en una campaña separada.',
              source,flags=re.S)
note='\nEl 14 de octubre se completó la rejilla de 64 combinaciones reutilizando 58 puntos y resolviendo seis faltantes. Se añadieron tres controles numéricos. Los nueve casos nuevos convergieron, sin cambios de rangos ni formulación. El contraste masa--rigidez de 10+11 supera la envolvente empírica en las cuatro velocidades examinadas.\n'
if note.strip() not in source:source=source.replace(r'\section{Qué se varió y qué representa el modelo}',note+'\n'+r'\section{Qué se varió y qué representa el modelo}')
refnote='\nEl artículo original de Morris utiliza media y dispersión de efectos elementales; la media absoluta $\\mu_i^*$ corresponde a la extensión de Campolongo, Cariboni y Saltelli \\cite{campolongo2007}. Los filtros de seguimiento, ruido y estabilización son decisiones de esta implementación.\n'
if refnote.strip() not in source:source=source.replace(r'\section{Resultados: dirección, magnitud y ejemplo con unidades}',refnote+'\n'+r'\section{Resultados: dirección, magnitud y ejemplo con unidades}')
signed=r'''\begin{figure}[htbp]\centering
\includegraphics[width=.98\linewidth,height=.40\textheight,keepaspectratio]{figures/actualizacion_20261014/influencia_firmada_grupos.pdf}
\caption{Estimadores originales de Morris, con las etiquetas reales de los grupos. Se representa $\mu_i/0.20$; círculos para masa/inercia, diamantes para rigidez y cuadrados para velocidad. Los símbolos llenos indican influencia aceptada y los vacíos, no resuelta. El grupo 12 permanece excluido. La figura nueva conserva los datos del Morris y utiliza el estilo monocromático autorizado.}\label{fig:sentidos}
\end{figure}'''
source=re.sub(r'\\begin\{figure\}.*?\\label\{fig:sentidos\}.*?\\end\{figure\}',lambda m:signed if m.group(0).count(r'\begin{figure}')==1 else m.group(0),source,flags=re.S)
# Restrict replacement to individual figure blocks, rather than spanning earlier floats.
source=re.sub(r'\\begin\{figure\}(?:(?!\\begin\{figure\}).)*?\\end\{figure\}',lambda m:signed if r'\label{fig:sentidos}' in m.group(0) else m.group(0),source,flags=re.S)
section=r'''
% BEGIN COMPLEMENT 20261014
\clearpage
\section{Comprobación complementaria de la rejilla y de los efectos combinados}
\subsection{Cobertura, controles y conservación del modelo}
La rejilla de cuatro niveles y tres factores contiene $4^3=64$ combinaciones. Morris había visitado 58 combinaciones distintas. Se resolvieron las seis faltantes y tres controles: QEP más estricto y continuación en uno de esos puntos, y repetición nominal. Se conservaron los casos de Morris y sus estimadores. Las nueve evaluaciones nuevas tomaron 77.49 s de solve, bajo un límite operacional de 300 s. La campaña modal global reúne así 170 evaluaciones originales y nueve complementarias, con 64 puntos de rejilla distintos.

Se verificaron las 175 huellas de fuentes de la campaña original. Los grupos históricos se conservan y sus formas pasan las comprobaciones correspondientes. La rama 12 continúa abierta frente a ramas fuera del conjunto seguido y queda excluida. Los rangos físicos, propiedades vinculadas y formulación permanecen iguales. La continuación y el QEP estricto en un nuevo punto no aumentaron la envolvente de frecuencia de 10+11: $\eta=8.7456\times10^{-5}$ Hz. La diferencia máxima de sus controles nuevos fue $1.0613\times10^{-5}$ Hz.

Las medias de secantes de extremos conservan el orden de influencia de los cinco grupos principales. Sus pasos y ponderaciones difieren de Morris, de modo que no son estimadores idénticos ni derivadas infinitesimales. En 1+2, la media absoluta de secantes de masa de extremo tiene cociente señal/ruido 10.41, cercano al umbral 10; solo once de sus dieciséis comparaciones individuales superan ese umbral. Este resultado marginal no cambia retrospectivamente la ausencia de aceptación de su estimador Morris.

\subsection{Compensación parcial a las cuatro velocidades}
Se examina la diagonal $\xi_\rho=\xi_K$ a 10.8, 11.6, 12.4 y 13.2 rpm. El cambio entre factores iguales 0.90 y 1.10 es de aproximadamente 0.00495--0.00519 Hz, equivalente a 0.404--0.423\pct\ de $f_{d,0}$ de 10+11. Cada curva de la figura usa como origen su propio punto diagonal 0.90. La cercanía de frecuencias apoya una compensación parcial, pero no una identidad válida para toda la respuesta. La identificación de propiedades necesita otras frecuencias, formas u observaciones.
\begin{figure}[htbp]\centering
\includegraphics[width=.92\linewidth,height=.37\textheight,keepaspectratio]{figures/actualizacion_20261014/compensacion_rejilla.pdf}
\caption{Cambios de frecuencia de 10+11 a lo largo de la diagonal masa--rigidez, medidos respecto del punto 0.90 de cada velocidad y normalizados por la frecuencia nominal fija. Se muestran únicamente valores calculados de la rejilla; las líneas conectan esos valores.}\label{fig:compensacion-rejilla}
\end{figure}
\FloatBarrier

\subsection{Contraste rectangular para distinguir no aditividad}
Para dos factores $i,j$, con el tercero fijo, se calcula el contraste de sus extremos:
\begin{equation}
I_{ij}=f_{++}-f_{+-}-f_{-+}+f_{--}.
\end{equation}
Los signos indican factores 1.10 y 0.90. Si la respuesta fuera una suma de funciones separadas de los dos factores, el contraste sería cero, incluso si dichas funciones tuvieran curvatura individual. Un contraste resuelto evidencia no aditividad de esta respuesta en esos puntos. No atribuye un mecanismo concreto a un término del operador ni cuantifica un porcentaje de varianza.

La envolvente propagada es $b_I=4\eta$, por los cuatro términos del contraste. Se exige $|I_{ij}|\geq10b_I$, además de seguimiento válido. La cota continúa siendo empírica. Para 10+11 se obtiene:
\begin{center}\small
\begin{tabular}{lrrl}\toprule
Par & $|I_{ij}|$ [Hz] & $|I_{ij}|/b_I$ & Interpretación \\ \midrule
Masa--rigidez & 0.00926--0.00940 & 26.47--26.87 & Resuelto \\
Masa--velocidad & 0.00356--0.00362 & 10.17--10.34 & Marginal sobre el umbral \\
Rigidez--velocidad & 0.00331--0.00342 & 9.47--9.77 & No resuelto \\
\bottomrule\end{tabular}
\end{center}
Masa--rigidez presenta contraste negativo en las cuatro velocidades. El incremento de rigidez tiene menor efecto de frecuencia al aumentar masa, de forma compatible con la dependencia conjunta de rigidez e inercia. La afirmación se limita al contraste observado, no a una separación causal de todos los operadores. Masa--velocidad supera por poco el umbral y requiere cautela. Rigidez--velocidad permanece sin resolución suficiente; no se infiere ausencia de interacción.
\begin{figure}[htbp]\centering
\includegraphics[width=.98\linewidth,height=.38\textheight,keepaspectratio]{figures/actualizacion_20261014/contrastes_interaccion.pdf}
\caption{Contrastes de extremos en 10+11, normalizados por $f_{d,0}$. Cada curva deja fijo un factor diferente, identificado en la leyenda. Los símbolos llenos superan el umbral empírico y los vacíos no. Las líneas discontinuas muestran $\pm10b_I/f_{d,0}$ en porcentaje.}\label{fig:contrastes-interaccion}
\end{figure}
\FloatBarrier

\subsection{Curvatura individual y límites de esta comprobación}
En pasos igualmente espaciados se calcula $C_i=f_{i+1}-2f_i+f_{i-1}$. En 10+11, seis de los 32 contrastes de masa/inercia superan diez veces la envolvente $4\eta$. Ninguno de los 32 contrastes de rigidez o de velocidad supera ese filtro. Por tanto, la evidencia adicional resuelve curvatura de masa en ciertos puntos y no aditividad masa--rigidez; las restantes ausencias de resolución no prueban linealidad.

El contraste masa--velocidad es un indicador diferente de $\sigma_\Omega$ de Morris, cuya aceptación original sigue siendo negativa. La rejilla completa verifica todos sus 64 puntos discretos, sin certificar extrema o monotonicidad del dominio continuo, convergencia espacial en operación ni incertidumbre probabilística. Sus tablas guardan también todos los indicadores que no superan el filtro.

La licencia de Tecplot vencida impidió exportaciones nuevas. El autor autorizó el 14 de octubre utilizar las figuras ya generadas y producir las restantes con el mismo formato y estilo. Se exportaron tres figuras nuevas y cuatro adaptaciones de legibilidad para la presentación con MATLAB R2026a, en escala de grises, fondo blanco y PDF vectorial. Su catálogo registra motor, datos y procedencia. Las figuras anteriores conservan su procedencia Tecplot.
% END COMPLEMENT 20261014
'''
source=re.sub(r'\n% BEGIN COMPLEMENT 20261014.*?% END COMPLEMENT 20261014\n','\n',source,flags=re.S)
source=source.replace(r'\section{Estabilidad, alcance y decisiones para continuar}',section+'\n'+r'\section{Estabilidad, alcance y decisiones para continuar}')
source=source.replace('Estas son propuestas para acordar; no se han ejecutado campañas adicionales en la preparación de este documento.',
                      'La comprobación de la rejilla y los contrastes finitos anteriores ya se ejecutaron. Los restantes puntos son propuestas científicas para acordar; no se han ejecutado campañas de refinamiento en operación ni estabilidad periódica.')
source=source.replace('La figura~\\ref{fig:dominio} muestra la oposición y compensación parcial entre masa y rigidez.',
                      'Las figuras~\\ref{fig:dominio} y~\\ref{fig:compensacion-rejilla} muestran la compensación parcial; los contrastes de la figura~\\ref{fig:contrastes-interaccion} resuelven no aditividad masa--rigidez en 10+11.')
bib=r'\bibitem{campolongo2007} F. Campolongo, J. Cariboni y A. Saltelli. An effective screening design for sensitivity analysis of large models. \emph{Environmental Modelling \& Software}, 22(10), 1509--1518, 2007. \href{https://doi.org/10.1016/j.envsoft.2006.10.004}{doi:10.1016/j.envsoft.2006.10.004}.'
if bib not in source:source=source.replace(r'\end{thebibliography}',bib+'\n'+r'\end{thebibliography}')
P.write_text(source)
body=source.split(r'\section{Qué se puede concluir del estudio}',1)[1].split(r'\begin{thebibliography}',1)[0]
(OLD/'seccion_para_incorporar.tex').write_text('% Cuerpo equivalente actualizado al 14 de octubre de 2026. Requiere graphicx, amsmath, booktabs, colores/macro pct de la fuente y las carpetas figures. Integre las referencias morris1991 y campolongo2007.\n'+r'\section{Qué se puede concluir del estudio}'+body)

report='''# Comprobación complementaria de sensibilidad — 14 de octubre de 2026

Se completaron las seis combinaciones faltantes de la rejilla de cuatro niveles dentro del dominio ya aprobado. Se reutilizaron 58 puntos del Morris y se ejecutaron tres controles nuevos. Las nueve evaluaciones convergieron en 77.49 s de solve. No se modificaron rangos, hipótesis físicas, fuentes del solver ni estimadores Morris.

## Método y alcance

La rejilla cubre 64 combinaciones de masa/inercia, rigidez de palas y velocidad. Se recalcula el equilibrio en cada caso. Se preservan grupos seguidos por formas y subespacios; la rama 12 continúa excluida. Los controles nuevos son QEP estricto, continuación en un punto nuevo y repetición nominal. Las tablas mantienen indicadores sin resolución.

Los contrastes rectangulares I = f++ − f+− − f−+ + f−− dejan fijo el tercer factor. La aditividad de los dos factores implica I=0, incluso con curvatura individual. Se propaga la envolvente empírica como b=4η y se exige |I|≥10b. Esa envolvente no es una garantía matemática de error en todo el dominio. Las curvaturas individuales usan C=f_siguiente−2f_central+f_anterior a pasos iguales.

## Resultados nuevos en 10+11

| Par de factores | Magnitud del contraste [Hz] | Señal / envolvente | Lectura |
|---|---:|---:|---|
| Masa–rigidez | 0.00926–0.00940 | 26.47–26.87 | Resuelto en cuatro velocidades |
| Masa–velocidad | 0.00356–0.00362 | 10.17–10.34 | Apenas sobre el umbral |
| Rigidez–velocidad | 0.00331–0.00342 | 9.47–9.77 | No resuelto |

Los cuatro contrastes masa–rigidez son negativos. Su signo indica que el incremento de rigidez tiene menor efecto sobre la frecuencia cuando aumenta la masa. Es una observación de no aditividad en esta respuesta y estos puntos, sin separar contribuciones causales de los operadores ni asignar porcentajes de varianza.

La diagonal de factores iguales masa=rigidez cambia 0.00495–0.00519 Hz entre 0.90 y 1.10, equivalentes a 0.404–0.423 % de la frecuencia nominal de 10+11. Se comprueba en las cuatro velocidades. Esto respalda compensación parcial y muestra una posible ambigüedad al identificar propiedades con una sola frecuencia.

Seis de 32 contrastes de curvatura de masa superan el filtro en 10+11. Los de rigidez y velocidad no lo superan. La no resolución no demuestra linealidad. El contraste masa–velocidad y la dispersión Morris de velocidad son indicadores distintos; el último conserva su falta de aceptación original.

## Comparación con Morris

Las secantes de extremos conservan el orden de influencia de los cinco grupos principales, pero usan pasos y ponderaciones diferentes del muestreo Morris. No se exige igualdad entre sus números. Los 14 indicadores medios y dos dispersiones aceptados pertenecen a la campaña original y permanecen intactos.

En 1+2, la media absoluta de secantes de masa entre extremos tiene cociente señal/ruido 10.41, apenas sobre el umbral. Once de sus 16 comparaciones individuales lo superan. Este dato marginal no modifica la ausencia de aceptación del estimador Morris de masa en 1+2. El giro en 4+5 mantiene su reserva de precisión.

## Verificación

- 64 combinaciones distintas, 58 reutilizadas y seis nuevas.
- Nueve casos nuevos exitosos, cero fallidos y cero pendientes.
- Las 175 huellas de fuente del Morris permanecen idénticas.
- Grupos históricos conservados; rama 12 excluida.
- Residuo de equilibrio máximo 9.94e−9 y QEP dual de masa máximo 4.05e−9.
- Las pruebas 17/17 del módulo y 155/155 de regresión son evidencia histórica. No se presentan como ejecutadas de nuevo.

## Figuras y reproducción

La licencia de Tecplot venció. El usuario autorizó reutilizar las figuras anteriores y generar las restantes con el mismo estilo. Las tres figuras nuevas y cuatro adaptaciones de legibilidad para diapositivas usan MATLAB R2026a, fondo blanco, escala de grises y salidas PNG/PDF vectorial. `figure_catalog.json` conserva el motor y los datos. No se atribuyen a Tecplot las exportaciones nuevas.

1. `scripts/complete_grid.m`: ejecuta/reanuda exclusivamente los nueve casos complementarios y exporta la rejilla. La carpeta rechaza reanudaciones con huellas distintas.
2. `scripts/analyze_grid.py`: verifica datos y fuentes, calcula contrastes y exporta CSV/JSON.
3. `scripts/make_figures.m`: produce gráficos desde resultados guardados, sin llamar al solver.
4. `scripts/update_documentation.py`: actualiza el mismo documento de sensibilidad y conserva un respaldo.

Resultados: `/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/grid_completion_20261014`.
Documento actualizado: `/Users/nuseche/Desktop/Tesis_codigos/docs/sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex`.
Presentación: `/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_sensibilidad_20261014/entrega`.

## Límites pendientes

La cobertura completa es discreta. No prueba extremos ni monotonicidad del dominio continuo. La convergencia espacial en operación sigue pendiente: el módulo existente permite refinamiento únicamente con rotor detenido. El análisis a azimut fijo y espectro parcial no demuestra estabilidad periódica de Floquet. Los rangos siguen siendo exploratorios y no definen una incertidumbre física probabilística. No se realizó calibración ni validación experimental.

Referencias: Morris (1991), doi:10.1080/00401706.1991.10484804. Campolongo, Cariboni y Saltelli (2007), doi:10.1016/j.envsoft.2006.10.004. Los contrastes finitos y sus filtros se definen explícitamente en esta comprobación.
'''
(D/'RESULTADOS_Y_VERIFICACION.md').write_text(report)
print('Updated existing source, equivalent fragment and complementary results report.')
