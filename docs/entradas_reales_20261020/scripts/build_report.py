"""Update the existing thesis discussion in place from verified result tables."""
from pathlib import Path
import csv
import hashlib
import json
import math

ROOT=Path('/Users/nuseche/Desktop/Tesis_codigos')
DOCS=ROOT/'docs/entradas_reales_20261020'
SOURCE=ROOT/'docs/sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex'


def rows(name): return list(csv.DictReader((DOCS/'tables'/name).open()))
def num(x): return float(x)
def flag(x): return str(x).lower() in ('1','true')
def fmt(x,n=3): return f'{float(x):.{n}f}'
def scientific_tex(x):
    mantissa,exponent=f'{float(x):.2e}'.split('e')
    return mantissa+r'\times10^{'+str(int(exponent))+'}'


def main():
    s=json.loads((DOCS/'analysis_summary.json').read_text())
    wind=json.loads((DOCS/'tables/wind_catalog.json').read_text())
    original_local=rows('local_sensitivities.csv'); local=original_local
    refined=None
    if (DOCS/'refined_tangent_summary.json').exists():
        refined=json.loads((DOCS/'refined_tangent_summary.json').read_text())
        local=rows('refined_local_sensitivities.csv')
    nominal=rows('nominal_earthquakes.csv')
    phase=rows('arrival_phase_comparison.csv'); intensity=rows('earthquake_intensities.csv')
    time=rows('time_convergence.csv')
    record_names={'ARL360':'Northridge, Arleta (1994)','CHY023-W':'Chi-Chi, CHY023-W (1999)','TCU052-N':'Chi-Chi, TCU052-N (1999)'}
    pg={x['recordFile'].split('.')[0]:num(x['pgaG']) for x in intensity}
    def response(record,name):
        return num(next(r['finePeak'] for r in nominal if r['record']==record and r['response']==name))
    nominal_lines=[]
    for record,label in record_names.items():
        q=response(record,'gondola_qH');a=response(record,'gondola_aH')
        nominal_lines.append(f'{label} & {pg[record]:.4f} & {q:.4f} & {a:.4f} & {q/pg[record]:.3f} \\\\')
    local_lines=[]
    labels={'blade_density':'Masa/inercia','blade_stiffness':'Rigidez','rotor_speed':'Velocidad'}
    for kind in ['earthquake','wind']:
        for parameter in labels:
            q=next(r for r in local if r['input']==kind and r['parameter']==parameter and r['response']=='gondola_qH_RMS')
            a=next(r for r in local if r['input']==kind and r['parameter']==parameter and r['response']=='gondola_aH_RMS')
            local_lines.append(f'{"Sismo X" if kind=="earthquake" else "Viento"} & {labels[parameter]} & {num(q["S"]):+.4f} & {"sí" if flag(q["accepted"]) else "no"} & {num(a["S"]):+.4f} & {"sí" if flag(a["accepted"]) else "no"} \\\\')
    refphase=[r for r in phase if abs(num(r['thrustOverReference'])-1)<1e-9 and r['response']=='gondola_qH']
    phase_range=[min(num(r['overEarthquakePeak']) for r in refphase),max(num(r['overEarthquakePeak']) for r in refphase)]
    q0=s['earthquakePeak'][0];a0=s['earthquakePeak'][5]
    eq_gate=[r for r in time if r['casePair']=='ARL360_fine' and r['response'] in ['gondola_qH','gondola_aH']]
    max_peak=max(num(r['relativePeakDifference']) for r in eq_gate)
    max_history=max(num(r['relativeHistoryL2']) for r in eq_gate)
    accepted=sum(flag(r['accepted']) for r in local)
    rms=[r for r in local if r['response'].endswith('_RMS')]
    accepted_rms=sum(flag(r['accepted']) for r in rms)
    accepted_peak=accepted-accepted_rms
    switches=rows('peak_time_switches.csv')
    max_switch=max(abs(num(r['peakTimeShiftSeconds'])) for r in switches)
    body=rf'''% BEGIN REAL INPUTS 20261020
\FloatBarrier
\section{{Comparación con entradas medidas: sismo y viento}}
Esta etapa extiende el estudio a historias temporales medidas. El autor autorizó utilizar registros de fuentes independientes y representar el viento mediante un empuje axial prescrito cuyo valor medio permanece como parámetro. Se cierra así una comparación estructural determinista y reproducible; el empuje medio real de la turbina y su respuesta aeroelástica acoplada siguen sin identificarse. Se conservan los resultados Morris anteriores y sus condiciones de aceptación.

\subsection{{Literatura, datos disponibles y nivel de comparación}}
Wang y colaboradores~\cite{{wang2026inputs}} publican ambas entradas de su análisis: registros sísmicos PEER y viento sintético de Davenport. Se descargaron y verificaron los archivos de su repositorio~\cite{{diao2026data}}, cuya versión comprobada contiene proyectos Origin OPJU. No se extrajeron de esos proyectos series numéricas ni se reprodujo su turbina híbrida de 160 m. Esta referencia sustenta la organización de casos, pero no acredita dos entradas de campo medidas.

Meng y colaboradores~\cite{{meng2020}} estudian experimentalmente viento y excitación de mesa sísmica, y muestran la importancia del amortiguamiento aerodinámico para combinar acciones. Turello y colaboradores~\cite{{turello2023inputs}} estudian un sismo derivado de Loma Prieta, ajustado a un espectro de diseño, y cargas calculadas con un modelo aeroelástico. Ninguno de esos tratamientos se sustituye aquí por un amortiguamiento aerodinámico supuesto.

Para las entradas medidas se seleccionaron el conjunto NM92 de DTU~\cite{{dtu2021inputs}} y acelerogramas procesados distribuidos en el repositorio oficial de OpenSees~\cite{{openseesinputs}}. El registro eólico y los sismos no ocurrieron juntos. Tampoco se comparan mediciones de respuesta de una misma turbina con predicciones: el nivel de comparación es el de \emph{{entradas transferidas al modelo existente}}, con sus hipótesis declaradas.

\subsection{{Qué se midió y cómo se preparó}}
El viento corresponde al primer archivo disponible en orden lexicográfico, fechado el 19 de noviembre de 2005 a las 00:00 según su cabecera; la zona horaria no está indicada. Se emplea el canal sónico longitudinal \texttt{{s70u}}, a 70 m de altura, con 15\,000 muestras a 25 Hz. La duración de adquisición es 600 s y la separación entre primera y última muestra es 599.96 s. Se verificaron las estadísticas contra la cabecera: media {wind['meanMps']:.4f} m/s, desviación poblacional {wind['stdPopulationMps']:.4f} m/s e intensidad longitudinal $I_u=\sigma_u/\overline U={100*wind['turbulenceIntensity']:.3f}\pct$. Es un registro seleccionado de viento relativamente uniforme; no representa por sí solo condiciones extremas.

La turbina medida es una NEG-Micon NM92 de 2.75 MW, cuyo registro indica 14.65 rpm. El escenario estructural conserva sus 12 rpm prescritas. La historia a 70 m se utiliza como sustituto temporal de un viento uniforme autorizado, sin extrapolación de altura ni afirmación de que se haya medido en el buje de este modelo. Los canales sónicos de 47 y 24 m aparecen duplicados en el archivo y no se usan para inferir un perfil espacial. Los momentos de palas, eje y torre publicados por DTU son respuestas internas medidas, no fuerzas nodales externas directamente transferibles.

Los acelerogramas conservan sus muestras, amplitudes y procesamiento de origen. El importador comprueba número de puntos, paso y unidades; convierte $g$ a m/s$^2$ mediante $g_0=9.80665$ m/s$^2$. No aplica escalamiento adicional ni corrección de línea base. Se interpolan linealmente las aceleraciones para integrar. Se emplea una componente horizontal por vez en X o Y; no se inventan componentes verticales ni se atribuye esa orientación a un emplazamiento real. No se interpretan desplazamientos absolutos del terreno obtenidos por doble integración como magnitudes validadas.

\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/entradas_medidas.pdf}}
\caption{{Historias medidas usadas como fuentes independientes. Los ejes temporales pertenecen a cada adquisición; sus amplitudes tienen unidades diferentes y no comparan directamente severidad de las acciones.}}\label{{fig:entradas-reales}}
\end{{figure}}
\FloatBarrier

\subsection{{De velocidad de viento a empuje parametrizado}}
Sea $\overline F$ el empuje medio muestral, $U_n$ las muestras originales del viento y $N=15000$. Se prescribe
\begin{{equation}}
g_w(t_n)=\frac{{U_n^2}}{{N^{{-1}}\sum_{{j=1}}^N U_j^2}},\qquad
\boldsymbol f_{{w,\mathrm{{full}}}}(t)=\overline F\,\boldsymbol b_{{\mathrm{{full}}}}\,g_w(t),
\end{{equation}}
donde $\boldsymbol b_{{\mathrm{{full}}}}$ aplica una fuerza axial unitaria en el maestro del buje 130 según el eje 129--130. Se interpola $g_w$ a partir de sus muestras originales; no se vuelve a elevar al cuadrado una velocidad ya interpolada. No se fija $C_T$, densidad del aire ni área efectiva para deducir un empuje real. La respuesta se calcula por 1 kN de $\overline F$.

Esta aproximación corresponde a un empuje impuesto proporcional a $U^2$, con forma espacial concentrada en el buje. No incorpora inducción, cargas distribuidas en las palas, arrastre de la torre, control de paso o realimentación del movimiento sobre el flujo. Tampoco es una implementación de BEM. Esas capacidades requieren información aerodinámica específica adicional.

Con los operadores congelados de cada caso mecánico, la ecuación integrada es
\begin{{equation}}
\mathsf M\ddot{{\boldsymbol q}}+\mathsf D\dot{{\boldsymbol q}}+\mathsf K\boldsymbol q
=-\mathsf P_g a_g(t-\tau)+\overline F\,\boldsymbol b\,g_w(t),
\qquad
\mathsf P_g=\mathsf T_c^T\mathsf M_{{\mathrm{{full}}}}\boldsymbol R_g,\quad
\boldsymbol b=\mathsf T_c^T\boldsymbol b_{{\mathrm{{full}}}}.
\end{{equation}}
Aquí $\boldsymbol R_g$ contiene la traslación absoluta de base y $\tau$ es el instante de llegada del sismo en el reloj del viento. La fuerza sísmica se reconstruye al cambiar la masa; no se mantiene artificialmente constante.

Para viento se adopta como condición inicial el equilibrio \emph{{lineal}} $\mathsf K\boldsymbol q_{{w,0}}=\overline F\boldsymbol b$, con velocidad perturbada nula; la aceleración inicial satisface la ecuación con el primer valor real de $g_w$. El equilibrio por gravedad y giro se recalcula para cada factor mecánico, pero los operadores no se actualizan por un empuje finito ni durante la historia. Por eso la proporcionalidad respecto de $\overline F$ describe este problema lineal congelado, no una familia completa de estados operativos aeroelásticos.

Las recuperaciones nodales conservan $\mathsf T_c$, $\dot{{\mathsf T}}_c$ y $\ddot{{\mathsf T}}_c$ de una misma instantánea. Se calculan desplazamientos relativos y aceleraciones absolutas, añadiendo a estas últimas la aceleración de base correspondiente. Mantener esos términos de transporte no hace evolucionar el azimut.

\subsection{{Contenido frecuencial y comparación sísmica}}
La figura~\ref{{fig:espectros-reales}} compara formas espectrales normalizadas a integral unitaria: aceleración del suelo y fluctuación de $g_w$. Se usa Welch con ventanas de 20 s, ventana de Hann y solape del 50\pct. La normalización permite comparar distribución de frecuencia, no iguala fuerzas, energía o peligrosidad. La estimación de viento dispone de más segmentos que la del registro de Arleta.
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/contenido_frecuencial.pdf}}
\caption{{Distribución espectral normalizada de las entradas. Las líneas verticales indican frecuencias nominales de 3, 6+7 y 10+11; la proximidad espectral no sustituye las participaciones modales ni la proyección de cargas.}}\label{{fig:espectros-reales}}
\end{{figure}}

La tabla compara los tres registros con amplitud original, aplicados en X. Corresponden a \emph{{dos terremotos}}, con dos estaciones distintas de Chi-Chi. Las duraciones completas son distintas: 39.98, 147.996 y 89.995 s. El cociente desplazamiento/PGA es una normalización diagnóstica del problema lineal, no una respuesta normalizada a un espectro de diseño común.
\begin{{center}}\small
\begin{{tabular}}{{p{{5.2cm}}rrrr}}
\toprule Registro & PGA [$g$] & $q_{{H,\max}}$ [m] & $a_{{H,\max}}^{{\mathrm{{abs}}}}$ [m/s$^2$] & $q_{{H,\max}}$/PGA [m/$g$]\\\midrule
@@NOMINAL_ROWS@@
\bottomrule\end{{tabular}}\end{{center}}
No se puede atribuir la diferencia de respuesta únicamente a la PGA: cambian espectro, duración y estación. Estos casos tampoco cuantifican la amenaza de un sitio particular.
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/respuesta_sismos_reales.pdf}}
\caption{{Máximos horizontales de góndola con cada registro completo aplicado en X, sin escalar. Se distinguen desplazamiento relativo y aceleración absoluta.}}\label{{fig:respuesta-sismos-reales}}
\end{{figure}}
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/efecto_direccion.pdf}}
\caption{{Efecto de aplicar la misma componente sísmica en X o Y. X corresponde al plano vertical que contiene el eje del rotor; Y es transversal. Esta es una comparación de orientación del escenario, no una simulación bidireccional observada.}}\label{{fig:direccion-reales}}
\end{{figure}}
\FloatBarrier

\subsection{{Qué resultados temporales son comparables}}
Se define $q_H(t)=\sqrt{{q_x^2+q_y^2}}$ en la góndola 129, y análogamente $a_H^{{\mathrm{{abs}}}}$. Los máximos describen la mayor demanda durante la ventana. Como indicador complementario se usa
\begin{{equation}}
q_{{H,\mathrm{{RMS}}}}=\left[\frac1T\int_0^T(q_x^2+q_y^2)\,dt\right]^{{1/2}},
\end{{equation}}
y expresiones equivalentes para aceleración horizontal y momento flector de base. El RMS mide magnitud cuadrática media; en viento incluye la componente media del empuje y no es la desviación de la fluctuación alrededor de la media.

Las sensibilidades mecánicas comparan los primeros 39.98 s de Arleta y del viento, manteniendo para este último la normalización con las 15000 muestras del registro completo. Se estudiaron masa/inercia de palas, sus seis rigideces y velocidad prescrita. Se recalculó el estado heredado y el conjunto de operadores en cada caso.

El análisis inicial con $h=1\pct$ y $0.5\pct$ mostró dependencia importante del paso en numerosos máximos. Se añadieron $h=0.25\pct$ y $0.125\pct$; la tabla siguiente usa $0.125\pct$ y contrasta con $0.25\pct$. También se comparan pasos temporales de 0.005 y 0.0025 s. No se confunde un máximo bien convergido en tiempo con una derivada respecto del parámetro bien resuelta.

Se acepta cada sensibilidad local únicamente si el cambio relativo al duplicar $h$ y al duplicar $\Delta t$ es como máximo del 2\pct, los controles nominales a 0.0025 y 0.00125 s difieren como máximo del 1\pct\ en máximo y norma temporal, y la señal supera diez veces el ruido de repetición observado. Esa envolvente es empírica en el nominal, no una cota rigurosa del dominio. Se aceptan {accepted} de {len(local)} indicadores locales: {accepted_peak} de máximos y {accepted_rms} de RMS. Los restantes valores se conservan como diferencias finitas exploratorias.

\begin{{center}}\small
\begin{{tabular}}{{llrrrr}}
\toprule Entrada & Factor & $S_{{q_H,\mathrm{{RMS}}}}$ & Aceptado & $S_{{a_H,\mathrm{{RMS}}}}$ & Aceptado\\\midrule
@@LOCAL_ROWS@@
\bottomrule\end{{tabular}}\end{{center}}
Un cambio en el instante que controla el máximo puede impedir que una secante amplia represente la derivada local. Se exportaron los instantes de máximos a ambos lados de cada perturbación, junto con todos los pasos. Sin embargo, la falta de estabilización aparece también en RMS: no puede explicarse solamente por cambios de pico. Con los pasos estudiados no se acepta una clasificación mecánica temporal. Esto no invalida los máximos nominales convergidos en tiempo ni modifica retrospectivamente la aceptación de frecuencias Morris.
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/refinamiento_sensibilidad.pdf}}
\caption{{Dependencia de las secantes del RMS de desplazamiento de góndola respecto de la perturbación mecánica. La ausencia de estabilización impide interpretar esas pendientes como derivadas locales resueltas.}}\label{{fig:refinamiento-temporal-reales}}
\end{{figure}}
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/sensibilidad_entradas.pdf}}
\caption{{Sensibilidades RMS de la góndola según la entrada. Los símbolos llenos superan todos los filtros locales; los vacíos no se utilizan para establecer una clasificación definitiva. La respuesta de viento es por unidad de empuje medio.}}\label{{fig:sensibilidad-entradas-reales}}
\end{{figure}}
\FloatBarrier

\subsection{{Empuje libre, superposición y momento de llegada}}
Para los mismos operadores lineales se obtiene exactamente
\begin{{equation}}
\boldsymbol q(t;\overline F,\tau)=\boldsymbol q_g(t-\tau)+
\frac{{\overline F}}{{1\ \mathrm{{kN}}}}\,\boldsymbol q_{{w,1\mathrm{{kN}}}}(t).
\end{{equation}}
La superposición se aplica a las historias, no a sus máximos separados. Se verificó además mediante una integración directa con la interfaz existente de sismo y fuerza externa completa durante 2 s. Esta identidad del problema implementado no afirma que la superposición sea exacta en un modelo aeroelástico no lineal.

Se define una escala de comparación
\begin{{equation}}
F_{{\mathrm{{ref}}}}=(1\ \mathrm{{kN}})\,
\frac{{q_{{H,\max}}^g}}{{q_{{H,\max}}^{{w,1\mathrm{{kN}}}}}}
={s['referenceMeanThrustKN']:.2f}\ \mathrm{{kN}},
\end{{equation}}
usando los primeros 39.98 s y llegada del sismo en cero. Esta escala iguala los máximos \emph{{separados}} de desplazamiento de góndola en esa ventana. No estima el empuje real, ni es un umbral de seguridad o de capacidad.

Se explora $\overline F/F_{{\mathrm{{ref}}}}$ entre 0 y 2 y 29 llegadas del sismo: $\tau=0,20,\ldots,540,559.98$ s. El último instante se ajusta al final de las muestras de viento, evitando extrapolación. El viento conserva su historia previa y cada máximo combinado usa la ventana $[\tau,\tau+39.98]$ s. No se inventa la cola sísmica después del registro ni se afirma que ese máximo sea el de los 600 s completos del escenario combinado. La franja de la figura es el mínimo y máximo de la rejilla temporal, no un intervalo de confianza.

Para $\overline F=F_{{\mathrm{{ref}}}}$, el cociente entre máximo combinado de desplazamiento y máximo sísmico varía entre {phase_range[0]:.3f} y {phase_range[1]:.3f} en las llegadas examinadas. Esa dependencia impide concluir que una de las entradas domina sin especificar empuje, dirección y ventana.
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/combinacion_y_llegada.pdf}}
\caption{{Respuesta combinada parametrizada y efecto de la llegada sísmica. La línea usa $\tau=0$; la franja cubre las 29 llegadas. El empuje continúa como parámetro libre.}}\label{{fig:combinacion-reales}}
\end{{figure}}
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/sensibilidad_combinada.pdf}}
\caption{{Sensibilidades RMS de la respuesta combinada con llegada en cero. Los símbolos llenos indican compatibilidad de los pasos de diferenciación y de tiempo; ese control parcial no equivale a la aceptación completa de una sensibilidad Morris o local.}}\label{{fig:sensibilidad-combinada-reales}}
\end{{figure}}
También se exportan sensibilidades respecto de la amplitud sísmica y del empuje medio. Para viento solo, toda respuesta homogénea no nula escala linealmente con $\overline F$, por lo que su sensibilidad normalizada es uno. En la combinación cambia la contribución relativa de cada entrada; en $\overline F=0$ la sensibilidad normalizada de ese parámetro se deja indefinida. Esto caracteriza dependencia respecto de amplitudes, no incertidumbre probabilística de los datos.
\begin{{figure}}[htbp]\centering
\includegraphics[width=.96\linewidth]{{../entradas_reales_20261020/figures/sensibilidad_amplitudes.pdf}}
\caption{{Sensibilidad de los máximos de góndola respecto de un multiplicador de amplitud sísmica y del empuje medio. Se mantienen los mismos operadores, por lo que estos indicadores de amplitud no requieren diferenciar una rigidez reconstruida. No representan porcentajes probabilísticos de contribución.}}\label{{fig:amplitudes-reales}}
\end{{figure}}
\FloatBarrier

\subsection{{Verificación y conclusiones que se pueden sostener}}
Se completaron {s['caseCount']} evaluaciones estructurales almacenadas; el residuo dinámico relativo máximo fue ${scientific_tex(s['maximumDynamicResidual'])}$. Las 175 fuentes congeladas de la campaña Morris conservan sus huellas. La recuperación por canales se contrastó con la rutina existente, con diferencias relativas menores que $5\times10^{{-11}}$. Para Arleta, los controles nominales de góndola entre 0.0025 y 0.00125 s muestran diferencias de máximo menores que {100*max_peak:.3f}\pct\ y diferencias temporales relativas menores que {100*max_history:.3f}\pct. Estos controles no certifican todas las aceleraciones de puntas.

El cierre alcanzado es una comparación con datos medidos, amplitudes trazables, orientación explícita y un empuje medio libre. Se distingue el efecto de los registros del efecto de los parámetros mecánicos; se conservan los indicadores que no superan los filtros. La clasificación modal de Morris no se traslada automáticamente a los máximos o RMS de una excitación particular.

Para convertir esta comparación en una predicción física de servicio hacen falta el empuje medio o una aerodinámica específica de la turbina, la validación de la transferencia espacial del viento y, para historias de operación, evolución de los operadores con el azimut. Permanecen pendientes la convergencia espacial en giro y la calibración experimental. La duración de los registros reales no convierte la instantánea congelada en una simulación de operación periódica.
% END REAL INPUTS 20261020
'''
    body=body.replace('@@NOMINAL_ROWS@@','\n'.join(nominal_lines)).replace('@@LOCAL_ROWS@@','\n'.join(local_lines))
    if refined:
        body=body.replace('la tabla siguiente usa $0.125\\pct$ y contrasta con $0.25\\pct$',
            'la tabla siguiente usa $0.25\\pct$ y contrasta con $0.5\\pct$, después de refinar la Hessiana interna')
        body=body.replace('Con los pasos estudiados no se acepta una clasificación mecánica temporal.',
            'Con la tangente numérica heredada no se acepta una clasificación mecánica temporal. La tabla y los símbolos de aceptación corresponden a la verificación adicional descrita previamente.')
        body=body.replace('Los símbolos llenos superan todos los filtros locales;',
            'Con la Hessiana refinada, los símbolos llenos superan todos los filtros locales;')
        body=body.replace('y la señal supera diez veces el ruido de repetición observado',
            'y la señal supera diez veces la envolvente empírica entre ambas Hessianas')
        body=body.replace('Esa envolvente es empírica en el nominal, no una cota rigurosa del dominio.',
            'Esa envolvente se estima en los extremos perturbados y no constituye una cota rigurosa del dominio.')
        paragraph=(r'\subsubsection*{Verificación adicional de la Hessiana interna}'+'\n'
            r'La rutina heredada aproxima primeras y segundas derivadas de una energía escalar con pasos internos de $2\times10^{-6}\max(L,1\ \mathrm{m})$ en traslación y $2\times10^{-6}$ rad en rotación. '
            r'Se conservó el equilibrio convergido original y se sustituyó solamente la Hessiana interna almacenada en la tangente dinámica, usando pasos internos multiplicados por 20; se contrastó con un factor 40. '
            r'La energía, las cargas y sus proyecciones no se modificaron. No se cambió ninguna de las 175 fuentes congeladas: esta opción numérica vive en el adaptador nuevo. '
            f'Se ejecutaron {refined["successfulCases"]} casos adicionales para aislar este efecto. '
            r'Además de los controles de perturbación y Newmark, se exige variación de la pendiente inferior al 2\pct\ entre factores internos 20 y 40 y variación nominal inferior al 1\pct. '
            r'La envolvente empírica de la pendiente se construye con las diferencias de cada extremo perturbado entre ambas Hessianas, no solo con repetición del nominal. '
            f'En {refined["stepConverged"]} de {len(local)} indicadores las pendientes son estables con los pasos examinados. '
            f'Se aceptan {accepted} de {len(local)} indicadores al añadir la envolvente conservadora. '
            r'Esta envolvente suma diferencias absolutas en los extremos sin cancelar el sesgo común entre discretizaciones; no es una estimación probabilística ni una cota demostrada. '
            r'Por eso una pendiente estable respecto de los pasos puede permanecer sin aceptación completa. No se utiliza este conjunto para proclamar un orden global de parámetros. '
            r'La tabla de máximos entre terremotos y la franja de llegadas conservan la configuración heredada, identificada en sus archivos; esta verificación adicional distingue la resolución de las derivadas sin sustituir retrospectivamente esas corridas ni el estudio Morris.'+'\n\n')
        anchor='Se acepta cada sensibilidad local únicamente'
        body=body.replace(anchor,paragraph+anchor,1)
        body=body.replace('../entradas_reales_20261020/figures/sensibilidad_entradas.pdf',
                          '../entradas_reales_20261020/figures/sensibilidad_refinada.pdf')
        fully=[r for r in local if flag(r['accepted'])]
        if fully:
            facts=[]
            for r in fully:
                label_response=r['response'].replace('_',r'\_')
                kind_label='viento' if r['input']=='wind' else 'sismo'
                response_label=('máximo absoluto del desplazamiento vertical relativo de la punta 92'
                                if r['response']=='punta92_qZ' else '\\texttt{'+label_response+'}')
                facts.append(f'{kind_label}, {labels[r["parameter"]]}, {response_label}, $S={num(r["S"]):+.4f}$')
            body=body.replace('Un cambio en el instante que controla el máximo',
                'Indicadores con aceptación completa: '+ '; '.join(facts)+'. No se deduce de ello un orden de parámetros para las demás respuestas.\n\nUn cambio en el instante que controla el máximo',1)
    diagnostic_path=DOCS/'tables/tangent_diagnostic.csv'
    diagnostic={}
    if diagnostic_path.exists():
        dr=list(csv.DictReader(diagnostic_path.open()));ok=[r for r in dr if r['status']=='success'];bad=[r for r in dr if r['status']!='success']
        diag_text=(f'En una comprobación numérica independiente se varió únicamente el paso de la Hessiana de energía '
                   f'en una copia de diagnóstico, mediante las interfaces existentes de fuerza y tangente. '
                   f'La energía física y las 175 fuentes originales se conservaron. Se completaron {len(ok)} '
                   f'pruebas de diagnóstico y {len(bad)} no convergieron; los fallos se conservan en la tabla correspondiente. '
                   f'No se sustituyeron con este diagnóstico los operadores de los 114 casos comparativos. ')
        diagnostic={'successful':len(ok),'failed':len(bad)}
        for field,label in [('peakQ','máximo'),('rmsQ','RMS')]:
            try:
                nominal_diag=next(r for r in ok if r['caseId']=='nominal_scale20');slopes=[]
                for h,tag in [(.005,'050'),(.0025,'025')]:
                    lo=next(r for r in ok if r['caseId']==f'mass_scale20_h{tag}_s-1')
                    hi=next(r for r in ok if r['caseId']==f'mass_scale20_h{tag}_s+1')
                    slopes.append((num(hi[field])-num(lo[field]))/(2*h*num(nominal_diag[field])))
                diagnostic[field]=slopes
                diag_text+=f'Para masa/inercia y {label} de góndola, las secantes con paso interno multiplicado por 20 fueron {slopes[0]:+.4f} y {slopes[1]:+.4f}, al usar perturbaciones de 0.5 y 0.25\\pct. '
            except StopIteration: pass
        diag_text+='La dependencia del resultado con esta decisión numérica exige verificar la tangente antes de aceptar una clasificación mecánica temporal; el residuo de equilibrio pequeño no basta por sí solo.\n'
        anchor='El cierre alcanzado es una comparación con datos medidos'
        body=body.replace(anchor,diag_text+'\n'+anchor,1)
    text=SOURCE.read_text();backup=DOCS/'source_before_20261020.txt'
    if not backup.exists():backup.write_text(text)
    start='% BEGIN REAL INPUTS 20261020';end='% END REAL INPUTS 20261020'
    if start in text:
        a=text.index(start);b=text.index(end,a)+len(end);text=text[:a]+body+text[b:]
    else:
        anchor='\\section{Estabilidad, alcance y decisiones para continuar}'
        assert anchor in text;text=text.replace(anchor,body+'\n'+anchor,1)
    text=text.replace('\\date{Morris del 6 de octubre y comprobación complementaria del 14 de octubre de 2026}',
                      '\\date{Morris y rejilla de octubre; comparación sísmica y eólica del 20 de octubre de 2026}')
    bibliography=r'''
\bibitem{wang2026inputs} W. Wang, H. Diao, H. Ma, X. Gao, B. Ji y Z. Zhang. Research on the Dynamic Response of Hybrid Tower Wind Turbines Under Combined Earthquake--Wind Multi-Hazard Conditions. \emph{Journal of Earthquake Engineering}, 2026. \href{https://doi.org/10.1080/13632469.2026.2671807}{doi:10.1080/13632469.2026.2671807}.
\bibitem{diao2026data} H. Diao. Data of Research on the Dynamic Response of Hybrid Tower Wind Turbines under Combined Earthquake--Wind Multi-Hazard Conditions. Zenodo, versión consultada 19347779, 2026. \href{https://doi.org/10.5281/zenodo.19347779}{doi:10.5281/zenodo.19347779}.
\bibitem{meng2020} J. Meng, K. Dai, Z. Zhao, Z. Mao, A. Camara, S. Zhang y Z. Mei. Study on the aerodynamic damping for the seismic analysis of wind turbines in operation. \emph{Renewable Energy}, 159, 1224--1242, 2020. \href{https://doi.org/10.1016/j.renene.2020.05.181}{doi:10.1016/j.renene.2020.05.181}.
\bibitem{turello2023inputs} D. F. Turello, M. S. Maza, S. Preidikman, F. G. Flores y F. Pinto. Interacción suelo-estructura no-lineal en el modelado de torres eólicas de eje horizontal ante carga sísmica. \emph{Mecánica Computacional}, XL, 639--650, 2023. \url{https://cimec.org.ar/ojs/index.php/mc/article/view/6595}.
\bibitem{dtu2021inputs} K. S. Hansen, N. Vasiljevic y S. A. Sørensen. Turbulence and turbine measurements from the NM92 turbine. DTU Data, 2021. \href{https://doi.org/10.11583/DTU.16743739}{doi:10.11583/DTU.16743739}. Datos CC BY 4.0.
\bibitem{openseesinputs} OpenSees. Repositorio oficial: registros PEER procesados en \texttt{EXAMPLES/ExampleScripts} y \texttt{Workshops/SimWorkshop/SmallMP/GM}. \url{https://github.com/OpenSees/OpenSees}. La revisión exacta, rutas y SHA-256 se conservan en el catálogo de entradas del proyecto.
'''
    if '\\bibitem{wang2026inputs}' not in text:text=text.replace('\\end{thebibliography}',bibliography+'\n\\end{thebibliography}')
    SOURCE.write_text(text)
    presentation_conclusions=[
        f'Arleta sin escalar: {q0:.3f} m de desplazamiento horizontal máximo en X',
        f'Con F̄ = Fref, el cociente combinado/sismo varía de {phase_range[0]:.2f} a {phase_range[1]:.2f} entre llegadas',
        (f'{refined["stepConverged"]} pendientes estables; solo {accepted} de {len(local)} supera el filtro conservador' if refined else f'{accepted} de {len(local)} sensibilidades locales superan los filtros'),
        ('Único aceptado con viento: giro → máximo vertical relativo de punta 92 (S = −0,5004)' if refined and accepted==1 else 'El empuje medio sigue libre: la comparación no fija una demanda real de servicio')
    ]
    values=dict(earthquakeDisplacementM=q0,earthquakeAccelerationMps2=a0,
        phaseRangeAtReference=phase_range,acceptedLocal=accepted,acceptedRMS=accepted_rms,
        acceptedPeaks=accepted_peak,totalLocal=len(local),maxPeakTimeSwitchSeconds=max_switch,
        nominalMaxPeakRelativeDifference=max_peak,nominalMaxHistoryRelativeDifference=max_history,
        presentationConclusions=presentation_conclusions,tangentDiagnostic=diagnostic,refinedTangent=refined,
        sourceSha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest())
    (DOCS/'report_values.json').write_text(json.dumps(values,ensure_ascii=False,indent=2))
    readme=f'''# Comparación sísmica y eólica con entradas medidas

Fecha de trabajo: 20 de octubre de 2026 (America/Bogota).

Se completaron {s['caseCount']} evaluaciones estructurales. Se conserva la formulación heredada y las 175 fuentes congeladas. El estudio compara registros sísmicos procesados sin escalar y viento medido por DTU como fuentes independientes. El autor autorizó un empuje axial proporcional a U², con media libre.

## Resultados y alcance

- Arleta global X: máximo horizontal de góndola {q0:.6f} m y aceleración absoluta horizontal {a0:.6f} m/s².
- El viento produce un coeficiente de respuesta por 1 kN medio. Fref = {s['referenceMeanThrustKN']:.6f} kN iguala los máximos separados de góndola en los primeros 39,98 s; es una escala matemática de comparación, sin valor calibrado ni límite de seguridad.
- Para Fmedia = Fref, máximo combinado / máximo sísmico entre {phase_range[0]:.6f} y {phase_range[1]:.6f}, entre 29 llegadas. La franja no es probabilística.
- {accepted}/{len(local)} sensibilidades locales aceptadas ({accepted_peak} máximos y {accepted_rms} RMS). Las tablas incluyen resultados rechazados y todos los pasos. La verificación temporal del máximo no garantiza convergencia de la derivada paramétrica.
- Operadores congelados, giro prescrito de 12 rpm y sin retroalimentación aerodinámica. La media eólica se equilibra con K del problema lineal, sin recalcular un equilibrio no lineal por empuje finito.
- RMS incluye la media del incremento eólico. El estudio no asigna distribuciones de incertidumbre ni calibra un sitio real.

## Fuentes primarias

1. [Wang et al. (2026)](https://doi.org/10.1080/13632469.2026.2671807), sismo PEER + viento sintético Davenport. Datos disponibles en [Zenodo, versión 19347779](https://doi.org/10.5281/zenodo.19347779). Ambos RAR descargados se verificaron con MD5 del repositorio; archivos OPJU, no series importadas a este estudio.
2. [Meng et al. (2020)](https://doi.org/10.1016/j.renene.2020.05.181), referencia experimental para amortiguamiento aerodinámico y combinación. PDF de manuscrito aceptado guardado sin modificación.
3. [DTU NM92](https://doi.org/10.11583/DTU.16743739), Hansen, Vasiljevic y Sørensen (2021), CC BY 4.0. Canal s70u, 70 m, 15000 muestras a 25 Hz, 2005-11-19. La turbina medida no es el modelo de tesis.
4. [OpenSees](https://github.com/OpenSees/OpenSees), fuente primaria de distribución de registros PEER procesados. Commit exacto, rutas y hashes en sources/earthquake_provenance.json. Tres registros cuantitativos de dos terremotos; el El Centro docente descargado se conserva solo como auxiliar y no se usa en los resultados.
5. [Turello et al. (2023)](https://cimec.org.ar/ojs/index.php/mc/article/view/6595), referencia del proyecto con sismo ajustado y cargas aeroelásticas. No se atribuyen esas entradas al caso DTU.

## Reproducción

1. `scripts/fetch_inputs.py`: descarga parcial del ZIP de DTU (sin descargar 7,19 GB completos), CRC32 del miembro y SHA-256. Los metadatos y el archivo original extraído se conservan en sources/.
2. `scripts/prepare_earthquakes.py` y `scripts/prepare_wind.py`: importación, unidades y comprobación de cabeceras.
3. MATLAB: ejecutar run_comparison.m, run_aligned.m y refine_local_steps.m. Las campañas reanudan archivos existentes. El refinamiento local responde a controles fallidos de h; el presupuesto operativo acumulado se registra en refinement_budget.mat.
4. MATLAB: analyze_comparison.m, verify_combination.m y make_figures.m. El análisis usa X para la comparación alineada y conserva Y como contraste.
5. Python: build_report.py actualiza exclusivamente el bloque nuevo del documento existente. Se guarda respaldo previo. No sincroniza automáticamente otros archivos LaTeX que ya difieren.

## Entregables y verificación

- Documento actualizado en ../sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex y su PDF del proyecto.
- Tablas: nominal_earthquakes, time_convergence, local_sensitivities, differentiation_refinement, peak_time_switches, combined_sensitivities, input_amplitude_sensitivities, arrival_phase_comparison y direction_comparison.
- Comprobación directa de carga combinada en combined_load_verification.json; recuperación y chunking en runs/.../recovery_verification.json.
- Figuras MATLAB R2026a, blanco y negro, PNG a 300 dpi y PDF vectorial. La licencia Tecplot sigue sin renovación; se aplica la alternativa expresamente autorizada.
- Fuentes congeladas comprobadas en source_integrity.json; catálogo y huellas de entrega en delivery_audit.json.

El cierre físico con una demanda eólica de servicio requiere identificar el empuje medio o desarrollar una aerodinámica específica. El cierre periódico requiere evolución del azimut. Esos trabajos no se presentan como ejecutados.
'''
    if refined:
        readme+='\n## Verificación adicional de la tangente\n\n'
        readme+=f'La configuración heredada no resolvió las pendientes mecánicas. Se conservaron sus 114 casos y sus rechazos. Se añadieron {refined["successfulCases"]} casos con la misma energía y equilibrio original, refinando solo la Hessiana dinámica con factores internos 20 y 40. En esta configuración se aceptan {accepted}/{len(local)} indicadores. No cambió ninguna fuente congelada.\n\n'
        readme+='Reproducir con run_refined_tangent.m y analyze_refined_tangent.m; sus archivos viven en runs/.../refined_tangent. make_refined_figure.m genera el gráfico nuevo. Las tablas de comparación entre terremotos y llegadas conservan la configuración heredada y su trazabilidad.\n'
    (DOCS/'LEEME.md').write_text(readme)
    print(json.dumps(values,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
