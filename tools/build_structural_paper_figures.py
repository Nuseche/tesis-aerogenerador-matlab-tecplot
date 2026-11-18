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
    d={}; left=r'width=.46\textwidth,height=6cm,extra description/.code={\node[anchor=north east,font=\small\bfseries] at (rel axis cs:1,1.18) {(a)};}'; right=r'at={(.52\textwidth,0)},anchor=south west,width=.46\textwidth,height=6cm,extra description/.code={\node[anchor=north east,font=\small\bfseries] at (rel axis cs:1,1.18) {(b)};}'
    body=panel(left+r',xlabel={Flexible elements},ylabel={Frequency discrepancy (\%)},xmode=log,ymode=log,xtick={133,266,532},xticklabels={133,266,532}',curve('mesh_convergence','elements','maxFirst12FrequencyErrorPercent','black,thick,mark=*',predicate=lambda r:float(r['subdivision'])<8))
    body+=panel(right+r',xlabel={Bending mode},ylabel={EB--Timoshenko difference (\%)},xtick={1,2,3,4},ymode=log,legend pos=north west',curve('beam_theory_difference','mode','theoryDifferencePercent','black,thick,mark=*',r'$L/h=10$',lambda r:float(r['slenderness'])==10)+curve('beam_theory_difference','mode','theoryDifferencePercent','black,dashed,thick,mark=square*',r'$L/h=100$',lambda r:float(r['slenderness'])==100))
    d['verification']=figure(body,r'Separate checks of discretization and beam assumptions. Left: maximum error among the first twelve stationary-turbine frequencies relative to 1064 elements. Right: analytical Euler--Bernoulli frequencies compared with a 512-element Timoshenko cantilever, normalized by the Timoshenko frequency. Both beams are 5 m long. The right panel compares different physical hypotheses, not two mesh resolutions.','verification')
    body=panel(r'width=.91\textwidth,height=7cm,xlabel={Rotor speed (rpm)},ylabel={Frequency (Hz)},xmin=.5,xmax=7.44,ymin=0,ymax=1.25,legend columns=4,legend style={at={(.5,1.02)},anchor=south}', ''.join(curve('campbell','rpm',f'frequency_{i}_hz','black!65,thin',r'Sorted frequencies' if i==1 else None) for i in range(1,12))+''.join(r'\addplot[%s,domain=.5:7.44,samples=2] {%s*x/60};\addlegendentry{%sP}'%(sty,k,k) for k,sty in [(1,'black,dotted,thick'),(3,'black,dashed,thick'),(6,'black,dashdotted,thick')]))
    d['campbell']=figure(body,r'Campbell screening from the full 804-coordinate, azimuth-averaged structural operators, without gravity or aerodynamic feedback. The lowest eleven sorted frequencies are shown; lines connect 72 calculated speeds and do not imply persistent mode identities. The 1P, 3P and 6P lines are excitation orders. Crossings require a forcing and observation calculation before they can be identified as resonances.','campbell')
    body=panel(left+r',xlabel={Rotor speed (rpm)},ylabel={Hub axial receptance (m/N)},ymode=log,xmin=.5,xmax=7.44,legend pos=north east', ''.join(curve(f'receptance_{k}P','rpm','hub_axial_m_per_N',s,f'{k}P') for k,s in [(1,'black,dotted,thick'),(3,'black,thick'),(6,'black,dashed,thick')]))
    body+=panel(right+r',xlabel={Rotor speed (rpm)},ylabel={3P receptance ($10^{-5}$ m/N)},ymin=0.5,ymax=4.6,xmin=3.25,xmax=3.65,legend pos=north east', ''.join(curve('receptance_3P','rpm',col,s,lab,lambda r:3.25<float(r['rpm'])<3.65,scale=1e5) for col,s,lab in [('hub_axial_m_per_N','black,thick','Hub'),('nacelle_axial_m_per_N','black,dashed,thick','Nacelle'),('tower_top_axial_m_per_N','black,dotted,thick','Tower top')]))
    d['receptance']=figure(body,r'Axial displacement per unit harmonic force along the nominal rotor axis at the hub. Left: 1P, 3P and 6P responses of the averaged structural system. Right: support participation near the strongest 3P peak. The near-coincident hub and nacelle curves follow from their stiff connection. Refined peak samples are retained; no curves are rescaled to improve agreement. Rayleigh damping is 0.5\% at 0.17 and 1 Hz.','receptance')
    body=panel(left+r',xlabel={Time (s)},ylabel={Tower-top global $X$ (m)},xmin=15,xmax=80,legend pos=north east',curve('nonlinear_history_00','time_s','tower_top_x_m','black,thin',r'$\Omega_{\rm nom}=0$')+curve('nonlinear_history_07','time_s','tower_top_x_m','black,dashed,thin',r'$\Omega_{\rm nom}=0.7$ rad/s'))
    body+=panel(right+r',xlabel={Frequency (Hz)},ylabel={One-sided amplitude (m)},xmin=.1,xmax=.5,ymode=log,legend pos=north east',curve('nonlinear_spectra','frequency_hz','case00_tower_x_m','black,thin',r'$0$ rad/s')+curve('nonlinear_spectra','frequency_hz','case07_tower_x_m','black,dashed,thin',r'$0.7$ rad/s'))
    d['nonlinear']=figure(body,r'Supplied nonlinear reference: tower-top node 400019, not the hub. Left: global $X$ displacement around the 20--21 s nacelle pulse; extrema are preserved in the plotting samples. Right: response spectra from the audited binary histories on the common grid from 25.01 to 1099.99 s, after mean removal, with a rectangular window and $\Delta f\simeq0.00093024$ Hz. Peaks are spectral lines of a finite-amplitude response, not identified eigenvalues.','nonlinear')
    body=panel(left+r',xlabel={Time (s)},ylabel={Base-relative global $X$ (mm)},xmin=0,xmax=8,legend pos=north west', ''.join(curve('stationary_response_plot','timeS',c,s,lab,scale=1000) for c,s,lab in [('MHT_full_nacelle_ux_m','black,thick','Nacelle'),('MHT_full_blade1_tip_ux_m','black,dashed,thin','Blade 1 tip'),('MHT_full_blade2_tip_ux_m','black,dotted,thick','Blade 2 tip'),('MHT_full_blade3_tip_ux_m','black,dashdotted,thin','Blade 3 tip')]))
    body+=panel(right+r',xlabel={Time (s)},ylabel={Base moment $M_Y$ (MN m)},xmin=0,xmax=8',curve('stationary_response_plot','timeS','MHT_full_base_My_Nm','black,thick',scale=1e-6))
    d['stationary']=figure(body,r'Stationary 804-coordinate reference under the two prescribed synthetic base motions. Different blade orientations produce different tip responses despite shared support motion. The base moment is recovered from the full dynamic residual. This zero-speed, unloaded configuration is separate from the rotating receptances and the nonlinear pulse campaign. Plotting uses an extrema-preserving subset of the stored samples; error norms use the full histories.','stationary')
    body=panel(r'width=.88\textwidth,height=6cm,xlabel={Tracked modal group},ylabel={Mean normalized elementary effect},xtick={1,2,3,4,5,6,7},xticklabels={{1+2},3,{4+5},{6+7},{8+9},{10+11},12},xmin=.5,xmax=7.5,ymin=-.14,ymax=.12,unbounded coords=jump,legend columns=3,legend style={at={(.5,1.03)},anchor=south}', ''.join(curve('morris_'+n,'group_index','mu',s.replace('thick,','thick,only marks,'),lab) for n,s,lab in [('blade_density','black,thick,mark=*','Blade mass/inertia'),('blade_stiffness','black,dashed,thick,mark=square*','Blade stiffness'),('rotor_speed','black,dotted,thick,mark=triangle*','Rotor speed')]))
    d['sensitivity']=figure(body,r'Accepted mean elementary effects in the historical frozen-azimuth, gravity-loaded sensitivity campaign. Blade mass/inertia, blade stiffness and rotor speed vary over $\pm10\%$ of the reference values (12 rpm for speed). Grouped frequencies preserve close-mode subspaces. Missing markers denote unresolved or unaccepted effects, not zero sensitivity. Forty trajectories support the reported means; dispersion is a separate acceptance question.','sensitivity')
    body=panel(left+r',xlabel={Retained modes},ylabel={History error (\%)},xmode=log,ymode=log,xtick={12,24,48,96,192},xticklabels={12,24,48,96,192},legend pos=south west', ''.join(curve('rom_errors','modes',c,s,lab) for c,s,lab in [('nacelle_ux_m','black,thick,mark=*','Nacelle $u_X$'),('blade1_tip_ux_m','black,dashed,thick,mark=square*','Blade 1 $u_X$'),('base_My_Nm','black,dotted,thick,mark=triangle*','Base $M_Y$')])+r'\addplot[black!40,dashdotted,domain=12:192,samples=2,forget plot] {1};')
    body+=panel(right+r',xlabel={Retained modes},ylabel={Measured speedup},xmode=log,xtick={12,24,48,96,192},xticklabels={12,24,48,96,192},legend pos=north east',curve('rom_costs','dofs','speedupIntegration','black,thick,mark=*','Integration',lambda r:r['model']!='MHT_full')+curve('rom_costs','dofs','speedupOneCaseIncludingBasis','black,dashed,thick,mark=square*','With preparation',lambda r:r['model']!='MHT_full'))
    d['rom']=figure(body,r'Output-dependent modal reduction for the stationary benchmark. Left: relative $L^2$ history error against the complete model at the same time step; the horizontal line is 1\%. Right: median measured integration speedup, also including basis construction and projection for one case. Assembly, physical output reconstruction and export are excluded from both timing definitions. These results do not measure periodic or aeroelastic integration cost.','rom')
    return d

def geometry_figure():
    """Actual front elevation plus orthogonal connectivity, with no crossing leaders."""
    import numpy as np
    g=loadmat(ROOT/'data/geometry/legacy_geometry_v0.mat',simplify_cells=True)['geometry'];xyz=g['coordinates'];conn=g['connectivity']
    out=[r'\begin{figure}[tbp]\centering',r'\begin{tikzpicture}[font=\footnotesize,>=stealth]',r'\path[use as bounding box] (0,-.25) rectangle (16,8.4);',r'\node[anchor=north west,font=\small\bfseries] at (0,8.35) {(a)};']
    for i,p in enumerate(xyz):out.append(r'\coordinate (g%d) at (%0.5f,%0.5f);'%(i+1,3.25+.0275*p[1],.65+.0275*p[2]))
    for row in conn:
        if row[1]==3:continue
        out.append(r'\draw[line width=%s] (g%d)--(g%d);'%('1pt' if row[1]==1 else '.8pt',int(row[2]),int(row[3])))
    out += [r'\fill (g130) circle (2pt);',r'\draw[thick] (2.9,.65)--(3.6,.65);']
    for x in np.linspace(2.94,3.55,6):out.append(r'\draw[thin] (%g,.65)--(%g,.48);'%(x,x-.12))
    out += [r'\node[anchor=south] at ([yshift=4pt]g128) {Blade 3};',r'\node[anchor=north west] at ([yshift=-4pt]g56) {Blade 1};',r'\node[anchor=north east] at ([yshift=-4pt]g92) {Blade 2};',r'\node[anchor=east] at (2.85,2) {Tower};',r'\draw[thin] (3.25,4.58)--(4.1,5.2)--(5.7,5.2);',r'\node[anchor=south] at (4.9,5.2) {Rotor centre};',r'\draw[thin,<->] (6.15,.65)--(6.15,4.3625) node[midway,right,rotate=90,anchor=south] {135 m};',r'\draw[thin] (5.95,.65)--(6.35,.65);\draw[thin] (5.95,4.3625)--(6.35,4.3625);',r'\draw[->] (.7,.9)--(1.5,.9) node[right] {$Y$};',r'\draw[->] (.7,.9)--(.7,1.8) node[above] {$Z$};',r'\draw (.7,.9) circle (2pt);\fill (.7,.9) circle (.7pt);\node[below left] at (.7,.9) {$X$};',r'\node[anchor=north west,font=\small\bfseries] at (7.1,8.35) {(b)};']
    for x,num in [(8.4,1),(11,2),(13.6,3)]:
        out += [r'\draw[fill=black!3] (%g,7.1) rectangle (%g,7.8);'%(x-.95,x+.95),r'\node at (%g,7.45) {Blade %d};'%(x,num),r'\draw[thick] (%g,7.1)--(%g,6.55);'%(x,x),r'\draw[densely dashed] (%g,6.55)--(%g,5.9);'%(x,x),r'\draw[fill=white,thick] (%g,6.55) circle (2.5pt);'%x,r'\node[anchor=east] at (%g,6.55) {$B_%d$};'%(x-.17,num)]
    out += [r'\draw[densely dashed] (8.4,5.9)--(13.6,5.9);\draw[densely dashed] (11,5.9)--(11,5.45);',r'\node[anchor=west,align=left] at (14,6.15) {Rigid\\ties};',r'\draw[fill=black!3] (9.85,4.75) rectangle (12.15,5.45);\node at (11,5.1) {Hub $M_R$};\fill (11,5.45) circle (2.5pt);',r'\draw (11,4.75)--(11,4.55)--(10.82,4.48)--(11.18,4.34)--(10.82,4.20)--(11.18,4.06)--(10.82,3.92)--(11,3.85)--(11,3.65);',r'\node[anchor=west,align=left] at (12.4,4.2) {Elastic connection\\$\mathbf K_d,\mathbf C_d$};',r'\draw[fill=black!3] (9.85,2.95) rectangle (12.15,3.65);\node at (11,3.3) {Nacelle $M_N$};\fill (11,3.65) circle (2.5pt);',r'\draw (11,2.95)--(11,2.55);',r'\draw[fill=white] (9.4,1.85) rectangle (12.6,2.55);\node[align=center] at (11,2.2) {Flexible transition\\9 beam elements};',r'\draw (11,1.85)--(11,1.45);',r'\draw[fill=white] (9.85,.75) rectangle (12.15,1.45);\node at (11,1.1) {Tower};',r'\draw (11,.75)--(11,.45);\draw[thick] (10.55,.45)--(11.45,.45);']
    for x in np.linspace(10.6,11.4,7):out.append(r'\draw[thin] (%g,.45)--(%g,.28);'%(x,x-.12))
    out += [r'\fill (7.9,-.05) circle (2pt);\node[anchor=west,font=\scriptsize] at (8.1,-.05) {Rigid-body master};',r'\draw[fill=white] (11.6,-.05) circle (2pt);\node[anchor=west,font=\scriptsize] at (11.8,-.05) {Blade-root slave};',r'\end{tikzpicture}',r'\caption{Geometry and mechanical connectivity. (a) Actual beam centre lines projected onto the global $YZ$ plane; $X$ points out of the page. The fixed-base tower is 135 m high. (b) Orthogonal connectivity schematic, not a geometric projection or a scale drawing: the tower and transition are flexible, the nacelle and hub have independent rigid-body inertia, the drivetrain is elastic, and three rigid ties impose root compatibility. The diagram deliberately separates component symbols from their spatial offsets, which enter the assembly through the kinematic relations.}\label{fig:geometry}',r'\end{figure}']
    return '\n'.join(out)+'\n'

def kinematics_figure():
    return r'''\begin{figure}[tbp]\centering
\begin{tikzpicture}[font=\footnotesize,>=stealth]
\path[use as bounding box] (0,-.25) rectangle (16,5.8);
\node[font=\small\bfseries,anchor=north west] at (0,5.7) {(a)};
\coordinate (O) at (1.3,.75);\coordinate (P) at (4.05,4.45);\coordinate (D) at (4.8,4.05);
\draw[->] (O)--(5.7,.75) node[right] {$\mathbf E_2$};
\draw[->] (O)--(1.3,5.2) node[above] {$\mathbf E_3$};
\draw[thick] (O)--(P);
\draw[dashed,thick] (O) .. controls (2.4,2.15) and (3.6,3.2) .. (D);
\fill (O) circle(2pt);\node[below left] at (O) {Rotor origin};
\draw[->] (2.35,.75) arc[start angle=0,end angle=53.4,radius=1.05];\node at (2.65,1.3) {$\psi(t)$};
\draw[->,thick] (P)--(D) node[midway,above] {$\mathbf u$};
\draw[->] (P)--(4.5,5.05) node[above] {$\mathbf e_1$};
\draw[->] (P)--(3.45,4.9) node[left] {$\mathbf e_2$};
\draw[thin,dotted] (D)--(5.4,4.85);\draw[->,thin] (D)--(5.65,4.65);
\node[anchor=west] at (5.55,4.9) {$\boldsymbol\theta$};
\draw[thick] (3.6,2.0)--(4.15,2.0);\node[anchor=west] at (4.3,2.0) {Nominal line};
\draw[dashed,thick] (3.6,1.55)--(4.15,1.55);\node[anchor=west] at (4.3,1.55) {Perturbed line};
\node[font=\small\bfseries,anchor=north west] at (7.4,5.7) {(b)};
\node at (11.6,4.9) {$\mathbf r_{sm}(t)=\mathbf Q_\psi(t)\mathbf r_{sm}(0)$};
\coordinate (M) at (9,2);\coordinate (S) at (13.5,2);
\draw[densely dashed,->] (M)--(S) node[midway,below] {$\mathbf r_{sm}(t)$};
\fill (M) circle(2.5pt);\draw[fill=white,thick] (S) circle(2.5pt);
\node[below left] at (M) {Master};\node[below right] at (S) {Slave};
\draw[->,thick] (M)--(9,2.9);\node[anchor=east] at (8.85,2.4) {$\mathbf u_m$};
\draw[->,thick] (S)--(13.5,3.5) node[above right] {$\mathbf u_s$};
\draw[thin,dotted] (9,2.9)--(13.5,3.5);
\draw[->] (8.45,2.9) arc[start angle=180,end angle=85,radius=.55];
\node[anchor=east] at (8.3,3.55) {$\boldsymbol\theta_m$};
\node at (11.3,.9) {$\mathbf u_s=\mathbf u_m-\mathbf S(\mathbf r_{sm})\boldsymbol\theta_m$};
\node at (11.3,.4) {$\boldsymbol\theta_s=\boldsymbol\theta_m$};
\end{tikzpicture}
\caption{Nominal motion and elastic compatibility. (a) Prescribed finite azimuth in the plane normal to the rotor axis, with fixed transverse basis $\mathbf E_2,\mathbf E_3$. The solid nominal line carries the section frame; the dashed line illustrates exaggerated small elastic displacement and rotation. (b) An instantaneous master--slave offset, drawn horizontally for clarity. Elastic translations and equal infinitesimal rotations obey the displayed compatibility; the dotted line joins the perturbed points. These are explanatory kinematic schematics, not solved deformation fields.}\label{fig:kinematics}
\end{figure}
'''

def stacked_stationary():
    body=''
    panels=[(6.6,3.1,'Nacelle $u_X$ (mm)',[('MHT_full_nacelle_ux_m','black,thick','Nacelle')],1000,'a'),(3.3,3.3,'Blade-tip $u_X$ (mm)',[('MHT_full_blade1_tip_ux_m','black,thick','Blade 1'),('MHT_full_blade2_tip_ux_m','black,dashed,thick','Blade 2'),('MHT_full_blade3_tip_ux_m','black,dotted,thick','Blade 3')],1000,'b'),(0,3.1,'Base $M_Y$ (MN m)',[('MHT_full_base_My_Nm','black,thick',None)],1e-6,'c')]
    for pos,height,yl,channels,scale,letter in panels:
        opts=f'at={{(0,{pos}cm)}},anchor=south west,width=.90\\textwidth,height={height}cm,xmin=0,xmax=8,ylabel={{{yl}}},legend columns=3,legend style={{at={{(.5,1.12)}},anchor=south}},extra description/.code={{\\node[anchor=south east,font=\\small\\bfseries] at (rel axis cs:1,1.05) {{({letter})}};}}'
        opts+=',xlabel={Time (s)}' if letter=='c' else ',xticklabels=\\empty'
        opts+=',ytick={-40,0,40},ymin=-45,ymax=45' if letter=='b' else ',ytick={-4,0,4},ymin=-5,ymax=5'
        body+=panel(opts,''.join(curve('stationary_response_plot','timeS',col,sty,lab if letter=='b' else None,scale=scale) for col,sty,lab in channels))
    return figure(body,r'Stationary full-model response under the two prescribed synthetic base motions, in global components. (a) Nacelle displacement; (b) three blade-tip displacements; (c) base moment recovered from the full dynamic residual. Displacements are relative to the base. Common support excitation produces different tip responses through geometry and participation. The three panels share time but have separate ordinate scales. Plotting preserves extrema; error norms use all stored samples.','stationary')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,default=DATA/'figures');args=ap.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    figures=numeric_figures();figures.update(geometry=geometry_figure(),kinematics=kinematics_figure(),stationary=stacked_stationary())
    for name,content in figures.items():(args.output/(name+'.tex')).write_text(content)
    print(f'Generated {len(figures)} self-contained figure snippets in {args.output}')
