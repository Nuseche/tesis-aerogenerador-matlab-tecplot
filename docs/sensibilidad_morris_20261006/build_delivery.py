"""Write the scientific discussion and LaTeX from the exported actual results."""
import csv
import json
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--replace-latex", action="store_true", help="Replace existing LaTeX with the original, unillustrated report template.")
args = parser.parse_args()

DOCS = Path(__file__).resolve().parent
ROOT = DOCS.parents[1]
RUNS = ROOT / "runs/sensitivity/morris_20261006"
data = json.loads((DOCS / "report_data.json").read_text())
stats = data["statistics"]
if isinstance(stats, dict):
    stats = [stats]
frequency = [r for r in stats if r["response"] == "frequency"]
accepted = [r for r in frequency if r["acceptedMean"]]
dispersion = [r for r in frequency if r["acceptedDispersion"]]
names = {"blade_density": "densidad de palas", "blade_stiffness": "rigidez de palas", "rotor_speed": "velocidad del rotor"}


def num(value, digits=5):
    return "no resuelto" if value is None else f"{value:.{digits}g}"


def texnum(value):
    mantissa, exponent = f"{value:.2e}".split("e")
    return mantissa + r"\times 10^{" + str(int(exponent)) + "}"


table = "| Parámetro | Grupo | μ | μ* | σ | Cambio μ* 20→40 | Aceptación de μ* |\n|---|---|---:|---:|---:|---:|---|\n"
for r in frequency:
    change = "—" if r["muStarRelativeChange"] is None else f'{100*r["muStarRelativeChange"]:.2f} %'
    table += f'| {names[r["parameter"]]} | {r["group"]} | {num(r["mu"])} | {num(r["muStar"])} | {num(r["sigma"])} | {change} | {"sí" if r["acceptedMean"] else "no"} |\n'
decisions = []
for group in dict.fromkeys(r["group"] for r in accepted):
    rows = [r for r in accepted if r["group"] == group]
    ordered = sorted(rows, key=lambda r: r["muStar"], reverse=True)
    details = "; ".join(f'{names[r["parameter"]]}: μ*={num(r["muStar"])}, μ={num(r["mu"])}' for r in ordered)
    decisions.append(f"Para el grupo {group}, los indicadores aceptados son {details}.")
observations = "\n\n".join(decisions) or "Ningún indicador de frecuencia superó simultáneamente los controles de seguimiento, ruido y estabilización. No se publica una clasificación de influencia."
spin_positive = [r["group"] for r in accepted if r["parameter"] == "rotor_speed" and r["mu"] > 0]
spin_negative = [r["group"] for r in accepted if r["parameter"] == "rotor_speed" and r["mu"] < 0]
spin_note = ""
if spin_positive and spin_negative:
    spin_note = ("La velocidad presenta signos medios opuestos: positivos en los grupos " + ", ".join(spin_positive) +
                 " y negativos en " + ", ".join(spin_negative) + ". Por tanto, el incremento de velocidad no eleva todas las frecuencias seleccionadas. "
                 "La ecuación cuadrática contiene simultáneamente operadores giroscópicos, transporte y cambios de la tangente en equilibrio; "
                 "el signo depende del grupo. Atribuirlo exclusivamente a una rigidez adicional positiva omitiría esa competencia. "
                 "Separar cuantitativamente las contribuciones exigiría un estudio diagnóstico adicional, sin alterar la formulación final.")
chords = {r["parameter"]: r["mu"] / 0.20 for r in accepted if r["group"] == "10+11"}
chord_note = ""
if len(chords) == 3:
    chord_note = ("Para el grupo 10–11, al dividir μ entre el ancho 0.20 de cada factor se obtienen pendientes medias de secante "
                  "normalizadas por la frecuencia nominal: " +
                  ", ".join(f"{names[p]} {v:+.4f}" for p, v in chords.items()) +
                  ". Son coherentes con los signos y magnitudes del estudio local. Estas secantes atraviesan pasos de 0.13333 "
                  "del factor y no reemplazan sus derivadas infinitesimales. Resolver una influencia en este dominio más amplio "
                  "no convierte automáticamente en aceptada una derivada local antes rechazada.")

elapsed = data["solverSeconds"] / 60
failed = data["failedCaseIds"] or []
if isinstance(failed, str):
    failed = [failed]
report = f"""# Resultados de la segunda etapa: Morris exploratorio

**Fecha:** 6 de octubre de 2026. **Autorización:** el autor aprobó los escenarios de ±10 % y un presupuesto de 30 minutos. La primera etapa se conserva en `docs/sensibilidad_20261005`; esta entrega tiene configuración, huellas y resultados propios.

## Ejecución y alcance

Se completaron {data['completedTrajectories']} trayectorias de las 40 previstas. Se guardaron {data['savedSuccessCases']} evaluaciones satisfactorias, incluidos diez controles, y {len(failed)} fallos de modelo. El tiempo acumulado de las evaluaciones fue {elapsed:.2f} minutos; esto no incluye preparación ni postprocesamiento. Estado de la campaña: completada={data['completed']}, detenida por presupuesto={data['budgetStopped']}. La semilla del diseño es {data['seed']}.

Los factores de masa e inercias de las palas, rigidez seccional de las palas y velocidad del rotor se muestrearon en [0.90,1.10]. La velocidad equivale a 10.8–13.2 rpm. El dominio es un conjunto de escenarios mecánicos aprobado; no constituye incertidumbre experimental ni una distribución física conjunta. Las dependencias masa–inercia y entre las seis rigideces seccionales permanecen consistentes, con geometría fija.

Para el grupo 10–11 se conservaron {data['uniqueTrackedGroup10Combinations']} combinaciones distintas entre los vértices válidos; se mantienen las evaluaciones repetidas como evidencia de reproducibilidad. La máxima diferencia de frecuencia entre repeticiones de la misma combinación fue {data['maximumRepeatedGroup10FrequencySpreadHz']:.4g} Hz.

La integración usa las rutinas físicas existentes y vuelve a calcular el equilibrio. Las respuestas son centroides de grupos o ramas aisladas bajo la convención exp(λt): frecuencia |Im λ|/(2π), crecimiento Re λ y amortiguamiento −Re λ/|λ|. El espectro es parcial y el azimut está congelado; las conclusiones no describen estabilidad de Floquet. Esta campaña global se limita a los indicadores modales.

## Estimadores y controles

Cada trayectoria tiene cuatro puntos y tres aristas, una por factor, sobre una malla de cuatro niveles. En la coordenada x∈[0,1], el factor es ξ=0.90+0.20x; el paso firmado tiene magnitud 2/3, equivalente a 0.13333 del factor. Se guarda cada efecto EE=(y_fin−y_inicio)/(Δx s_y), con escala fija nominal. μ es su media firmada, μ* su media absoluta y σ su desviación estándar muestral. Son adimensionales después del escalamiento. μ* no es un porcentaje máximo de variación de la respuesta ni un índice de Sobol.

Los prefijos de 10, 20 y 40 pertenecen al mismo diseño. El agrupamiento usa la unión de proximidades de TODOS los puntos observados para mantener la misma definición de respuesta entre prefijos. Se exigen grupos cerrados, correlación con el nominal y correlación entre extremos. No se omiten efectos inválidos al promediar. La envolvente de ruido se obtiene en el nominal y dos esquinas, con repetición, QEP estricto y continuación; sigue siendo empírica y no una cota rigurosa de todo el dominio.

La media absoluta debe superar diez veces su envolvente propagada y cambiar como máximo un 10 % entre los dos últimos prefijos para aceptarse. La dispersión tiene su propio control de ruido y estabilización. La convergencia de prefijos es un diagnóstico finito, no una garantía asintótica.

## Evidencia numérica

El máximo residuo de equilibrio fue {data['maximumEquilibriumResidual']:.4g}; los máximos residuos derechos e izquierdos del QEP fueron {data['maximumRightQEPResidual']:.4g} y {data['maximumLeftQEPResidual']:.4g}. En norma dual de masa, que combina fuerzas y momentos de manera compatible con unidades, el máximo fue {data['maximumDualMassQEPResidual']:.4g}. Estas medidas no son por sí solas cotas de error de autovalores. Las {data['modulePassed']} pruebas del módulo pasaron, con {data['moduleFailed']} fallos. La regresión anterior de 155 pruebas se conserva; no se presenta como una nueva ejecución de esa suite.

La mayor parte real de las raíces calculadas fue {data['largestGrowthComputedPerSecond']:.5g} s⁻¹. Este dato solo se refiere al subconjunto de autovalores efectivamente calculado y no basta para concluir estabilidad del sistema periódico completo.

## Frecuencias: resultados e interpretación

Se aceptaron {len(accepted)} indicadores de media absoluta de frecuencia. La tabla conserva también estimadores rechazados para distinguir falta de resolución, seguimiento incompleto y estabilización insuficiente. Los CSV incluyen cada bandera por separado.

{table}

{observations}

{spin_note}

{chord_note}

El signo de μ informa la dirección media del cambio en las aristas muestreadas; no demuestra monotonicidad de todo el continuo. μ* permite comparar factores con el mismo ancho relativo, únicamente dentro de cada respuesta y dominio. Los intervalos observados por grupo están en `morris_frequency_ranges.csv`; se calculan con vértices cuyo seguimiento es válido.

Los mecanismos son consistentes con el análisis local: la escala de masa modifica la inercia traslacional y rotacional, el peso y las contribuciones asociadas al giro; por ello su efecto total incluye el cambio del equilibrio. La escala de rigidez modifica conjuntamente EA, GAy, GAz, GJ, EIy y EIz. La velocidad modifica términos proporcionales a Ω y Ω², el equilibrio y las derivadas de las restricciones y de MBC. El predominio de las palas en los modos altos seleccionados está respaldado por las participaciones cuadráticas de referencia de la primera etapa; esas participaciones no son una partición de toda la energía del sistema en rotación.

No se extiende la compensación local masa–rigidez a todo el dominio como una identidad. Una media firmada similar y de signo opuesto puede motivar estudiar curvas de compensación; confirmar esas curvas exigiría evaluar directamente combinaciones seleccionadas.

## Dispersión, interacción y límites

Se aceptaron {len(dispersion)} indicadores de dispersión de frecuencia. σ reúne variación del efecto elemental con la posición en el dominio y puede deberse a no linealidad o interacción. Morris no separa esas causas. Una dispersión no resuelta no demuestra ausencia de interacción. La interacción central local anterior, a ±1 %, permanece una evidencia diferente con su propio piso numérico.

Los indicadores de crecimiento y amortiguamiento se exportan en los mismos archivos, con escala fija; no se convierten sus centroides en una clasificación de estabilidad de cada raíz. La truncación espectral, cambios de grupo, el piso del equilibrio y la envolvente empírica limitan las conclusiones. El refinamiento espacial anterior corresponde al rotor detenido; no demuestra convergencia espacial de las sensibilidades globales en rotación. No se ejecutaron trayectorias adicionales, simulaciones sísmicas globales, Sobol ni cambios en hipótesis físicas.

## Reproducción y archivos

Código: `+sensitivity/config_morris.m`, `morris_design.m`, `morris_statistics.m`, `summarize_morris.m` y `run_morris_study.m`. Caso: `cases/config_sensitivity_morris_approved.m`. Los escenarios crudos están en `{RUNS}`. `campaign.mat/json` contiene la configuración completa, el diseño y la huella de código/datos/MATLAB. Cada evaluación conserva estado, operadores, factores, opciones, convergencia y error si corresponde. La reanudación exige la misma versión y configuración.

Las tablas principales son `morris_elementary_effects.csv`, `morris_estimators.csv`, `morris_tracking.csv`, `morris_noise.csv`, `morris_residuals.csv` y `morris_frequency_ranges.csv`. Los checkpoints `morris_summary_r10/20/40.mat` conservan la evolución del postprocesamiento; la comparación final recalcula los prefijos con grupos uniformes en el dominio observado. Las figuras PNG y PDF vectoriales están en `figures`.

Referencia primaria del diseño: Morris (1991), [DOI 10.1080/00401706.1991.10484804](https://doi.org/10.1080/00401706.1991.10484804). La evidencia específica, los escalados y los controles de aceptación proceden de esta implementación y de sus resultados guardados.
"""
(DOCS / "RESULTADOS_Y_DISCUSION.md").write_text(report, encoding="utf-8")

latex_rows = []
for r in accepted:
    latex_rows.append(f"{names[r['parameter']]} & {r['group']} & {r['mu']:.5f} & {r['muStar']:.5f} & {r['sigma']:.5f} " + r"\\")
if not latex_rows:
    latex_rows.append(r"\multicolumn{5}{c}{Ningún indicador de media aceptado}\\")
tex = r"""\documentclass[11pt,a4paper]{article}
\usepackage[spanish]{babel}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[margin=2.3cm]{geometry}
\usepackage{amsmath,amssymb,booktabs,array}
\usepackage{hyperref}
\title{Sensibilidad global exploratoria mediante Morris}
\author{Sección para revisión antes de incorporar al manuscrito}
\date{6 de octubre de 2026}
\begin{document}
\maketitle
\section{Dominio y alcance físico}
El autor aprobó factores entre 0.90 y 1.10 para masa e inercias de palas, rigideces seccionales de palas y velocidad prescrita del rotor. Se denotan estos factores por $\xi_\rho$, $\xi_K$ y $\xi_\Omega$, respectivamente. El nominal es uno; la velocidad nominal $\Omega_0$ corresponde a 12 rpm, y el dominio es 10.8--13.2 rpm. Son escenarios exploratorios; no intervalos medidos ni distribuciones de fabricación. Se escalan de manera consistente masa e inercias a geometría fija, y las seis rigideces seccionales se modifican conjuntamente.

Cada escenario reconstruye los operadores y su equilibrio. Se conserva la formulación de septiembre: contribuciones inerciales y giroscópicas asociadas a la rotación, restricciones móviles y sus derivadas, y transformación a coordenadas de palas homólogas. El giro es constante por evaluación, sin guiñada nominal. El azimut está congelado y el espectro es parcial; el estudio no calcula estabilidad periódica de Floquet.

\section{Diseño, indicadores y verificación}
Sea $x_i\in[0,1]$ la coordenada del factor $i$; se aplica $\xi_i=0.90+0.20x_i$. Se generan cuarenta trayectorias aleatorias de Morris en una malla de cuatro niveles, con incremento firmado $\Delta x_i$ de magnitud $2/3$ y semilla 6706 \cite{morris1991}. Cada trayectoria tiene cuatro vértices y una arista por factor. Se comparan los prefijos contenidos de diez, veinte y cuarenta trayectorias.

Sea $\lambda$ una raíz del problema cuadrático con convención $\exp(\lambda t)$, donde $t$ es tiempo. Se definen frecuencia amortiguada $f_d=|\operatorname{Im}\lambda|/(2\pi)$, crecimiento $\gamma=\operatorname{Re}\lambda$ y razón de amortiguamiento $\zeta=-\operatorname{Re}\lambda/|\lambda|$. Las respuestas $y$ son centroides de grupos cerrados o ramas aisladas. La agrupación usa la unión de proximidades en todo el dominio observado y mantiene la misma respuesta entre prefijos. Se verifica correlación compleja de formas con el nominal y entre extremos de cada arista; se excluyen grupos que tocan el corte espectral.

Sea $s_y$ una escala nominal fija: la frecuencia nominal para $f_d$, la media nominal de $|\lambda|$ para $\gamma$, y $\max(|\zeta_0|,0.01)$ para $\zeta$. El efecto elemental adimensional es
\begin{equation}
 EE_i=\frac{y_{\rm fin}-y_{\rm inicio}}{\Delta x_i s_y}.
\end{equation}
Para $r$ trayectorias se calculan la media firmada $\mu_i$, la media absoluta $\mu_i^*$ y la desviación estándar muestral $\sigma_i$ de estos efectos. Se conservan todos los efectos; un fallo de seguimiento impide calcular el estimador del prefijo y no se corrige eliminando selectivamente aristas.

Se incluyen diez controles en el nominal y dos esquinas: repetición, tolerancia del autoproblema más estricta y comparación entre solución directa y continuación. Sea $\eta$ la máxima diferencia observada de una respuesta. Se asigna a cada efecto la envolvente empírica $b=2\eta/(|\Delta x_i|s_y)$. La envolvente de las medias es $\overline b$ y la de la desviación es $[\sum b_j^2/(r-1)]^{1/2}$. No son cotas rigurosas del error en todo el dominio.

Se acepta influencia media si $\mu_i^*\geq10\overline b$ y cambia como máximo 10\text{\char37} entre los prefijos de veinte y cuarenta. La dispersión tiene un control independiente de ruido y estabilización al 10\text{\char37}. El presupuesto aprobado es treinta minutos, con conservación explícita de casos pendientes si se agota.

\section{Resultados observados}
"""
tex += f"Se completaron {data['completedTrajectories']} trayectorias y {data['savedSuccessCases']} evaluaciones satisfactorias, con {len(failed)} fallos de modelo. El tiempo acumulado de evaluación fue {elapsed:.2f} minutos. Pasaron {data['modulePassed']} pruebas del módulo. Los máximos residuos de equilibrio y QEP en norma dual de masa fueron ${texnum(data['maximumEquilibriumResidual'])}$ y ${texnum(data['maximumDualMassQEPResidual'])}$, respectivamente.\n\n"
tex += f"Se aceptaron {len(accepted)} indicadores de influencia media de frecuencia. La tabla contiene exclusivamente estos indicadores; los estimadores rechazados y sus banderas se conservan en los archivos de resultados.\n"
tex += r"""\begin{center}
\small
\begin{tabular}{p{3.4cm}lrrr}
\toprule Parámetro & Grupo & $\mu$ & $\mu^*$ & $\sigma$ \\ \midrule
""" + "\n".join(latex_rows) + r"""
\bottomrule
\end{tabular}
\end{center}
El signo de $\mu$ describe una dirección media en las aristas muestreadas; no demuestra monotonicidad del continuo. $\mu^*$ permite comparar factores de igual ancho dentro de una respuesta, pero no es un porcentaje máximo de variación ni un índice de Sobol.

\section{Mecanismos y límites de interpretación}
La escala de masa modifica inercia traslacional y rotacional, peso y contribuciones asociadas al giro; su efecto total incluye el cambio del equilibrio. La escala de rigidez modifica conjuntamente las rigideces axial, de cortante, torsional y de flexión. La velocidad modifica términos proporcionales a $\Omega$ y $\Omega^2$, equilibrio y derivadas de las restricciones y de la transformación modal. Las participaciones cuadráticas nominales de palas de la primera etapa respaldan la interpretación de los grupos asociados, pero no constituyen una partición de toda la energía en rotación.

"""
tex += spin_note + "\n\n"
tex += f"Se aceptaron {len(dispersion)} indicadores de dispersión de frecuencia. "
tex += r"""La dispersión puede reunir no linealidad e interacción; Morris no separa sus causas. Una dispersión no resuelta no demuestra ausencia de interacción. Tampoco se extiende la compensación local masa--rigidez a todo el dominio como identidad.

Las respuestas de crecimiento y amortiguamiento se guardan con escalas fijas; los centroides no reemplazan el examen de estabilidad de cada raíz. El agrupamiento, la truncación espectral, el piso del equilibrio y el carácter empírico de la envolvente limitan las conclusiones. La verificación espacial previa con rotor detenido no demuestra convergencia espacial de las sensibilidades globales en rotación. No se ejecuta sensibilidad sísmica global ni se atribuye validación experimental al estudio.

\begin{thebibliography}{9}
\bibitem{morris1991} M. D. Morris. Factorial Sampling Plans for Preliminary Computational Experiments. \emph{Technometrics}, 33(2), 161--174, 1991. \href{https://doi.org/10.1080/00401706.1991.10484804}{doi:10.1080/00401706.1991.10484804}.
\end{thebibliography}
\end{document}
"""
fragment = tex.split(r"\section{Dominio", 1)[1].split(r"\begin{thebibliography}", 1)[0]
latex_outputs = {
    "SECCION_MORRIS_REVISION.tex": tex,
    "seccion_para_incorporar.tex": "% Requiere revisar e integrar la referencia morris1991.\n" + r"\section{Dominio" + fragment,
}
for filename, content in latex_outputs.items():
    destination = DOCS / filename
    if not destination.exists() or args.replace_latex:
        destination.write_text(content, encoding="utf-8")
    else:
        print(f"Preserved existing LaTeX: {filename}")
print(f"Report generated: {len(accepted)} accepted mean indicators, {len(dispersion)} accepted dispersion indicators.")
