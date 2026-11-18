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
    """Actual-coordinate orthographic diagrams, with schematic rigid-body symbols."""
    import numpy as np
    g=loadmat(ROOT/'data/geometry/legacy_geometry_v0.mat',simplify_cells=True)['geometry']; xyz=g['coordinates'];conn=g['connectivity']
    # Orthogonal, unit image-plane vectors: undistorted orthographic projection.
    theta=np.deg2rad(14); e=np.array([2**-.5,2**-.5,0]); v=np.array([-np.sin(theta)/2**.5,np.sin(theta)/2**.5,np.cos(theta)])
    def pr(p):return np.array([p@e,p@v])
    def pt(p):return '(%0.5f,%0.5f)'%tuple(p)
    lines=[r'\begin{figure}[tbp]\centering',r'\begin{tikzpicture}[font=\footnotesize,>=stealth]',r'\path[use as bounding box] (0,-.6) rectangle (16.1,8.2);']
    # global model, axes x in cm, reference SI coordinates remain in generator.
    origin=np.array([3.2,.25]);scale=.03
    for i,p in enumerate(xyz):lines.append(r'\coordinate (g%d) at %s;'%(i+1,pt(origin+scale*pr(p))))
    for row in conn:
        a,b=int(row[2]),int(row[3])
        if row[1]!=3:lines.append(r'\draw[line width=%s] (g%d)--(g%d);'%('1pt' if row[1]==1 else '.7pt',a,b))
    for node in [21,57,93]:lines.append(r'\draw[densely dashed] (g130)--(g%d);'%node)
    lines += [r'\draw[double,double distance=1.4pt,line width=.4pt] (g129)--(g130);',r'\draw[thick] (2.85,.25)--(3.55,.25);']
    for h in np.linspace(2.88,3.5,6):lines.append(r'\draw[thin] (%g,.25)--(%g,.07);'%(h,h-.13))
    lines += [r'\draw[<->,thin] (.55,.25)--(.55,4.18) node[midway,left,rotate=90,anchor=south] {135 m};',r'\node[anchor=west] at (3.45,1.8) {Tower};',r'\node[anchor=north west] at ([xshift=3pt]g56) {Blade 1};',r'\node[anchor=north west] at (g92) {Blade 2};',r'\node[anchor=south] at (g128) {Blade 3};',r'\node[anchor=east] at (2.7,5.5) {Upper assembly};\draw[thin,->] (2.5,5.15)--(g129);',r'\node[anchor=north west,font=\small\bfseries] at (0,8.1) {(a)};']
    tri=np.array([4.7,.75]);length=1.15
    for vec,label in [(np.array([1,0,0]),'X'),(np.array([0,1,0]),'Y'),(np.array([0,0,1]),'Z')]:
        anchor={'X':'north west','Y':'south west','Z':'south'}[label]
        lines.append(r'\draw[->,thin] %s--%s node[anchor=%s] {$%s$};'%(pt(tri),pt(tri+length*pr(vec)),anchor,label))
    lines.append(r'\node[anchor=north,font=\scriptsize] at (4.75,.45) {Global frame};')
    # Zoom of real upper connection geometry. Body boxes are explicitly symbols.
    centre=xyz[129];origin=np.array([11.3,4.05]);scale=.27
    for i,p in enumerate(xyz):lines.append(r'\coordinate (d%d) at %s;'%(i+1,pt(origin+scale*pr(p-centre))))
    selected=list(range(124,133))+[18,19,20,54,55,89,90]
    # first two elements per blade are rows19/20,54/55,89/90.
    for idx in selected:
        row=conn[idx];a,b=int(row[2]),int(row[3]);lines.append(r'\draw[thick] (d%d)--(d%d);'%(a,b))
    for n in [20,129,130,21,22,23,57,58,59,93,94,95,131,132,133,134,135,136,137,138]:lines.append(r'\fill (d%d) circle (.6pt);'%n)
    lines += [r'\draw[double,double distance=2pt,line width=.5pt] (d129)--(d130);']
    for node in [21,57,93]:lines.append(r'\draw[densely dashed,thick] (d130)--(d%d);\draw[fill=white,line width=.7pt] (d%d) circle (2.5pt);'%(node,node))
    for node in [129,130]:lines.append(r'\fill (d%d) circle (2.5pt);'%node)
    lines += [r'\node[draw,rounded corners=1pt,fill=white,inner sep=3pt,anchor=south east] at ([xshift=-3pt,yshift=3pt]d129) {Nacelle $M_N$};',r'\node[draw,fill=white,inner sep=3pt,anchor=south west] at ([xshift=4pt,yshift=1pt]d130) {Hub $M_R$};',r'\node[anchor=north west] at ([xshift=4pt,yshift=-3pt]d21) {$B_1$};',r'\node[anchor=north west] at ([xshift=4pt,yshift=-3pt]d57) {$B_2$};',r'\node[anchor=south east] at ([xshift=-4pt,yshift=2pt]d93) {$B_3$};',r'\draw[thin,->] (7.4,3.2) node[above,align=center] {Flexible\\transition} -- (d134);',r'\node[anchor=north east] at ([xshift=-3pt]d20) {Tower top};',r'\draw[thin,->] (9.5,6.2) node[above,align=center] {Elastic drivetrain\\$\mathbf K_d,\mathbf C_d$} -- ($ (d129)!.55!(d130) $);',r'\draw[thin,->] (13.5,3.8) node[right,align=left] {Rigid root\\compatibility} -- ($ (d130)!.6!(d57) $);',r'\node[anchor=north west,font=\small\bfseries] at (7.05,8.1) {(b)};']
    # Axis direction from actual master positions, extended just beyond hub.
    a=(xyz[129]-xyz[128]);a/=np.linalg.norm(a);end=origin+scale*pr(8*a)
    lines.append(r'\draw[->,dashdotted,thin] (13.5,2.1)--(15,1.92) node[anchor=north west] {$\mathbf a,\ \Omega$};')
    lines += [r'\draw[thick] (7.2,-.25)--(7.9,-.25) node[right,font=\scriptsize] {Flexible member};',r'\draw[densely dashed,thick] (10.5,-.25)--(11.2,-.25) node[right,font=\scriptsize] {Rigid tie};',r'\fill (13.1,-.25) circle (2pt);\node[right,font=\scriptsize] at (13.25,-.25) {Master};',r'\draw[fill=white] (14.8,-.25) circle (2pt);\node[right,font=\scriptsize] at (14.95,-.25) {Slave};',r'\end{tikzpicture}',r'\caption{Structural assembly and compatibility. (a) Orthographic view of the actual beam centre lines, fixed base and global frame. (b) Enlarged upper assembly using the same projection: the nine transition beams remain flexible; the nacelle and hub masters remain independent, coupled by a six-component elastic connection; the three blade-root slaves follow the hub through rigid ties. $\mathbf a$ is the nominal rotor-axis direction. Solid/open circles distinguish masters/slaves; body boxes are symbols, not measured outer surfaces. Panels have different scales; coordinates are in metres.}\label{fig:geometry}',r'\end{figure}']
    return '\n'.join(lines)+'\n'

def kinematics_figure():
    return r'''\begin{figure}[tbp]\centering
\begin{tikzpicture}[font=\footnotesize,>=stealth]
\path[use as bounding box] (0,-.2) rectangle (16,5.3);
\node[font=\small\bfseries,anchor=north west] at (0,5.2) {(a)};
\coordinate (O) at (1.6,.65);
\draw[->] (O)--(5.8,.65) node[right] {$\mathbf E_2$};
\draw[->] (O)--(1.6,4.8) node[above] {$\mathbf E_3$};
\draw[densely dotted] (O)--(5.4,.65);
\draw[thick] (O)--(4.2,4.05) coordinate (P);
\draw[black,dashed,thick] (O) .. controls (2.65,1.75) and (3.85,2.5) .. (5.0,3.55) coordinate (D);
\fill (O) circle(2pt);\node[below left] at (O) {Rotor origin};
\draw[->] (2.7,.65) arc[start angle=0,end angle=52.6,radius=1.1];
\node at (3.0,1.25) {$\psi(t)$};
\draw[->,thick] (P)--(D) node[midway,above] {$\mathbf u$};
\draw[->] (P)--(4.65,4.65) node[above] {$\mathbf e_1$};
\draw[->] (P)--(3.55,4.55) node[left] {$\mathbf e_2$};
\draw[->] (D)--(5.62,4.08);
\draw[dotted] (D)--(5.48,4.18);
\node[anchor=west] at (5.55,3.75) {$\boldsymbol\theta$};
\node[align=left,anchor=west] at (3.8,2.0) {Nominal line (solid)\\Perturbed line (dashed)};

\node[align=left,anchor=west] at (8.0,4.45) {$\mathbf r_{sm}(t)=\mathbf Q_\psi(t)\mathbf r_{sm}(0)$};
\node[font=\small\bfseries,anchor=north west] at (7.3,5.2) {(b)};
\coordinate (M) at (9.1,1.5);\coordinate (S) at (13.1,3.4);
\fill (M) circle(2.5pt);\draw[fill=white,thick] (S) circle(2.5pt);
\draw[densely dashed,thick,->] (M)--(S) node[midway,above] {$\mathbf r_{sm}(t)$};
\node[below] at (M) {Master};\node[above] at (S) {Slave};
\draw[->,thick] (M)--(9.9,1.55) node[below right] {$\mathbf u_m$};
\draw[->,thick] (S)--(14.05,3.8) node[right] {$\mathbf u_s$};
\draw[->] (9.85,1.5) arc[start angle=0,end angle=80,radius=.75];
\node[above] at (9.85,2.15) {$\boldsymbol\theta_m$};
\node[align=center] at (11.4,.45) {$\mathbf u_s=\mathbf u_m-\mathbf S(\mathbf r_{sm})\boldsymbol\theta_m$\\$\boldsymbol\theta_s=\boldsymbol\theta_m$};
\end{tikzpicture}
\caption{Kinematic distinction underlying the linear model. (a) Schematic in the nominal plane normal to the rotor axis, with fixed transverse basis $\mathbf E_2,\mathbf E_3$: the solid nominal line undergoes finite prescribed azimuth; the dashed line shows an exaggerated elastic perturbation. The nominal section frame is transported by the prescribed motion, while $\mathbf u$ and $\boldsymbol\theta$ remain small. (b) Moving offset compatibility relates master and slave elastic variables. These are kinematic schematics, not numerical deformation results; only the components needed to explain the relationships are drawn.}\label{fig:kinematics}
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
