#!/usr/bin/env python3
"""Generate self-contained PGFPlots/TikZ snippets for the structural manuscript.
No external graphics are required by the resulting main.tex. Numerical inputs
remain in the simulation repository; coordinates are embedded without fitting.
"""
from pathlib import Path
import argparse
from scipy.io import loadmat
ROOT=Path(__file__).resolve().parents[1]

# Numerical figure generation. Each data block embeds original tabulated values.
import csv
DATA=ROOT/'output/structural_paper'
def rows(name):
    with (DATA/(name+'.csv')).open() as f:return list(csv.DictReader(f))
def curve(name,x,y,style='black,thick',label=None,predicate=None,scale=1):
    rr=rows(name); rr=[r for r in rr if predicate is None or predicate(r)]
    v='\n'.join(f"{float(r[x]):.12g} {float(r[y])*scale:.12g}" for r in rr)
    s='\\addplot['+style+('' if label else ',forget plot')+'] table[row sep=newline] {\nx y\n'+v+'\n};\n'
    if label:s+='\\addlegendentry{'+label+'}\n'
    return s

def panel(options,body):return '\\begin{axis}['+options+']\n'+body+'\\end{axis}\n'
def figure(body,caption,label):return '\\begin{figure}[tbp]\\centering\n\\begin{tikzpicture}\n'+body+'\\end{tikzpicture}\n\\caption{'+caption+'}\\label{fig:'+label+'}\n\\end{figure}\n'
def numeric_figures():
    d={}; left=r'width=.46\textwidth,height=6cm'; right=r'at={(.52\textwidth,0)},anchor=south west,width=.46\textwidth,height=6cm'
    body=panel(left+r',xlabel={Flexible elements},ylabel={Frequency discrepancy (\%)},xmode=log,ymode=log,xtick={133,266,532},xticklabels={133,266,532}',curve('mesh_convergence','elements','maxFirst12FrequencyErrorPercent','black,thick,mark=*',predicate=lambda r:float(r['subdivision'])<8))
    body+=panel(right+r',xlabel={Bending mode},ylabel={EB--Timoshenko difference (\%)},xtick={1,2,3,4},ymode=log,legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}',curve('beam_theory_difference','mode','theoryDifferencePercent','black,thick,mark=*',r'$L/h=10$',lambda r:float(r['slenderness'])==10)+curve('beam_theory_difference','mode','theoryDifferencePercent','black,dashed,thick,mark=square*',r'$L/h=100$',lambda r:float(r['slenderness'])==100))
    d['verification']=figure(body,r'Numerical resolution and beam assumptions. Left: maximum discrepancy of the first twelve stationary-turbine frequencies relative to the 1064-element mesh. Right: Euler--Bernoulli frequency differences relative to a converged Timoshenko cantilever, for two slenderness ratios $L/h$.','verification')
    body=panel(r'width=.91\textwidth,height=7cm,xlabel={Rotor speed (rpm)},ylabel={Frequency (Hz)},xmin=.5,xmax=7.44,ymin=0,ymax=1.25,legend columns=4,legend style={at={(.5,1.02)},anchor=south,/tikz/column sep=7pt}', ''.join(curve('campbell','rpm',f'frequency_{i}_hz','black!65,thin',r'Sorted frequencies' if i==1 else None) for i in range(1,12))+''.join(r'\addplot[%s,domain=.5:7.44,samples=2] {%s*x/60};\addlegendentry{%sP}'%(sty,k,k) for k,sty in [(1,'black,dotted,thick'),(3,'black,dashed,thick'),(6,'black,dashdotted,thick')]))
    d['campbell']=figure(body,r'Frequency diagram of the azimuth-averaged, 804-coordinate structural system without gravity or aerodynamic feedback. The lowest eleven sorted frequencies are compared with excitation orders 1P, 3P and 6P; connecting lines do not denote tracked mode identities.','campbell')
    body=panel(left+r',xlabel={Rotor speed (rpm)},ylabel={Hub axial receptance (m/N)},ymode=log,xmin=.5,xmax=7.44,legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}', ''.join(curve(f'receptance_{k}P','rpm','hub_axial_m_per_N',s,f'{k}P') for k,s in [(1,'black,dotted,thick'),(3,'black,thick'),(6,'black,dashed,thick')]))
    body+=panel(right+r',xlabel={Rotor speed (rpm)},ylabel={3P receptance ($10^{-5}$ m/N)},ymin=0.5,ymax=4.6,xmin=3.25,xmax=3.65,legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}', ''.join(curve('receptance_3P','rpm',col,s,lab,lambda r:3.25<float(r['rpm'])<3.65,scale=1e5) for col,s,lab in [('hub_axial_m_per_N','black,thick','Hub'),('nacelle_axial_m_per_N','black,dashed,thick','Nacelle'),('tower_top_axial_m_per_N','black,dotted,thick','Tower top')]))
    d['receptance']=figure(body,r'Axial displacement magnitude per unit harmonic hub force along the rotor axis. Left: hub receptance at orders 1P, 3P and 6P. Right: hub, nacelle and tower-top receptances near the 3P peak. Rayleigh damping targets are 0.5\% at 0.17 and 1 Hz.','receptance')
    body=panel(left+r',xlabel={Time (s)},ylabel={Tower-top global $X$ (m)},xmin=15,xmax=80,legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}',curve('nonlinear_history_00','time_s','tower_top_x_m','black,thin',r'$\Omega_{\rm nom}=0$')+curve('nonlinear_history_07','time_s','tower_top_x_m','black,dashed,thin',r'$\Omega_{\rm nom}=0.7$ rad/s'))
    body+=panel(right+r',xlabel={Frequency (Hz)},ylabel={One-sided amplitude (m)},xmin=.1,xmax=.5,ymode=log,legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}',curve('nonlinear_spectra','frequency_hz','case00_tower_x_m','black,thin',r'$0$ rad/s')+curve('nonlinear_spectra','frequency_hz','case07_tower_x_m','black,dashed,thin',r'$0.7$ rad/s'))
    d['nonlinear']=figure(body,r'Tower-top response of the nonlinear model at two nominal rotor speeds. Left: global $X$ displacement following the nacelle pulse at 20--21 s. Right: one-sided amplitude spectra over 25.01--1099.99 s, after mean removal, using a rectangular window ($\Delta f=0.00093$ Hz).','nonlinear')
    body=panel(left+r',xlabel={Time (s)},ylabel={Base-relative global $X$ (mm)},xmin=0,xmax=8,legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}', ''.join(curve('stationary_response_plot','timeS',c,s,lab,scale=1000) for c,s,lab in [('MHT_full_nacelle_ux_m','black,thick','Nacelle'),('MHT_full_blade1_tip_ux_m','black,dashed,thin','Blade 1 tip'),('MHT_full_blade2_tip_ux_m','black,dotted,thick','Blade 2 tip'),('MHT_full_blade3_tip_ux_m','black,dashdotted,thin','Blade 3 tip')]))
    body+=panel(right+r',xlabel={Time (s)},ylabel={Base moment $M_Y$ (MN m)},xmin=0,xmax=8',curve('stationary_response_plot','timeS','MHT_full_base_My_Nm','black,thick',scale=1e-6))
    d['stationary']=figure(body,r'Stationary 804-coordinate reference under the two prescribed synthetic base motions. Different blade orientations produce different tip responses despite shared support motion. The base moment is recovered from the full dynamic residual. This zero-speed, unloaded configuration is separate from the rotating receptances and the nonlinear pulse campaign. Plotting uses an extrema-preserving subset of the stored samples; error norms use the full histories.','stationary')
    body=panel(r'width=.88\textwidth,height=6cm,xlabel={Tracked modal group},ylabel={Mean normalized elementary effect},xtick={1,2,3,4,5,6,7},xticklabels={{1+2},3,{4+5},{6+7},{8+9},{10+11},12},xmin=.5,xmax=7.5,ymin=-.14,ymax=.12,unbounded coords=jump,legend columns=3,legend style={at={(.5,1.03)},anchor=south,/tikz/column sep=7pt}', ''.join(curve('morris_'+n,'group_index','mu',s.replace('thick,','thick,only marks,'),lab) for n,s,lab in [('blade_density','black,thick,mark=*','Blade mass/inertia'),('blade_stiffness','black,dashed,thick,mark=square*','Blade stiffness'),('rotor_speed','black,dotted,thick,mark=triangle*','Rotor speed')]))
    d['sensitivity']=figure(body,r'Mean normalized frequency effects about the gravity-loaded, frozen-azimuth state at 12 rpm. Blade mass/inertia, stiffness and speed vary over $\pm10\%$. Markers show accepted means for the tracked modal groups; missing markers denote unresolved effects.','sensitivity')
    body=panel(left+r',xlabel={Retained modes},ylabel={History error (\%)},xmode=log,ymode=log,ytick={0.00001,0.0001,0.001,0.01,0.1,1,10,100},xtick={12,24,48,96,192},xticklabels={12,24,48,96,192},legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}', ''.join(curve('rom_errors','modes',c,s,lab) for c,s,lab in [('nacelle_ux_m','black,thick,mark=*','Nacelle $u_X$'),('blade1_tip_ux_m','black,dashed,thick,mark=square*','Blade 1 $u_X$'),('base_My_Nm','black,dotted,thick,mark=triangle*','Base $M_Y$')])+r'\addplot[black!65,dashdotted,domain=12:192,samples=2,forget plot] {1};\node[anchor=south east,font=\scriptsize,fill=white,inner sep=1pt] at (axis cs:180,1) {1\%};')
    body+=panel(right+r',xlabel={Retained modes},ylabel={Measured speedup},xmode=log,xtick={12,24,48,96,192},xticklabels={12,24,48,96,192},legend columns=-1,legend style={at={(.5,1.04)},anchor=south,/tikz/column sep=5pt}',curve('rom_costs','dofs','speedupIntegration','black,thick,mark=*','Integration',lambda r:r['model']!='MHT_full')+curve('rom_costs','dofs','speedupOneCaseIncludingBasis','black,dashed,thick,mark=square*','With preparation',lambda r:r['model']!='MHT_full'))
    d['rom']=figure(body,r'Modal accuracy and solution cost for the stationary support-motion case. Left: relative $L^2$ history errors at the same time step; the horizontal line marks 1\%. Right: integration speedup and speedup including basis construction and projection. Assembly and output recovery/export are excluded.','rom')
    return d

def geometry_figure():
    return r'''% Original engineering schematic; geometry is intentionally not to scale.
% Requires TikZ only; housing and blade outlines are explanatory, not CAD.
\begin{figure}[tbp]
\centering
\begin{tikzpicture}[x=1cm,y=1cm,line cap=round,line join=round,
  every node/.style={font=\small},
  outline/.style={draw=black,line width=.7pt,fill=white},
  leader/.style={draw=black,line width=.45pt},
  tie/.style={draw=black,line width=.55pt,dash pattern=on 2.2pt off 1.6pt}]
\path[use as bounding box] (0,0) rectangle (16,8.35);
% Fixed support and tapered tower.
\draw[outline] (5.10,1.30)--(5.37,4.96)--(5.65,4.96)--(5.91,1.30)--cycle;
\draw[line width=.75pt] (4.75,1.30)--(6.27,1.30);
\foreach \x in {4.85,5.05,5.25,5.45,5.65,5.85,6.05,6.25}
  \draw[line width=.4pt] (\x,1.30)--++(-.16,-.16);
% A short flexible transition, kept distinct from the rigid housing.
\draw[outline] (5.37,4.96)--(5.40,5.24)--(5.69,5.32)--(5.65,4.96)--cycle;
\draw[line width=.4pt] (5.38,5.06)--(5.66,5.06);
\draw[line width=.4pt] (5.39,5.16)--(5.68,5.24);
% Nacelle housing, with a rounded rear and sloping front.
\draw[outline] (4.95,5.27)--(6.94,5.27)--(7.18,5.43)--(7.18,5.66)
 --(6.94,5.83)--(5.01,5.83)
 ..controls(4.79,5.83)and(4.76,5.72)..(4.76,5.54)
 ..controls(4.76,5.35)and(4.81,5.27)..(4.95,5.27)--cycle;
% Shaft and flanges. These symbols denote the six-component connection.
\draw[line width=.6pt] (7.18,5.46)--(9.06,5.46);
\draw[line width=.6pt] (7.18,5.59)--(9.06,5.59);
\foreach \x in {7.39,7.48,8.72,8.81}
  \draw[line width=.65pt] (\x,5.31)--(\x,5.73);
% Three blade silhouettes drawn before their roots and the hub.
\draw[outline] (9.29,5.92)
 ..controls(9.18,6.17)and(9.10,6.45)..(9.09,6.76)
 ..controls(9.07,7.23)and(9.14,7.83)..(9.22,8.14)
 ..controls(9.37,7.52)and(9.58,6.90)..(9.57,6.50)
 ..controls(9.56,6.22)and(9.48,6.01)..(9.43,5.90)--cycle;
\draw[outline] (9.11,5.16)
 ..controls(8.80,5.03)and(8.51,4.73)..(8.23,4.41)
 ..controls(7.75,3.86)and(7.05,3.08)..(6.65,2.52)
 ..controls(7.35,2.97)and(8.10,3.50)..(8.65,4.01)
 ..controls(9.00,4.34)and(9.20,4.70)..(9.28,5.03)--cycle;
\draw[outline] (9.80,5.15)
 ..controls(10.17,5.14)and(10.56,4.98)..(10.95,4.76)
 ..controls(11.71,4.31)and(12.92,3.62)..(13.67,3.11)
 ..controls(12.75,3.37)and(11.42,3.82)..(10.67,4.20)
 ..controls(10.21,4.42)and(9.91,4.70)..(9.73,5.00)--cycle;
% Hub nose and rear collar.
\draw[outline] (9.03,5.22)--(9.03,5.83)
 ..controls(9.48,5.83)and(9.91,5.69)..(10.12,5.52)
 ..controls(9.90,5.34)and(9.47,5.22)..(9.03,5.22)--cycle;
\draw[line width=.5pt] (9.13,5.25)--(9.13,5.80);
% Master nodes and blade-root constraints.
\fill (5.87,5.54) circle (2pt);
\fill (9.57,5.52) circle (2pt);
\draw[tie] (9.57,5.52)--(9.36,5.93);
\draw[tie] (9.57,5.52)--(9.18,5.10);
\draw[tie] (9.57,5.52)--(9.78,5.08);
\foreach \p in {(9.36,5.93),(9.18,5.10),(9.78,5.08)}
  \draw[line width=.6pt,fill=white] \p circle (2.2pt);
% Spin arrow, separated from the upper blade and leader lines.
\draw[->,line width=.6pt] (10.10,5.96) arc[start angle=28,end angle=142,x radius=.67cm,y radius=.43cm];
\node[anchor=west] at (10.35,6.08) {$\psi(t),\ \Omega$};
% Restrained technical labels with noncrossing leaders.
\node[anchor=east,align=right] at (4.10,6.42) {Rigid nacelle};
\draw[leader] (4.24,6.39)--(5.18,6.39)--(5.48,5.83);
\node[anchor=south,align=center] at (7.30,6.33) {Elastic drivetrain\\connection};
\draw[leader] (7.30,6.24)--(7.75,5.61);
\node[anchor=west,align=left] at (11.66,7.23) {Three flexible blades};
\draw[leader] (11.52,7.22)--(10.10,7.22)--(9.53,6.90);
\node[anchor=west] at (12.02,5.66) {Rigid hub--nose};
\draw[leader] (11.88,5.65)--(10.62,5.65)--(10.08,5.53);
\node[anchor=east,align=right] at (4.10,4.61) {Flexible transition};
\draw[leader] (4.24,4.65)--(4.78,4.65)--(5.37,5.07);
\node[anchor=east] at (4.10,3.14) {Flexible tower};
\draw[leader] (4.24,3.13)--(5.20,3.13);
\node[anchor=north] at (5.50,1.02) {Fixed base};
% Master-coordinate labels kept in clear interior spaces.
\node[anchor=north,align=center] at (6.65,4.91) {$M_N$};
\draw[leader] (6.55,4.98)--(5.87,5.49);
\node[anchor=north,align=center] at (9.55,3.42) {$M_R$};
\draw[leader] (9.57,3.61)--(9.57,5.47);
% Inertial triad is separate from the structural symbols.
\draw[->,line width=.6pt] (1.95,1.53)--(2.92,1.53) node[right] {$X$};
\draw[->,line width=.6pt] (1.95,1.53)--(1.95,2.48) node[above] {$Z$};
\draw[->,line width=.6pt] (1.95,1.53)--(1.30,1.04) node[below left] {$Y$};
\node[anchor=north,font=\footnotesize] at (2.05,.82) {Global frame};
% A single shared symbol key, visually outside the assembly.
\fill (4.0,.24) circle (2pt);
\node[anchor=west,font=\footnotesize] at (4.14,.24) {rigid-body master};
\draw[line width=.6pt,fill=white] (7.42,.24) circle (2.2pt);
\node[anchor=west,font=\footnotesize] at (7.56,.24) {blade-root slave};
\draw[tie] (10.76,.24)--(11.32,.24);
\node[anchor=west,font=\footnotesize] at (11.46,.24) {rigid compatibility};
\end{tikzpicture}
\caption{Structural idealization and connection kinematics (schematic, not to scale). The tower, transition and blades are flexible; the nacelle and hub are rigid. The master points $M_N$ and $M_R$ are connected elastically, while blade-root motion satisfies rigid compatibility with the hub.}\label{fig:geometry}
\end{figure}
'''

def kinematics_figure():
    return r'''% Original engineering schematic. Requires only tikz; no external graphics.
\begin{figure}[tbp]
\centering
\begin{tikzpicture}[x=1cm,y=1cm,line width=.45pt,>=stealth,font=\small]
\path[use as bounding box] (0,0) rectangle (16,5.7);
\node[anchor=north west] at (.15,5.55) {(a)};
\node[anchor=north west] at (8.05,5.55) {(b)};
% Pure nominal rotor motion, viewed along its fixed spin axis.
\begin{scope}[shift={(3.15,2.75)}]
  % Initial blade position, shown only as construction geometry.
  \draw[dashed,line width=.35pt] (.38,-.10)
    .. controls (.75,-.23) and (1.25,-.19) .. (2.48,0)
    .. controls (1.25,.28) and (.72,.27) .. (.38,.10) -- cycle;
  \draw[densely dashed,line width=.3pt,->] (0,0)--(3.28,0)
    node[right] {$\mathbf E_2$};
  \draw[densely dashed,line width=.3pt,->] (0,0)--(0,2.42)
    node[above] {$\mathbf E_3$};
  % Three nominal blade outlines: finite width, taper and rounded root.
  \foreach \a in {38,158,278}{
    \begin{scope}[rotate=\a]
    \draw[fill=white,line width=.65pt] (.38,-.10)
      .. controls (.75,-.23) and (1.25,-.19) .. (2.48,0)
      .. controls (1.25,.28) and (.72,.27) .. (.38,.10)
      .. controls (.31,.06) and (.31,-.06) .. (.38,-.10) -- cycle;
    \draw[dash pattern=on 3pt off 1.4pt on .6pt off 1.4pt,line width=.3pt]
      (.28,0)--(2.55,0);
    \end{scope}
  }
  \draw[fill=white,line width=.65pt] (0,0) circle (.34);
  \draw (0,0) circle (.065);
  \fill (0,0) circle (.016);
  \draw[line width=.4pt,->] (1.03,0) arc[start angle=0,end angle=38,radius=1.03];
  \node at (1.38,.40) {$\psi(t)$};
  % Rotating nominal basis, kept clear of the blade outlines.
  \draw[->,line width=.4pt] ({2.53*cos(38)},{2.53*sin(38)})
    --({2.94*cos(38)},{2.94*sin(38)}) node[above right] {$\mathbf a_2(t)$};
  \draw[->,line width=.4pt] (0,0)--({1.33*cos(128)},{1.33*sin(128)})
    node[above left] {$\mathbf a_3(t)$};
  \draw[line width=.35pt] (-.24,-.23)--(-.80,-.78)--(-1.52,-.78);
  \node[anchor=east] at (-1.55,-.78) {$O,\ \mathbf E_1$};
\end{scope}
% Rotating-frame section: small deformation, independent of nominal spin.
\begin{scope}[shift={(10.15,2.05)}]
  % Section contour is schematic, not an aerodynamic profile.
  \draw[dashed,line width=.45pt]
    (-1.30,0) .. controls (-1.30,.75) and (.92,.73) .. (1.65,0)
    .. controls (.92,-.58) and (-1.30,-.65) .. (-1.30,0) -- cycle;
  \draw[densely dashed,line width=.3pt,->] (-1.6,0)--(3.58,0)
    node[right] {$\mathbf e_2$};
  \draw[densely dashed,line width=.3pt,->] (0,-.95)--(0,2.75)
    node[above] {$\mathbf e_3$};
  \fill (0,0) circle (.035);
  \node[below left] at (-.03,-.05) {$P$};
  % The solid contour is translated and rotated as a rigid section.
  \begin{scope}[shift={(.72,.80)},rotate=12]
    \draw[line width=.65pt]
      (-1.30,0) .. controls (-1.30,.75) and (.92,.73) .. (1.65,0)
      .. controls (.92,-.58) and (-1.30,-.65) .. (-1.30,0) -- cycle;
    \draw[dash pattern=on 3pt off 1.4pt on .6pt off 1.4pt,line width=.3pt]
      (-1.50,0)--(2.40,0);
    \fill (0,0) circle (.035);
    \fill (.72,.21) circle (.035);
    \draw[->,line width=.45pt] (.03,.009)--(.68,.198);
    \node[above] at (.30,.11) {$\mathbf r$};
    \draw[line width=.3pt] (.72,.25)--(.93,.73)--(1.35,.73);
    \node[right] at (1.38,.73) {$C$};
  \end{scope}
  \draw[->,line width=.55pt] (.04,.045)--(.68,.755);
  \node[anchor=north west] at (.10,.40) {$\mathbf u$};
  \draw[line width=.3pt] (.75,.76)--(1.02,.25)--(1.84,.25);
  \node[anchor=west] at (1.89,.25) {$P'$};
  % Two rays and a clean angular dimension for the small torsional component.
  \draw[densely dashed,line width=.3pt] (2.46,.80)--(3.10,.80);
  \draw[->,line width=.4pt] (2.85,.80)
    arc[start angle=0,end angle=12,radius=2.13];
  \node[anchor=west] at (2.98,1.12) {$\theta_1$};
\end{scope}
\end{tikzpicture}
\caption{Separation of prescribed spin and elastic deformation. (a) The rotor axes $\mathbf a_2,\mathbf a_3$ rotate through $\psi(t)$ relative to the fixed frame. (b) Small translation $\mathbf u$ moves a section reference point from $P$ to $P'$, and rotation $\theta_1$ changes its orientation. The section centroid $C$ has offset $\mathbf r$. Dashed outlines denote reference positions; deformation and eccentricity are exaggerated.}\label{fig:kinematics}
\end{figure}
'''

def stacked_stationary():
    body=''
    panels=[(6.6,3.1,'Nacelle $u_X$ (mm)',[('MHT_full_nacelle_ux_m','black,thick','Nacelle')],1000,'a'),(3.3,3.3,'Blade-tip $u_X$ (mm)',[('MHT_full_blade1_tip_ux_m','black,thick','Blade 1'),('MHT_full_blade2_tip_ux_m','black,dashed,thick','Blade 2'),('MHT_full_blade3_tip_ux_m','black,dotted,thick','Blade 3')],1000,'b'),(0,3.1,'Base $M_Y$ (MN m)',[('MHT_full_base_My_Nm','black,thick',None)],1e-6,'c')]
    for pos,height,yl,channels,scale,letter in panels:
        opts=f'at={{(0,{pos}cm)}},anchor=south west,width=.90\\textwidth,height={height}cm,xmin=0,xmax=8,ylabel={{{yl}}},legend columns=3,legend style={{at={{(.5,1.12)}},anchor=south,/tikz/column sep=7pt}},extra description/.code={{\\node[anchor=south east,font=\\small\\bfseries] at (rel axis cs:1,1.05) {{({letter})}};}}'
        opts+=',xlabel={Time (s)}' if letter=='c' else ',xticklabels=\\empty'
        opts+=',ytick={-40,0,40},ymin=-45,ymax=45' if letter=='b' else ',ytick={-4,0,4},ymin=-5,ymax=5'
        body+=panel(opts,''.join(curve('stationary_response_plot','timeS',col,sty,lab if letter=='b' else None,scale=scale) for col,sty,lab in channels))
    return figure(body,r'Stationary response to prescribed support translations. (a) Nacelle and (b) blade-tip displacements relative to the base, in global $X$ components; (c) base bending moment about global $Y$. The panels share time but use separate ordinate scales.','stationary')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,default=DATA/'figures');args=ap.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    figures=numeric_figures();figures.update(geometry=geometry_figure(),kinematics=kinematics_figure(),stationary=stacked_stationary())
    for name,content in figures.items():(args.output/(name+'.tex')).write_text(content)
    print(f'Generated {len(figures)} self-contained figure snippets in {args.output}')
