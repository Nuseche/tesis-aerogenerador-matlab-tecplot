"""Expand the existing editor source with inline vector figures from stored data."""
import csv
import hashlib
import json
from pathlib import Path

REV = Path(__file__).resolve().parent
DOCS = REV.parent
ROOT = DOCS.parents[1]
RUNS = ROOT / 'runs/sensitivity/morris_20261006'
meta = json.loads((DOCS / 'report_data.json').read_text())
rows = meta['statistics']
freq = {(r['parameter'], r['group']): r for r in rows if r['response'] == 'frequency'}
parameters = ['blade_density', 'blade_stiffness', 'rotor_speed']
param_labels = ['Masa e inercia de palas', 'Rigidez de palas', 'Velocidad del rotor']
colors = ['massblue', 'stiffgreen', 'speedorange']
groups = ['3', '4+5', '6+7', '8+9', '10+11']
accepted = [r for r in freq.values() if r['acceptedMean']]
max_change = max(r['muStarRelativeChange'] for r in accepted)
nominal = {r['group']: r['nominalFrequencyHz'] for r in meta['groups']}
energy = {r['mode']: r for r in csv.DictReader((ROOT / 'runs/sensitivity/initial_20261005/local/modal_energy_evidence.csv').open())}
estimators = list(csv.DictReader((RUNS / 'morris_estimators.csv').open()))
sweeps = list(csv.DictReader((RUNS / 'morris_sweeps.csv').open()))


def pct(v, digits=2):
    return f'{100*v:.{digits}f}' + r'\,\pct'


def plot(coords, style):
    return r'\addplot[' + style + '] coordinates {' + ' '.join(f'({x},{y:.9g})' for x, y in coords) + '};\n'


fig_signed = r'''\begin{figure}[!htbp]
\centering
'''
for p, name in enumerate(parameters):
    fig_signed += r'\begin{minipage}{0.32\linewidth}\centering' + '\n' + r'\begin{tikzpicture}\begin{axis}[width=\linewidth,height=5.1cm,title={' + param_labels[p] + r'''},title style={font=\small},xmin=0.4,xmax=5.6,ymin=-0.65,ymax=0.5,xtick={1,2,3,4,5},xticklabels={3,4+5,6+7,8+9,10+11},xticklabel style={rotate=35,anchor=east,font=\scriptsize},ytick={-0.6,-0.3,0,0.3},xlabel={Grupo},ylabel={$\overline c_i$},grid=major,grid style={gray!20},tick label style={font=\scriptsize},label style={font=\small}]
'''
    ok, bad = [], []
    for j, g in enumerate(groups, 1):
        r = freq[name, g]
        (ok if r['acceptedMean'] else bad).append((j, r['mu']/0.20))
    fig_signed += plot(ok, f'ybar,bar width=10pt,fill={colors[p]},draw={colors[p]}')
    if bad:
        fig_signed += plot(bad, 'ybar,bar width=10pt,fill=gray!40,draw=gray!70')
    fig_signed += plot([(0.4, 0), (5.6, 0)], 'black,thin,no marks')
    fig_signed += r'\end{axis}\end{tikzpicture}\end{minipage}' + '\n'
fig_signed += r'''\caption{Dirección y magnitud media de las secantes normalizadas: $\overline c_i=\mu_i/0.20$. Una barra negativa indica disminución media de frecuencia al aumentar el factor. Gris: velocidad en el grupo 4+5, cuyo estimador no supera el ruido. Los grupos se siguen por sus formas; las barras no corresponden a posiciones reordenadas en cada caso.}
\label{fig:sentidos}
\end{figure}
'''

fig_conv = r'\begin{figure}[!htbp]\centering' + '\n'
for g in ['6+7', '10+11']:
    fig_conv += r'\begin{minipage}{0.48\linewidth}\centering\begin{tikzpicture}\begin{axis}[width=\linewidth,height=5.3cm,title={Grupo ' + g + r'''},xlabel={Trayectorias},ylabel={$\mu_i^*$},xtick={10,20,40},xmin=8,xmax=42,grid=major,grid style={gray!20},tick label style={font=\small},label style={font=\small},legend style={font=\scriptsize,at={(0.5,-0.27)},anchor=north,legend columns=1}]
'''
    for p, name in enumerate(parameters):
        selected = sorted([r for r in estimators if r['parameter'] == name and r['group'] == g and r['response'] == 'frequency'], key=lambda r: int(r['trajectories']))
        fig_conv += plot([(int(r['trajectories']), float(r['muStar'])) for r in selected], f'{colors[p]},thick,mark=*')
        fig_conv += r'\addlegendentry{' + ['Masa/inercia', 'Rigidez', 'Velocidad'][p] + '}\n'
    fig_conv += r'\end{axis}\end{tikzpicture}\end{minipage}' + '\n'
fig_conv += r'''\caption{Estabilización de dos respuestas representativas con prefijos del mismo diseño. El agrupamiento final se conserva al recalcular 10, 20 y 40 trayectorias. Las curvas casi horizontales apoyan la estabilidad del cribado en esta muestra; no prueban convergencia asintótica.}
\label{fig:convergencia}
\end{figure}
'''

fig_disp = r'''\begin{figure}[!htbp]\centering
\begin{tikzpicture}\begin{axis}[width=0.84\linewidth,height=6cm,xlabel={$\mu_i^*$},ylabel={$10^3\sigma_i$},xmin=0.03,xmax=0.085,ymin=1.1,ymax=5.1,grid=major,grid style={gray!20}]
'''
for p, name in enumerate(parameters):
    r = freq[name, '10+11']
    face = colors[p] if r['acceptedDispersion'] else 'white'
    fig_disp += plot([(r['muStar'], 1000*r['sigma'])], f'only marks,mark=*,mark size=3pt,draw={colors[p]},fill={face},mark options={{draw={colors[p]},fill={face}}}')
    anchor = 'east' if p < 2 else 'west'
    offset = -0.0008 if p < 2 else 0.0008
    fig_disp += r'\node[anchor=' + anchor + r',font=\small] at (axis cs:' + f'{r["muStar"]+offset:.9g},{1000*r["sigma"]:.9g}' + ') {' + ['Masa/inercia', 'Rigidez', 'Velocidad'][p] + '};\n'
fig_disp += r'''\end{axis}\end{tikzpicture}
\caption{Influencia y dispersión de efectos elementales en el grupo 10+11. Los puntos llenos superan los controles de ruido y estabilización de $\sigma_i$; el punto vacío no. El eje vertical está multiplicado por $10^3$. Esta dispersión describe los efectos elementales, no una distribución física de frecuencias ni una probabilidad de fallo.}
\label{fig:dispersion}
\end{figure}
'''

fig_energy = r'''\begin{figure}[!htbp]\centering
\begin{tikzpicture}\begin{axis}[width=0.8\linewidth,height=5.2cm,ybar,bar width=20pt,ymin=0,ymax=105,xmin=0.5,xmax=2.5,xtick={1,2},xticklabels={Rama 10,Rama 11},ylabel={Participación de las palas (\pct)},ytick={0,25,50,75,100},grid=major,grid style={gray!20},legend style={at={(0.5,1.05)},anchor=south,legend columns=2,font=\small},nodes near coords,nodes near coords style={font=\scriptsize,/pgf/number format/fixed,/pgf/number format/precision=1}]
'''
fig_energy += plot([(i, 100*float(energy[str(m)]['bladeMassFraction'])) for i, m in enumerate([10, 11], 1)], 'fill=massblue,draw=massblue')
fig_energy += r'\addlegendentry{Forma cuadrática de masa}' + '\n'
fig_energy += plot([(i, 100*float(energy[str(m)]['bladeElasticFraction'])) for i, m in enumerate([10, 11], 1)], 'fill=stiffgreen,draw=stiffgreen')
fig_energy += r'''\addlegendentry{Forma cuadrática elástica}
\end{axis}\end{tikzpicture}
\caption{Comprobación mecánica independiente en la referencia de la primera etapa. Las palas aportan aproximadamente 96.2 y 93.4\pct\ de la forma cuadrática de masa, y 97.8 y 86.5\pct\ de la forma cuadrática elástica de las ramas 10 y 11. Se utilizan masa y rigidez elástica de referencia; no se representa toda la energía del sistema en rotación.}
\label{fig:participaciones}
\end{figure}
'''

points = {}
levels = [0.90, 0.966666666667, 1.033333333333, 1.10]
for r in sweeps:
    if r['group'] == '10+11' and r['trackingValid'] == '1' and abs(float(r['rotorSpeedFactor'])-levels[2]) < 1e-10:
        a = min(range(4), key=lambda i: abs(levels[i]-float(r['bladeDensityFactor'])))
        b = min(range(4), key=lambda i: abs(levels[i]-float(r['bladeStiffnessFactor'])))
        points[a, b] = float(r['frequencyHz'])
assert len(points) == 16
lo, hi = min(points.values()), max(points.values())
fig_heat = r'\begin{figure}[!htbp]\centering' + '\n'
for (a, b), value in sorted(points.items()):
    t = (value-lo)/(hi-lo)
    if t <= 0.5:
        s = 2*t; rgb = tuple((1-s)*v+s*w for v, w in zip((0.25,0.20,0.55),(0.20,0.65,0.65)))
    else:
        s = 2*t-1; rgb = tuple((1-s)*v+s*w for v, w in zip((0.20,0.65,0.65),(0.99,0.88,0.18)))
    fig_heat += r'\definecolor{cell' + f'{a}{b}' + '}{rgb}{' + ','.join(f'{v:.4f}' for v in rgb) + '}\n'
fig_heat += r'\begin{tikzpicture}[x=1.85cm,y=1.2cm]' + '\n'
for (a, b), value in sorted(points.items()):
    t = (value-lo)/(hi-lo); ink = 'white' if t < .38 else 'black'
    fig_heat += r'\filldraw[fill=cell' + f'{a}{b}' + ',draw=white] (' + f'{a},{b}' + ') rectangle (' + f'{a+1},{b+1}' + ');\n'
    fig_heat += r'\node[text=' + ink + '] at (' + f'{a+.5},{b+.5}' + ') {' + f'{value:.3f}' + '};\n'
labels_levels = ['0.90','0.9667','1.0333','1.10']
for j, level in enumerate(labels_levels):
    fig_heat += r'\node[font=\small] at (' + f'{j+.5},-0.3' + ') {' + level + '};\n'
    fig_heat += r'\node[anchor=east,font=\small] at (' + f'-.08,{j+.5}' + ') {' + level + '};\n'
fig_heat += r'''\node at (2,-0.8) {Factor de masa/inercia de palas $\xi_\rho$};
\node[rotate=90] at (-0.8,2) {Factor de rigidez de palas $\xi_K$};
\node[font=\small] at (2,4.35) {$\Omega=12.4$ rpm; frecuencia media del grupo 10+11 [Hz]};
\end{tikzpicture}
\caption{Dieciséis combinaciones realmente calculadas a velocidad fija de 12.4 rpm. Cada número es una frecuencia de los resultados guardados; las celdas coloreadas no interpolan puntos adicionales. Hacia la derecha aumenta masa/inercia y disminuye frecuencia; hacia arriba aumenta rigidez y crece frecuencia. La diagonal sugiere compensación parcial, sin demostrar una ley exacta de compensación.}
\label{fig:dominio}
\end{figure}
'''

fig_noise = r'''\begin{figure}[!htbp]\centering
\begin{tikzpicture}\begin{axis}[width=0.84\linewidth,height=5.4cm,ybar,bar width=18pt,ymin=0.8,ymax=550,ymode=log,xtick={1,2,3,4,5},xticklabels={{Masa; 1+2},{Giro; 4+5},{Masa; 10+11},{Rigidez; 10+11},{Giro; 10+11}},xticklabel style={rotate=20,anchor=east,font=\small},ylabel={$\mu_i^*/\overline b_i$},xmin=0.5,xmax=5.5,grid=major,grid style={gray!20},ytick={1,10,100}]
'''
selected_noise = [('blade_density','1+2'),('rotor_speed','4+5'),('blade_density','10+11'),('blade_stiffness','10+11'),('rotor_speed','10+11')]
for j, key in enumerate(selected_noise, 1):
    r = freq[key]; color = 'massblue' if r['acceptedMean'] else 'gray!50'
    fig_noise += plot([(j,r['muStar']/r['muNoiseBound'])], f'fill={color},draw={color}')
fig_noise += plot([(0.5,10),(5.5,10)], 'red!70!black,dashed,thick,no marks')
fig_noise += r'''\node[anchor=south west,font=\small,text=red!70!black] at (axis cs:0.6,11) {Umbral de aceptación: 10};
\end{axis}\end{tikzpicture}
\caption{La estabilización de un estimador no basta para aceptarlo. Masa en 1+2 y velocidad en 4+5 tienen señal inferior a diez veces la envolvente de ruido, aunque sus medias se estabilizan. El eje vertical es logarítmico. Las tres influencias del grupo 10+11 superan ampliamente ese filtro.}
\label{fig:ruido}
\end{figure}
'''

summary_rows = ''
for g in groups:
    winner = max([freq[p,g] for p in parameters if freq[p,g]['acceptedMean']], key=lambda r:r['muStar'])
    label = {'blade_density':'Masa/inercia','blade_stiffness':'Rigidez','rotor_speed':'Velocidad'}[winner['parameter']]
    sign = r'$-$' if freq['rotor_speed',g]['mu'] < 0 else r'$+$'
    if not freq['rotor_speed',g]['acceptedMean']: sign = 'No resuelto'
    summary_rows += f'{g} & {nominal[g]:.3f} & {label} & {sign} ' + r'\\' + '\n'

range_rows = ''
for g in ['1+2']+groups:
    r = next(r for r in meta['ranges'] if r['group']==g)
    range_rows += f'{g} & {nominal[g]:.3f} & {r["minimumHz"]:.3f} & {r["maximumHz"]:.3f} ' + r'\\' + '\n'

example_rows = ''
for p in parameters:
    c = freq[p,'10+11']['mu']/.2
    label = {'blade_density':'Masa/inercia','blade_stiffness':'Rigidez','rotor_speed':'Velocidad'}[p]
    example_rows += f'{label} & {c:+.3f}' + r'\,\pct' + f' & {nominal["10+11"]*c*.01:+.5f} ' + r'\\' + '\n'

sigma_rows = ''
for p in parameters:
    r = freq[p,'10+11'];label = {'blade_density':'Masa/inercia','blade_stiffness':'Rigidez','rotor_speed':'Velocidad'}[p]
    sigma_rows += f'{label} & {r["sigma"]:.5f} & {r["sigma"]/r["sigmaNoiseBound"]:.2f} & {100*r["sigmaRelativeChange"]:.2f}' + r'\,\pct' + (' & Sí ' if r['acceptedDispersion'] else ' & No ') + r'\\' + '\n'

full_rows = ''
for p in parameters:
    for g in groups:
        r=freq[p,g]
        if r['acceptedMean']:
            label = {'blade_density':'Masa/inercia','blade_stiffness':'Rigidez','rotor_speed':'Velocidad'}[p]
            full_rows += f'{label} & {g} & {r["mu"]:+.5f} & {r["muStar"]:.5f} & {r["sigma"]:.5f} ' + r'\\' + '\n'

text = r'''\documentclass[11pt,a4paper]{article}
\usepackage[spanish]{babel}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[margin=2.3cm]{geometry}
\usepackage{amsmath,amssymb,booktabs,array}
\usepackage{hyperref}
\usepackage{tikz,pgfplots}
\pgfplotsset{compat=1.18}
\usetikzlibrary{babel,arrows.meta,positioning}
\definecolor{massblue}{rgb}{0.15,0.40,0.65}
\definecolor{stiffgreen}{rgb}{0.18,0.55,0.30}
\definecolor{speedorange}{rgb}{0.70,0.30,0.15}
\newcommand{\pct}{\text{\char37}}
\setlength{\parskip}{0.35em}
\renewcommand{\arraystretch}{1.15}
\title{Sensibilidad del aerogenerador:\\ resultados, mecanismos e interpretación}
\author{Documento de apoyo para la discusión con el asesor de tesis}
\date{Resultados del 6 de octubre de 2026; versión ilustrada para revisión}
\begin{document}
\maketitle

\section{Qué se puede concluir del estudio}
La pregunta estudiada es cómo cambian las frecuencias del modelo existente al modificar propiedades de las palas y velocidad del rotor. La respuesta depende del grupo modal. Entre los \emph{tres factores comparados}, la masa e inercia de palas tienen la mayor influencia media en las respuestas 3, 4+5, 8+9 y 10+11; la velocidad del rotor tiene la mayor influencia media en 6+7. Esta clasificación se refiere a un dominio exploratorio de factores entre 0.90 y 1.10.

Se completaron cuarenta trayectorias Morris: 160 evaluaciones del diseño y diez controles numéricos, todas convergidas. El diseño visitó 58 combinaciones diferentes; sus repeticiones se conservaron. Se aceptaron catorce indicadores de influencia media de frecuencia. Su cambio entre veinte y cuarenta trayectorias fue menor de 1\pct. Se aceptaron dos indicadores de dispersión, asociados a masa y rigidez en 10+11. Estas observaciones constituyen evidencia de sensibilidad del modelo numérico; no son una validación experimental ni una probabilidad de respuesta.

Una forma útil de presentar la contribución es: \emph{se obtuvo un cribado de influencia por grupo modal, con seguimiento de formas, actualización del equilibrio y filtros explícitos de ruido y estabilización}. El aporte científico incluye los signos opuestos del efecto del giro, la compensación parcial masa--rigidez y la identificación de respuestas cuya sensibilidad aún no puede resolverse.

\section{Qué se varió y qué representa el modelo}
Se denotan los factores por $\xi_\rho$ (masa e inercias de palas), $\xi_K$ (rigideces seccionales de palas) y $\xi_\Omega$ (velocidad del rotor). Su nominal es uno. El subíndice $\rho$ expresa un escalamiento compatible con cambio de densidad a geometría fija; no identifica una densidad experimental única de las palas.

\begin{center}\small
\begin{tabular}{p{2cm}p{7.1cm}p{3.7cm}}
\toprule Factor & Cambio consistente & Intervalo aprobado \\ \midrule
$\xi_\rho$ & Masa por longitud e inercias seccionales de las tres palas, con geometría y centroides fijos. & 0.90--1.10 \\
$\xi_K$ & Rigideces axial, de cortante, torsional y de flexión de las palas, escaladas conjuntamente. & 0.90--1.10 \\
$\xi_\Omega$ & Velocidad prescrita alrededor del eje del rotor, constante en cada caso. & 10.8--13.2 rpm \\
\bottomrule
\end{tabular}
\end{center}
Los rangos son escenarios aprobados, no límites de fabricación medidos. Los restantes parámetros conservan sus valores en esta campaña. Por ello, la clasificación global no compara exhaustivamente palas, torre, cimentación y conexiones.

\begin{figure}[!htbp]\centering
\begin{tikzpicture}[box/.style={draw,rounded corners,align=center,text width=3.6cm,minimum height=1.2cm,font=\small},arr/.style={-{Stealth},thick}]
\node[box,fill=massblue!10] (p) at (0,0) {Factores aprobados\\$\xi_\rho,\xi_K,\xi_\Omega$};
\node[box] (prop) at (4.5,0) {Propiedades consistentes\\masa, inercias y rigideces};
\node[box] (eq) at (9,0) {Nuevo equilibrio\\para cada escenario};
\node[box] (ops) at (9,-2.1) {Operadores efectivos\\masa, velocidad y tangente};
\node[box] (modes) at (4.5,-2.1) {Raíces y formas complejas\\seguimiento de grupos};
\node[box,fill=stiffgreen!10] (ee) at (0,-2.1) {Efectos y estimadores\\filtros de aceptación};
\draw[arr] (p)--(prop);\draw[arr] (prop)--(eq);\draw[arr] (eq)--(ops);
\draw[arr] (ops)--(modes);\draw[arr] (modes)--(ee);
\end{tikzpicture}
\caption{La sensibilidad es total: incluye el cambio del equilibrio y de los operadores. El giro es prescrito alrededor del eje 129--130, sin guiñada nominal. Cada punto es un escenario independiente a azimut congelado.}
\label{fig:proceso}
\end{figure}

\section{Cómo leer las frecuencias y los grupos}
Sea $\boldsymbol q$ el vector de coordenadas perturbadas alrededor del equilibrio y $t$ el tiempo. Los operadores efectivos de masa, velocidad y tangente se denotan por $\mathsf M$, $\mathsf D$ y $\mathsf K$. La parte homogénea de la linealización congelada se escribe
\begin{equation}
\mathsf M\ddot{\boldsymbol q}+\mathsf D\dot{\boldsymbol q}+\mathsf K\boldsymbol q=\boldsymbol 0.
\end{equation}
La matriz $\mathsf D$ reúne amortiguamiento, efectos giroscópicos y transporte; sus términos no representan todos disipación material. La tangente $\mathsf K$ incluye las contribuciones implementadas del equilibrio y del giro, con las transformaciones cinemáticas correspondientes.

Sean $\lambda$ una raíz compleja y $\boldsymbol\phi$ su forma modal. Con $\boldsymbol q\propto\boldsymbol\phi\exp(\lambda t)$ se obtiene el problema cuadrático
\begin{equation}
[\lambda^2\mathsf M+\lambda\mathsf D+\mathsf K]\boldsymbol\phi=\boldsymbol 0.
\end{equation}
Se definen frecuencia amortiguada $f_d=|\operatorname{Im}\lambda|/(2\pi)$ [Hz], crecimiento $\gamma=\operatorname{Re}\lambda$ [s$^{-1}$] y razón de amortiguamiento $\zeta=-\operatorname{Re}\lambda/|\lambda|$. La frecuencia mide oscilaciones por segundo; el crecimiento mide evolución de la envolvente. Una frecuencia que aumenta no implica, por sí sola, mayor estabilidad.

Las etiquetas 6+7 o 10+11 identifican conjuntos de ramas de la referencia, no posiciones que se vuelvan a ordenar por frecuencia en cada caso. Se correlacionan formas complejas en el espacio físico con la masa nominal y se comprueban subespacios cuando hay raíces próximas. La respuesta de un grupo es la \emph{media de las frecuencias de sus ramas}; no constituye una nueva forma modal individual. Las ramas 4 y 5 se agruparon por su proximidad en parte del dominio ampliado. La rama 12 toca la frontera del conjunto seguido y se excluye de los estimadores; sus vecinos del espectro calculado impiden tratarla como grupo cerrado.

\begin{center}\small
\begin{tabular}{lrlp{3cm}}
\toprule Respuesta & $f_{d,0}$ [Hz] & Mayor influencia media & Signo aceptado del giro \\ \midrule
@@SUMMARY_ROWS@@
\bottomrule
\end{tabular}
\end{center}
Aquí $f_{d,0}$ es la frecuencia nominal individual o media del grupo. El giro tiene efecto positivo en tres grupos y negativo en la rama 3. Su efecto en 4+5 permanece no resuelto frente al ruido. Una ausencia de aceptación no significa ausencia de influencia física.

\section{Cómo funciona Morris en este estudio}
Sea $x_i\in[0,1]$ la coordenada normalizada del factor $i$. Se aplica $\xi_i=\ell_i+(u_i-\ell_i)x_i$, donde los límites son $\ell_i=0.90$ y $u_i=1.10$. Se generan trayectorias aleatorias sobre cuatro niveles, con semilla 6706 y paso firmado $\Delta x_i$ de magnitud $2/3$ \cite{morris1991}. Cada segmento cambia un factor y conserva los otros dos. A lo largo de cuarenta trayectorias, ese cambio se observa en diferentes combinaciones del dominio.

@@TRAJECTORY@@

El tamaño del paso del factor es $|\Delta\xi_i|=0.20(2/3)=0.13333$. Aunque los puntos están dentro de $\pm10\pct$ respecto del nominal, cada secante atraviesa 13.333\pct\ del factor nominal. Esta es una razón para distinguir un efecto elemental de una derivada infinitesimal.

Sea $y$ una respuesta escalar y $s_y$ su escala nominal fija. Para frecuencia se usa $s_y=f_{d,0}$; para crecimiento, la media nominal de $|\lambda|$; para amortiguamiento, $\max(|\zeta_0|,0.01)$. El efecto elemental de la trayectoria $j$ es
\begin{equation}
EE_i^{(j)}=\frac{y_{\rm fin}^{(j)}-y_{\rm inicio}^{(j)}}{\Delta x_i^{(j)}s_y}.
\end{equation}
El signo del paso se conserva. Por ejemplo, en la primera arista del grupo 10+11 se \emph{reduce} $\xi_\rho$ de 1.10 a 0.9667 y la frecuencia \emph{aumenta} de 1.203767 a 1.263304 Hz:
\begin{equation}
EE_\rho^{(1)}=\frac{1.263304-1.203767}{(-2/3)(1.225430)}\simeq-0.07288.
\end{equation}
Su signo negativo describe la disminución de frecuencia al \emph{aumentar} masa/inercia. Este ejemplo proviene de casos almacenados; no es una simulación adicional.

Para $r$ trayectorias se calculan
\begin{align}
\mu_i&=\frac{1}{r}\sum_{j=1}^r EE_i^{(j)},&
\mu_i^*&=\frac{1}{r}\sum_{j=1}^r |EE_i^{(j)}|,\\
\sigma_i&=\left[\frac{1}{r-1}\sum_{j=1}^r(EE_i^{(j)}-\mu_i)^2\right]^{1/2}.
\end{align}
$\mu_i$ da dirección media, $\mu_i^*$ magnitud media y $\sigma_i$ dispersión de los efectos entre posiciones del dominio. No son índices de Sobol ni porcentajes máximos de respuesta. No se interpreta el muestreo como una distribución física de incertidumbre. Un efecto inválido impide calcular el estimador correspondiente; no se eliminan aristas selectivamente para obtener una clasificación favorable.

\section{Resultados: dirección, magnitud y ejemplo con unidades}
Para relacionar Morris con un cambio del factor, se define la pendiente media de secante normalizada
\begin{equation}
\overline c_i=\frac{\mu_i}{u_i-\ell_i}=\frac{\mu_i}{0.20}.
\end{equation}
En frecuencias, $\overline c_i$ es la media de $\Delta f_d/(f_{d,0}\Delta\xi_i)$. No equivale automáticamente a la sensibilidad local $S_i=(\xi_i/f_d)(\partial f_d/\partial\xi_i)$, porque utiliza secantes finitas y distintos puntos del dominio.

@@SIGNED@@

La masa/inercia tiene signo negativo en todos los grupos aceptados y la rigidez, positivo. La velocidad tiene mayor magnitud relativa en 6+7, mientras que reduce la frecuencia de 3. El giro, por tanto, no produce un aumento universal de todas las frecuencias. La comparación de magnitudes es entre factores con el mismo ancho relativo y dentro de cada respuesta.

Para 10+11, la frecuencia nominal es $f_{d,0}=1.22543$ Hz y
\begin{equation}
\overline c_\rho=-0.38266,\qquad
\overline c_K=0.35860,\qquad
\overline c_\Omega=0.18389.
\end{equation}
Como orientación de magnitud, al aplicar $\Delta f_d\simeq f_{d,0}\overline c_i\Delta\xi_i$ a un aumento de 1\pct\ del factor se obtiene:
\begin{center}\small
\begin{tabular}{lrr}
\toprule Factor que aumenta & Cambio relativo orientativo & Cambio orientativo [Hz] \\ \midrule
@@EXAMPLE_ROWS@@
\bottomrule
\end{tabular}
\end{center}
Estos valores son ejemplos calculados a partir de secantes medias; \emph{no son nuevos casos a 1\pct\ ni predicciones locales certificadas}. Los signos y magnitudes son coherentes con las derivadas aceptadas de la primera etapa en el mismo grupo.

\subsection{Intervalos observados de frecuencia}
\begin{center}\small
\begin{tabular}{lrrr}
\toprule Respuesta & Nominal [Hz] & Mínimo observado [Hz] & Máximo observado [Hz] \\ \midrule
@@RANGE_ROWS@@
\bottomrule
\end{tabular}
\end{center}
Los extremos reúnen cambios simultáneos de los tres factores en los vértices calculados. No son intervalos de confianza ni extremos demostrados de todo el dominio continuo. En 10+11 se observaron 1.116--1.342 Hz. El rango observado en 1+2 existe, aunque sus influencias individuales no pasaron el filtro de ruido: observar variación y atribuirla con resolución suficiente son afirmaciones distintas.

\section{Qué mecanismos físicos respaldan las tendencias}
\subsection{Masa y rigidez: intuición y comprobación}
Como analogía, un oscilador escalar de masa $m$ y rigidez $k$ tiene $f=(2\pi)^{-1}\sqrt{k/m}$, de donde
\begin{equation}
\frac{\Delta f}{f}\simeq\frac{1}{2}\frac{\Delta k}{k}-\frac{1}{2}\frac{\Delta m}{m}.
\end{equation}
La relación explica por qué aumentar masa suele reducir frecuencia y aumentar rigidez suele elevarla. Es una analogía para interpretar signos; no sustituye el aerogenerador multicuerpo en rotación ni establece coeficientes exactos de $\pm0.5$ para sus factores.

En el modelo, $\xi_\rho$ cambia inercia traslacional y rotacional de palas, peso y contribuciones asociadas al giro; también cambia el equilibrio. $\xi_K$ modifica conjuntamente las rigideces axial, de cortante, torsional y de flexión. Los coeficientes observados incluyen acoplamiento con torre, góndola, cubo y conexiones, cuya masa y rigidez no se escalan en esta campaña. Por eso el efecto no se reduce a reemplazar toda la masa o toda la rigidez del sistema.

@@ENERGY@@

Para interpretar las participaciones de la figura~\ref{fig:participaciones}, sea $\boldsymbol\phi$ una forma nominal y $\mathsf M_c$ la contribución de masa del componente $c$. Su participación de referencia se obtiene de $\boldsymbol\phi^{\mathsf H}\mathsf M_c\boldsymbol\phi$ dividida por la suma de las contribuciones; $\mathsf H$ indica transposición conjugada. Se procede de forma análoga con la rigidez elástica de referencia. La presencia predominante de palas en 10 y 11 respalda la sensibilidad a sus propiedades. Estas participaciones no separan cuantitativamente todos los mecanismos de la tangente rotacional.

\subsection{Giro: competencia de contribuciones}
El incremento de velocidad modifica efectos giroscópicos proporcionales a $\Omega$, contribuciones inerciales y de transporte, términos proporcionales a $\Omega^2$, el equilibrio y las derivadas de las restricciones y de la transformación de coordenadas. La matriz de velocidad y la tangente intervienen simultáneamente en el problema cuadrático; no basta imaginar una rigidez adicional positiva.

El signo negativo observado en 3 y positivo en 6+7, 8+9 y 10+11 es evidencia de que la respuesta al giro depende del grupo. La hipótesis mecánica compatible con la formulación es una competencia de contribuciones cuya proyección modal cambia de una rama a otra. El cribado no identifica cuánto aporta individualmente cada término; esa separación requeriría un diagnóstico adicional del modelo existente.

\subsection{Compensación parcial entre masa y rigidez}
A velocidad fija, la orientación media del grupo 10+11 sugiere
\begin{equation}
\frac{\Delta f_d}{f_{d,0}}\simeq-0.38266\Delta\xi_\rho+0.35860\Delta\xi_K.
\end{equation}
Una cancelación aproximada de estas secantes daría $\Delta\xi_K\simeq1.067\Delta\xi_\rho$. Esta proporción es una \emph{hipótesis de compensación para comprobar}, no una ley válida para todos los puntos. Diferentes propiedades podrían producir frecuencias similares: ajustar solo una frecuencia puede dejar ambigüedad entre masa y rigidez.

@@HEAT@@

La diagonal de la figura~\ref{fig:dominio} muestra frecuencias próximas al aumentar conjuntamente masa y rigidez. Por ejemplo, las esquinas de factores iguales $(0.90,0.90)$ y $(1.10,1.10)$ dan aproximadamente 1.236 y 1.231 Hz a 12.4 rpm. Los valores son cercanos, pero distintos; la compensación no es exacta. Sería útil contrastar más de una frecuencia, formas modales u otros indicadores al identificar propiedades.

\section{Por qué se aceptan unos resultados y otros no}
Se evalúan tres preguntas numéricas: ¿se sigue la misma respuesta modal?, ¿el efecto supera el ruido?, ¿el estimador se estabiliza al aumentar trayectorias? El éxito del solver no garantiza por sí solo las tres condiciones. En esta campaña, las formas y grupos cerrados se conservaron; el grupo abierto asociado a 12 se rechazó.

\subsection{Ruido y señal}
Sea $\eta$ la máxima diferencia de una respuesta observada entre controles: repetición nominal, tolerancia QEP más estricta y solución directa frente a continuación, en el nominal y dos esquinas. Se asigna la envolvente empírica por efecto
\begin{equation}
b_i^{(j)}=\frac{2\eta}{|\Delta x_i^{(j)}|s_y},\qquad
\overline b_i=\frac{1}{r}\sum_j b_i^{(j)}.
\end{equation}
La media absoluta debe satisfacer $\mu_i^*\geq10\overline b_i$. La envolvente no es una cota rigurosa de error en todo el dominio. La comparación con continuación es relevante porque diferencias pequeñas del equilibrio y la tangente pueden afectar indicadores aunque el residuo de equilibrio sea reducido.

@@NOISE@@

Por ejemplo, para masa/inercia en 1+2 el cociente señal/ruido es 7.09 y, para velocidad en 4+5, 5.88: ambos quedan bajo el umbral 10. No se publican como influencias aceptadas, aunque sus estimadores cambian menos de 1\pct\ entre veinte y cuarenta trayectorias. Esto evita confundir una estimación repetible con una estimación suficientemente resuelta.

\subsection{Estabilización con el número de trayectorias}
@@CONVERGENCE@@

El máximo cambio relativo de $\mu_i^*$ entre veinte y cuarenta, entre los catorce indicadores aceptados, fue @@MAX_CHANGE@@. El umbral fijado era 10\pct. El orden de influencia se conserva en los grupos mostrados. Este resultado apoya la suficiencia del cribado para estas respuestas; no demuestra convergencia espacial de las sensibilidades en rotación ni elimina la dependencia de la malla numérica de Morris.

Los máximos residuos de equilibrio y del QEP en norma dual de masa fueron $9.94\times10^{-9}$ y $4.05\times10^{-9}$, respectivamente. Esta norma reúne fuerzas y momentos con una escala dimensional compatible. Las 170 evaluaciones convergieron y pasaron 17 pruebas del módulo. La regresión histórica de 155 pruebas se conserva como evidencia anterior; no se presenta como una nueva ejecución. Las 148 fuentes físicas MATLAB anteriores permanecieron intactas.

\section{Qué significa la dispersión aceptada}
@@DISPERSION@@

La dispersión indica que el efecto elemental cambia según el punto donde se evalúa. Puede reunir curvatura respecto del propio factor, dependencia de los otros factores e influencia numérica. Morris no separa estas causas. Para $\sigma_i$, la envolvente propagada es $b_{\sigma,i}=[\sum_j(b_i^{(j)})^2/(r-1)]^{1/2}$; se exige $\sigma_i\geq10b_{\sigma,i}$ y estabilización al 10\pct.

\begin{center}\small
\begin{tabular}{lrrrr}
\toprule Factor; grupo 10+11 & $\sigma_i$ & $\sigma_i/b_{\sigma,i}$ & Cambio 20--40 & Aceptado \\ \midrule
@@SIGMA_ROWS@@
\bottomrule
\end{tabular}
\end{center}
La dispersión de masa/inercia y rigidez supera el ruido y cambia aproximadamente 6.31\pct\ y 8.22\pct, respectivamente. La de velocidad tiene cociente 7.97 y no supera el filtro de ruido. No puede afirmarse que el giro sea exactamente lineal o independiente de los otros factores por ese rechazo. Tampoco puede afirmarse que las dos dispersiones aceptadas demuestren, por sí solas, una interacción específica.

\section{Estabilidad, alcance y decisiones para continuar}
Las partes reales de los dieciséis representantes modales retornados por evaluación fueron negativas; la mayor observada fue $-0.01238$ s$^{-1}$. Bajo los operadores congelados, esto es compatible con decaimiento de esas perturbaciones modales seleccionadas. El espectro es parcial y no se calcula estabilidad periódica de Floquet: el dato no demuestra estabilidad de toda la turbina ni de todas las velocidades posibles. La sensibilidad de un centroide de crecimiento tampoco sustituye el examen de cada raíz.

La verificación espacial previa se realizó con rotor detenido, y la convergencia temporal corresponde al benchmark sísmico local anterior. No verifican automáticamente las sensibilidades globales en rotación. Esta etapa utiliza propiedades heredadas sin calibración experimental y tres factores elegidos; no estudia incertidumbre probabilística ni sensibilidad sísmica global.

Las siguientes decisiones científicas se pueden discutir con el asesor:
\begin{enumerate}
\item Obtener fuentes para rangos físicos y propiedades de palas, conexiones y apoyo. Esto permitiría pasar de escenarios a incertidumbre justificada.
\item Priorizar la convergencia espacial de las respuestas y sensibilidades con rotor en operación, conservando restricciones y seguimiento modal.
\item Examinar la compensación masa--rigidez con combinaciones dirigidas y más de una respuesta; distinguir curvatura e interacción en 10+11.
\item Definir si el alcance del artículo será sensibilidad a azimut fijo o si se requiere un estudio periódico adicional para afirmaciones de estabilidad.
\end{enumerate}
Estas son propuestas para acordar; no se han ejecutado campañas adicionales en la preparación de este documento.

\section{Guía breve para la reunión}
\paragraph{Apertura.} Se auditó y conservó el modelo existente, se implementó sensibilidad total con nuevo equilibrio y se pasó de derivadas locales a un cribado Morris sobre escenarios aprobados. La implementación conserva trazabilidad y rechaza resultados sin resolución suficiente.
\paragraph{Resultado principal.} La influencia depende del grupo: masa/inercia domina cuatro respuestas y velocidad domina 6+7 entre los tres factores. La frecuencia de 3 disminuye al aumentar giro; las de tres grupos superiores aumentan. Se usa la figura~\ref{fig:sentidos} para mostrar simultáneamente dirección y magnitud.
\paragraph{Mecanismo respaldado.} La participación nominal predominante de palas en 10 y 11 apoya la sensibilidad a sus propiedades. La figura~\ref{fig:dominio} muestra la oposición y compensación parcial entre masa y rigidez. La separación exacta de contribuciones del giro sigue abierta.
\paragraph{Confianza y límite.} Catorce influencias y dos dispersiones superan los filtros. Los estimadores de influencia cambian menos de 1\pct\ al duplicar veinte a cuarenta trayectorias. Las figuras~\ref{fig:ruido} y~\ref{fig:dispersion} muestran por qué otros indicadores permanecen no resueltos. Esta evidencia es numérica y de azimut fijo.
\paragraph{Decisión a pedir.} Acordar cuál será la siguiente contribución: rangos físicos, convergencia espacial en operación, comprobación de compensaciones o extensión periódica. La elección debe estar ligada a la afirmación científica que se quiera sostener en el artículo y la tesis.

\appendix
\section{Valores de los catorce indicadores aceptados}
\begin{center}\small
\begin{tabular}{llrrr}
\toprule Factor & Grupo & $\mu_i$ & $\mu_i^*$ & $\sigma_i$ \\ \midrule
@@FULL_ROWS@@
\bottomrule
\end{tabular}
\end{center}
La aceptación de $\mu_i^*$ en esta tabla no implica aceptación de $\sigma_i$ en todas sus filas. Los controles de dispersión se evalúan por separado. Los números se redondean para lectura; las tablas CSV y MAT conservan mayor precisión.

Todas las figuras son vectoriales y sus datos están incorporados en esta misma fuente. Proceden de \texttt{morris\_estimators.csv}, \texttt{morris\_sweeps.csv}, \texttt{morris\_vertices.csv}, \texttt{report\_data.json} y \texttt{modal\_energy\_evidence.csv} de las campañas guardadas. No se reemplazaron casos fallidos ni se calcularon escenarios nuevos para preparar las figuras.

\begin{thebibliography}{9}
\bibitem{morris1991} M. D. Morris. Factorial Sampling Plans for Preliminary Computational Experiments. \emph{Technometrics}, 33(2), 161--174, 1991. \href{https://doi.org/10.1080/00401706.1991.10484804}{doi:10.1080/00401706.1991.10484804}.
\end{thebibliography}
\end{document}
'''

# The already verified trajectory figure is retained directly from the editor.
current = (DOCS / 'SECCION_MORRIS_REVISION.tex').read_text()
start = current.index(r'\begin{figure}[htbp]')
end = current.index(r'\end{figure}', start) + len(r'\end{figure}')
trajectory = current[start:end]
values = {'SUMMARY_ROWS':summary_rows,'TRAJECTORY':trajectory,'SIGNED':fig_signed,'EXAMPLE_ROWS':example_rows,
          'RANGE_ROWS':range_rows,'ENERGY':fig_energy,'HEAT':fig_heat,'NOISE':fig_noise,'CONVERGENCE':fig_conv,
          'DISPERSION':fig_disp,'SIGMA_ROWS':sigma_rows,'FULL_ROWS':full_rows,'MAX_CHANGE':pct(max_change)}
for key, value in values.items():
    text = text.replace('@@'+key+'@@', value)
assert '@@' not in text
assert text.count(r'\begin{figure}') == 8
(DOCS / 'SECCION_MORRIS_REVISION.tex').write_text(text, encoding='utf-8')
data_files = [DOCS / 'report_data.json', ROOT / 'runs/sensitivity/initial_20261005/local/modal_energy_evidence.csv']
data_files += [RUNS / f for f in ['morris_estimators.csv','morris_sweeps.csv','morris_vertices.csv','morris_elementary_effects.csv']]
provenance={'date':'2026-10-06','sourceFile':'SECCION_MORRIS_REVISION.tex','figures':8,'newModelEvaluations':0,
            'dataFiles':[str(p) for p in data_files],
            'dataSHA256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in data_files},
            'sourceSHA256':hashlib.sha256(text.encode()).hexdigest()}
(REV / 'revision_provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
print('Edited existing source in place; eight inline figures, no external figure files.')
