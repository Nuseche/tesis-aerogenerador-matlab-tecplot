"""Figures from persisted results only. Never imports or runs the solver."""
from common import *
import hdf5storage

EVID = ROOT/'data/reference/operating_results.json'
MORRIS = ROOT/'runs/sensitivity/morris_20261006'
LOCAL = ROOT/'runs/sensitivity/initial_20261005'
MODAL = ROOT/'runs/run_20260919_182410_438_gyro_energy_corrected_20260919'
SEISMIC = ROOT/'runs/run_20260919_183052_480_gyro_corrected_seismic_20260919'
HIST = ROOT/'runs/run_20260914_mecom_comparison'
DOC = 'docs/verification.md'

def unwrap(x):
    while isinstance(x,np.ndarray) and x.dtype.names and x.size==1:x=x.reshape(-1)[0]
    return x

def field(x,*names):
    for n in names:x=unwrap(x)[n]
    return unwrap(x)

def sparse(x):
    from scipy.sparse import csc_matrix
    x=unwrap(x);n=len(x['jc'].ravel())-1
    return csc_matrix((x['data'].ravel(),x['ir'].ravel().astype(int),x['jc'].ravel().astype(int)),shape=(n,n))

def result(name,title,source,xlabel,ylabel,**kw):
    return Figure(name,title,kind='result',source=source,document=[DOC],xlabel=xlabel,ylabel=ylabel,**kw)

def mesh_xy(name,title,xyz,elements,axes=(1,2),bounds=None,ids=False):
    f=Figure(name,title,kind='computational_beam_mesh',source=[MODAL/'model_snapshot.mat'],document=[DOC],xlabel='XYZ'[axes[0]]+' [m]',ylabel='XYZ'[axes[1]]+' [m]',legend=False,bounds=bounds,height=5.6)
    for e in elements:
        i,j=int(e[1])-1,int(e[2])-1;c=int(e[4]) if e[4] else (6 if e[0]<20 else 7)
        f.line(xyz[[i,j]][:,axes],color=c,symbols=ids)
    if ids:
        selected=sorted(set(int(n) for e in elements for n in e[1:3]))
        for n in selected:
            x,y=xyz[n-1,list(axes)];f.label(x+.25,y+.2,str(n),8)
    f.config={'projection_axes':[int(a)+1 for a in axes],'axis_equal_scale':True}
    return f

def mesh3d(name,title,xyz,elements,reference=None,ordered=None,source=None,config=None):
    """True FELINESEG connectivity; optional reference and ordered axes/paths."""
    path=HERE/'data'/f'{name}.dat';styles=[]
    with path.open('w') as f:
        f.write('TITLE="'+txt(title)+'"\nVARIABLES="X [m]" "Y [m]" "Z [m]" "NodeID"\nDATASETAUXDATA Representation="beam_centerline_only"\n')
        for x,n,c in [(xyz,'Deformed',0)]+([(reference,'Reference',7)] if reference is not None else []):
            for b in range(5):
                subset=[e for e in elements if (int(e[4]) if e[4] else (0 if e[0]<20 else 4))==b]
                if not subset:continue
                label=n+' '+['Tower','Blade 1','Blade 2','Blade 3','Transition'][b]
                f.write(f'ZONE T="{label}", N={len(x)}, E={len(subset)}, DATAPACKING=POINT, ZONETYPE=FELINESEG\n')
                np.savetxt(f,np.c_[x,np.arange(1,len(x)+1)],fmt='%.17g')
                np.savetxt(f,np.array([[int(e[1]),int(e[2])] for e in subset]),fmt='%d')
                styles.append((c if reference is not None else [6,0,1,2,7][b],False))
        for p,label,c in ordered or []:
            p=np.asarray(p);f.write(f'ZONE T="{txt(label)}", I={len(p)}, DATAPACKING=POINT\n');np.savetxt(f,np.c_[p,np.zeros(len(p))],fmt='%.17g');styles.append((c,True))
    s=['#!MC 1410','$!NewLayout','$!FrameLayout Width = 7 Height = 5.6 ShowBorder = No',f"$!ReadDataSet '\"{path}\"'",'$!PlotType = Cartesian3D'];colors(s)
    s += ['$!FieldLayers ShowMesh = Yes ShowContour = No ShowShade = No ShowEdge = No','$!ThreeDAxis AxisMode = XYZDependent DepXToYRatio = 1 DepXToZRatio = 1 AspectRatioLimit = 1000 BoxAspectRatioLimit = 1000 FrameAxis { Show = Yes Size = 6 XYPos { X = 9 Y = 14 } } GridArea { IsFilled = No FillColor = White UseLightSourceToFill = No DrawBorder = No }']
    for i,(c,ordered_) in enumerate(styles,1):s += [f'$!FieldMap [{i}] Mesh {{ Show = Yes Color = {COLORS[c]} LineThickness = 0.25 }}']
    for axis in ['X','Y','Z']:s.append(f"$!ThreeDAxis {axis}Detail {{ ShowAxis = {'Yes' if name.startswith('morris') or axis=='Z' else 'No'} AxisLine {{ Show = Yes LineThickness = 0.15 }} Title {{ TitleMode = UseText Offset = 7 Text = '{axis} [m]' TextShape {{ SizeUnits = POINT Height = {12 if name.startswith('morris') else 9} IsBold = No }} }} TickLabel {{ Skip = {2 if name.startswith('morris') else 1} TextShape {{ SizeUnits = POINT Height = {10 if name.startswith('morris') else 8} IsBold = No }} }} GridLines {{ Show = No }} }}")
    s += ['$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No','$!View Fit','$!ThreeDView ViewWidth *= 1.25']
    # No embedded title/footer; the LaTeX document supplies the caption.
    exports(s,name);(HERE/'macros'/f'{name}.mcr').write_text('\n'.join(s)+'\n')
    return dict(id=name,purpose=title,representation='computational_beam_mesh' if reference is None else 'deformed_beam_mesh',sources=[str(p) for p in (source or [MODAL/'model_snapshot.mat'])],documents=[DOC],units={'coordinates':'m'},configuration=config or {'uniform_geometric_scale':True},dataset=f'data/{name}.dat',macro=f'macros/{name}.mcr',layout=f'layouts/{name}.lay',package=f'layouts/{name}.lpk',exports=[f'figures/{name}.{e}' for e in ['eps','pdf','png']],notes=['No visualization surfaces are interpreted as a physical mesh.'],generator='Tecplot batch macros')

def build():
    j=json.loads(EVID.read_text());xyz=np.asarray(j['geometry']['nodeCoordinates_m']);els=np.asarray(j['geometry']['elements'],int)
    raw=field(hdf5storage.loadmat(ROOT/'data/geometry/legacy_geometry_v0.mat')['geometry'])
    rawxyz=np.asarray(raw['coordinates']);rawconn=np.asarray(raw['connectivity']);assert np.array_equal(xyz,rawxyz)
    keep=rawconn[:,1]!=3;assert np.array_equal(els[:,1:3],rawconn[keep,2:4]);assert len(els)==133
    ax=np.array(j['geometry']['rotorAxis']['direction']);axis=(xyz[129]-xyz[128]);axis/=np.linalg.norm(axis);assert np.allclose(axis,ax,rtol=0,atol=1e-15)
    checks={'nodes':len(xyz),'elements':len(els),'components':j['geometry']['summary']['elementCountByType'],'raw_coordinates_equal':True,'connectivity_after_explicit_type3_removal_equal':True,'removed_legacy_type3':rawconn[~keep,0].tolist(),'rotor_axis':ax.tolist(),'source_geometry_sha256':sha(ROOT/'data/geometry/legacy_geometry_v0.mat'),'new_solver_evaluations':0,'modal_gate':j['modalGates']['passed'],'seismic_gate':j['seismic']['gates']['passed']}
    ordered=[(np.vstack([xyz[128]-20*ax,xyz[129]+20*ax]),'Actual axis 129-130',1)]
    native=[mesh3d('mesh_3d','Computational mesh: 138 nodes, 133 beams',xyz,els,ordered=ordered)]
    figs=[]
    for a,b,label in [(0,2,'xz'),(1,2,'yz'),(0,1,'xy')]:
        f=mesh_xy('mesh_'+label,'Computational mesh: projection '+label.upper(),xyz,els,(a,b));f.width=3.2 if label!='yz' else 5.5;f.height=6.5;f.notes=['Uniform geometric scale; coordinates in metres.'];figs.append(f)
    roots=[e for e in els if int(e[1]) in [21,57,93] or int(e[2]) in [21,57,93]]
    # Include actual MPC root-hub links in a dedicated overlay, never as beams.
    f=mesh_xy('detail_roots','Roots, hub and rotor axis',xyz,roots,(1,2),bounds=[-18,18,127,162],ids=True)
    f.bounds=[-11,11,134,154]
    for n in [21,57,93]:f.line(xyz[[129,n-1]][:,[1,2]],color=1,pattern='DASHED')
    f.label(1,xyz[129,2],'130',10);f.notes=['Dashed lines: hub-root MPC links, not beams.'];figs.append(f)
    f=mesh_xy('detail_nacelle','Flexible transition and masters 129-130',xyz,els[els[:,0]>=125],(0,2),bounds=[-10,16,132,147],ids=True)
    f.line(xyz[[128,129]][:,[0,2]],'Axis / nacelle-hub connection',1,pattern='DASHED').label(9.5,144.3,'130: hub',10,1);f.notes=['Nacelle-hub connection: separate operator, not a type-3 element.'];figs.append(f)
    f=mesh_xy('detail_base','Fixed base: node 1, six constrained DOFs',xyz,els[:3],(0,2),bounds=[-6,6,-1,28],ids=True);f.notes=['Fixed-base snapshot; the solver is unchanged.'];figs.append(f)
    # Local beam frames from the actual independent auxiliary points.
    errors=[]
    e=els[19];p=xyz[e[1]-1];q=xyz[e[2]-1];aux=np.asarray(raw['coorP1aux'])[0];e1=(q-p)/np.linalg.norm(q-p);e3=aux-p;e3-=np.dot(e3,e1)*e1;e3/=np.linalg.norm(e3);e2=np.cross(e3,e1);R=np.vstack([e1,e2,e3]);checks['root_frame_orthogonality_error']=float(np.linalg.norm(R@R.T-np.eye(3)));checks['root_frame_determinant']=float(np.linalg.det(R))
    from spatial import Scene
    from kinematics import e as director
    scene=Scene('beam_local_frame','Local 3D frame of the actual blade-1 root element')
    scene.line([p,q],0,.0,.28).dot(p).dot(q).label(p-.45*e1,'I = '+str(e[1]),11).label(q+.55*e1,'J = '+str(e[2]),11)
    scene.basis(p,R.T,2.2,[director(i) for i in [1,2,3]])
    localframe=scene.export();localframe.update(representation='computational_beam_mesh',sources=[str(ROOT/'data/geometry/legacy_geometry_v0.mat')],documents=[DOC],units={'coordinates':'m'},notes=['Actual coordinates; right-handed frame from the independent auxiliary point. R maps global to local; e2 = e3 x e1. Displayed local-axis length: 2.2 m.'])
    localpath=HERE/localframe['dataset'];localpath.write_text(localpath.read_text().replace('"X_design" "Y_design" "Z_design"','"X [m]" "Y [m]" "Z [m]"').replace('conceptual_3D_not_physical_mesh','actual_beam_element_with_local_directors'))
    native.append(localframe)
    # Properties: actual piecewise section fields, plotted at element midpoints.
    sections={int(r['sectionId']):r for r in readcsv(LOCAL/'local/nominal_sections.csv')}
    for comp,select in [('tower',els[:19]),('blade',els[19:54])]:
        lengths=np.linalg.norm(xyz[select[:,2]-1]-xyz[select[:,1]-1],axis=1);mid=np.cumsum(lengths)-lengths/2
        for family,fields_,unit in [('mass',['massPerLength_kg_m'],'kg/m'),('bending',['EIy_Nm2','EIz_Nm2'],'N m^2'),('axial_shear',['EA_N','GAy_N','GAz_N'],'N'),('torsion',['GJ_Nm2'],'N m^2'),('inertias',['Jx_kg_m','Jy_kg_m','Jz_kg_m'],'kg m')]:
            f=result('section_'+comp+'_'+family,'Properties of '+comp+': '+family,[LOCAL/'local/nominal_sections.csv',MODAL/'model_snapshot.mat'],'s [m]',unit)
            for c,key in enumerate(fields_):
                vals=np.array([float(sections[int(e[3])][key]) for e in select]);xy=[]
                edges=np.r_[0,np.cumsum(lengths)]
                for i,v in enumerate(vals):xy.extend([[edges[i],v],[edges[i+1],v]])
                f.line(xy,key.split('_')[0],c)
            f.notes=['Piecewise section field; blade Jx follows the declared Jy+Jz rule.'];figs.append(f)
    # Corrected September Campbell and branch tracking, no Floquet statement.
    m=j['modal'];rpm=np.asarray(m['speed_rpm']);freq=np.asarray(m['dampedFrequency_Hz']);mac=np.asarray(m['effectiveTrackingMAC'])
    for name,title,a,yl in [('campbell','Campbell diagram: corrected energy formulation',freq,'Damped frequency [Hz]'),('branch_tracking','Shape-based branch tracking',mac,'MAC efectivo [-]')]:
        f=result(name,title,[MODAL/'results.mat',EVID],'Speed [rpm]',yl)
        for b in range(a.shape[1]):f.line(np.c_[rpm,a[:,b]],'Branch '+str(b+1),b%8,'SOLID' if b<8 else 'DASHED',symbols=True)
        f.notes=['Frozen-azimuth operators; partial spectrum, not Floquet analysis.'];figs.append(f)
    pts=j['equilibrium']['points']
    f=result('equilibrium_speed','Stored equilibrium versus speed',[MODAL/'equilibrium.mat',EVID],'Speed [rpm]','Maximum ||u|| nodal [m]')
    f.line([[p['speed_rpm'],p['maxNodalTranslationNorm_m']] for p in pts],'Maximum translation',symbols=True);figs.append(f)
    # Individual complex branches, phase and visualization normalization explicit.
    record=field(hdf5storage.loadmat(MORRIS/'nominal.mat')['record'],'result');sol=field(record,'solution');phi=np.asarray(sol['fullModes']);q=np.asarray(field(record,'state','qFull')).ravel().reshape(-1,6)[:,:3]
    state=field(record,'state');checks['nominal_equilibrium_residual']=float(np.asarray(state['residualRelative']).squeeze());checks['mode_count']=phi.shape[1]
    M=sparse(record['fullMass']);mass=[];mpc=[]
    native.append(mesh3d('equilibrium_shape','Nominal Morris equilibrium: amplification 20',xyz+20*q,els,reference=xyz,source=[MORRIS/'nominal.mat',MODAL/'model_snapshot.mat'],config={'displacement_unit':'m','amplification':20,'speed_rpm':12,'phase':'not applicable'}))
    export=[]
    for b in range(phi.shape[1]):
        v=phi[:,b];d=v.reshape(-1,6);translations=d[:,:3];pivot=int(np.argmax(np.abs(translations)));pv=translations.ravel()[pivot];angle=-float(np.angle(pv));v=v*np.exp(1j*angle);d=v.reshape(-1,6);norm=float(np.max(np.linalg.norm(d[:,:3],axis=1)));mass.append(float(np.real(phi[:,b].conj()@(M@phi[:,b]))))
        rerr=[]
        for root in [21,57,93]:
            r=xyz[root-1]-xyz[129];rerr.append(np.linalg.norm(d[root-1,:3]-d[129,:3]-np.cross(d[129,3:6],r))/max(norm,1e-30))
        mpc.append(float(max(rerr)))
        for phase in [0,90]:
            u=np.real(d[:,:3]*np.exp(1j*np.deg2rad(phase)))/norm;name=f'mode_{b+1:02d}_phase_{phase:02d}'
            config={'branch':b+1,'frequency_Hz':float(np.asarray(sol['frequencyHz']).ravel()[b]),'phase_deg':phase,'phase_alignment_rad':angle,'pivot_translation_flat_index_zero_based':pivot,'normalization':'max nodal complex translation norm = 1','original_max_translation_norm':norm,'original_generalized_mass':mass[-1],'display_amplitude_m':10,'original_right_QEP_residual':float(np.asarray(sol['residual']).ravel()[b]),'original_left_QEP_residual':float(np.asarray(sol['leftResidual']).ravel()[b]),'mpc_relative_residual':mpc[-1],'group_averaging':False}
            native.append(mesh3d(name,f'Branch {b+1}; phase {phase} deg; display amplitude 10 m',xyz+10*u,els,reference=xyz,source=[MORRIS/'nominal.mat',MODAL/'model_snapshot.mat'],config=config));export.append(config)
    dump(HERE/'reports/modes.json',export);checks['modal_generalized_masses']=mass;checks['modal_max_mpc_relative_residual']=max(mpc)
    # Corrected seismic histories. All node axes and units remain explicit.
    for node in [129,56]:
        for channel,idx,unit in [('displacementRelative_m',0,'m'),('accelerationAbsolute_m_s2',0,'m/s^2')]:
            name=f'seismic_n{node}_'+('ux' if 'displacement' in channel else 'ax')
            f=result(name,f'Synthetic earthquake: node {node}, global X axis',[SEISMIC/'action09_matrices.mat',EVID],'t [s]',unit)
            for c,case in enumerate(j['seismic']['cases']):
                n=next(n for n in case['nodes'] if n['nodeId']==node);f.line(np.c_[case['time_s'],np.asarray(n[channel])[:,idx]],str(case['speed_rpm'])+' rpm',c)
            f.notes=['Synthetic verification input, not a design accelerogram.'];figs.append(f)
    f=result('seismic_reaction','Base moment My: synthetic earthquake',[SEISMIC/'action09_matrices.mat',EVID],'t [s]','My [N m]')
    for c,case in enumerate(j['seismic']['cases']):f.line(np.c_[case['time_s'],case['baseReaction']['momentY_Nm']],str(case['speed_rpm'])+' rpm',c)
    figs.append(f)
    f=result('seismic_convergence','Stored time-step comparison',[SEISMIC/'action09_matrices.mat',EVID],'t [s]','u<sub>y</sub> node 129 [m]')
    for c,case in enumerate(j['seismic']['convergenceHistories']):f.line(np.c_[case['time_s'],case['displacement_m']],f"dt = {case['timeStep_s']:.5g} s",c)
    figs.append(f)
    # Separate historical stopped-rotor ROM benchmark.
    h=j['stationaryHistorical'];models=h['models'];t=np.asarray(h['time_s'])
    for out in [0,2,5,7]:
        f=result('rom_history_'+str(out),'Stationary MHT/ROM: '+h['outputNames'][out],[HIST/'global_raw_data.mat',EVID],'t [s]',h['outputUnits'][out])
        for c,model in enumerate(models):f.line(np.c_[t,np.asarray(model['valuesTimeByOutput'])[:,out]],model['modelName'].replace('MHT_full','MHT').replace('MHT_ROM','ROM'),c,'SOLID' if c==0 else 'DASHED')
        f.notes=['Historical benchmark at 0 rpm without gravity or preload.'];figs.append(f)
    cost=readcsv(HIST/'global_costs.csv');errors=readcsv(HIST/'global_response_errors.csv');roms=[r for r in cost if r['model']!='MHT_full']
    for metric,unit,label in [('speedupIntegration','[-]','Integration speedup'),('speedupOneCaseIncludingBasis','[-]','Speedup including basis and projection'),('operatorAndBasisBytes','bytes','Storage'),('massParticipationXPercent','%','X-load participation')]:
        f=result('rom_'+metric,label,[HIST/'global_costs.csv'],'ROM order',unit,logx=False,legend=False)
        f.line([[float(r['dofs']),float(r[metric])/(1000 if metric=='operatorAndBasisBytes' else 1)] for r in roms],label,symbols=True)
        if metric=='operatorAndBasisBytes':f.ylabel='Storage [kB]';f.config['bytesPerKB']=1000
        elif metric=='massParticipationXPercent':f.ylabel='X inertial load [%]'
        else:f.ylabel='Speedup [-]'
        f.notes=['Historical timings on the original computer; not remeasured.'];figs.append(f)
    f=result('rom_error','History error versus modal order',[HIST/'global_response_errors.csv'],'ROM order','Relative error [%]',logx=False,logy=True)
    for c,output in enumerate(sorted(set(r['output'] for r in errors))):
        rr=[r for r in errors if r['output']==output and r['model']!='MHT_full'];f.line([[int(r['model'].split('ROM')[1]),float(r['historyErrorPercent'])] for r in rr],{'base_My_Nm': 'My base', 'blade1_tip_ax_absolute_mps2': 'tip ax 1', 'blade1_tip_ux_m': 'tip ux 1', 'blade2_tip_ux_m': 'tip ux 2', 'blade3_tip_ux_m': 'tip ux 3', 'nacelle_ax_absolute_mps2': 'nacelle ax', 'nacelle_ux_m': 'nacelle ux', 'nacelle_uy_m': 'nacelle uy'}[output],c,symbols=True)
    f.notes=['Original data; lines connect evaluated orders.'];figs.append(f)
    ms=readcsv(ROOT/'runs/run_20260914_mecom_mesh_refinement/mesh_summary.csv');f=result('refinement','Stored refinement: first twelve frequencies',[ROOT/'runs/run_20260914_mecom_mesh_refinement/mesh_summary.csv'],'Elements','Maximum error [%]',logx=False,logy=True)
    f.line([[float(r['elements']),float(r['maxFirst12FrequencyErrorPercent'])] for r in ms if float(r['maxFirst12FrequencyErrorPercent'])>0],'Relative to 1064 elements',symbols=True);f.notes=['Numerical h8 reference; not a convergence check for 192 modes.'];figs.append(f)
    sv=j['rigidModeHistorical']['stiffnessSingularValues']['columns'];f=result('rigid_kernel','Rigid kernel: stored singular values',[EVID,ROOT/'runs/run_20260914_mecom_rigid_modes/rigid_mode_evidence.mat'],'Ascending index','sigma / sigma_max [-]',logy=True)
    for c,case in enumerate(sorted(set(sv['caseName']))):
        data=[[float(sv['ascendingIndex'][i]),float(sv['normalizedSingularValue'][i])] for i,v in enumerate(sv['caseName']) if v==case and sv['scaling'][i]=='diagonal_equilibrated' and float(sv['normalizedSingularValue'][i])>0 and float(sv['ascendingIndex'][i])<=12]
        if data:f.line(sorted(data),{'global_fixed_804':'Fixed base (804)','global_free_810':'Free system (810)','primitive_12':'Element (12)'}.get(case,case),c,symbols=True)
    f.notes=['Exact zeros omitted on the logarithmic scale and retained in the source dataset.'];figs.append(f)
    # Local sensitivity with signs and unresolved outcomes retained in CSV.
    lr=readcsv(LOCAL/'local/local_sensitivity.csv');groups=sorted(set(r['modeOrGroup'] for r in lr if r['identity']=='group_centroid'),key=lambda s:int(s.split('+')[0]));pars=sorted(set(r['parameter'] for r in lr))
    f=result('local_signed','Local sensitivity: candidates and acceptance status',[LOCAL/'local/local_sensitivity.csv'],'Group index','Normalized sensitivity [-]',legend=True,bounds=[.7,4.7,-.49,.60])
    accepted=[];unresolved=[]
    for pi,p in enumerate(pars):
        data=[];bad=[]
        for gi,g in enumerate(groups,1):
            rr=[r for r in lr if r['parameter']==p and r['modeOrGroup']==g and r['identity']=='group_centroid' and r['response']=='frequency'];rr=sorted(rr,key=lambda r:abs(float(r['step'])-.01))
            if not rr:continue
            r=rr[0];ok=all(r[k]=='1' for k in ['signalResolved','trackingValid','stepConverged']) and np.isfinite(number(r['sensitivity']))
            (accepted if ok else unresolved).append(r)
            if np.isfinite(number(r['sensitivity'])):(data if ok else bad).append([gi+pi*.045,number(r['sensitivity'])])
        if data:f.line(data,p,pi,symbols=True,only=True,filled=True)
        if bad:f.line(bad,'' if data else p,pi,symbols=True,only=True,filled=False)
    f.notes=['Groups: 1=1+2, 2=6+7, 3=8+9, 4=10+11.','Filled: accepted. Open: unresolved; candidates are not interpreted as accepted physical effects. Full status in local_status.csv.'];figs.append(f)
    with (HERE/'data/local_status.csv').open('w') as o:
        w=csv.DictWriter(o,fieldnames=list(lr[0])+['displayAccepted']);w.writeheader();w.writerows([dict(r,displayAccepted=r in accepted) for r in accepted+unresolved])
    checks['local_display_accepted']=len(accepted);checks['local_display_unresolved']=len(unresolved)
    # Morris: full status for all seven groups, including excluded groups.
    meta=json.loads((ROOT/'studies/morris/report_data.json').read_text());stats=[r for r in meta['statistics'] if r['response']=='frequency'];gp=[r['group'] for r in meta['groups']];par=['blade_density','blade_stiffness','rotor_speed'];pl=['Mass/inertia','Stiffness','Speed']
    f=Figure('morris_workflow', 'Morris design, stored responses, and checks', bounds=[0,10,0,6], legend=False);f.name='morris_workflow';f.document=[];f.source=[MORRIS/'campaign.json',MORRIS/'morris_estimators.csv']
    for i,(x,y,l) in enumerate([(1.5,4.5,'Domain'),(5,4.5,'Trajectories'),(8.5,4.5,'MAT cases'),(8.5,1.5,'Tracking'),(5,1.5,'Effects / noise'),(1.5,1.5,'Acceptance')]):f.rect(x-1.2,y-.45,2.4,.9).label(x,y,l,11)
    for a,b in [([2.7,4.5],[3.8,4.5]),([6.2,4.5],[7.3,4.5]),([8.5,4],[8.5,2]),([7.3,1.5],[6.2,1.5]),([3.8,1.5],[2.7,1.5])]:f.arrow(a,b,0)
    figs.append(f)
    verts=readcsv(MORRIS/'morris_vertices.csv');trajectory=[]
    for k in range(1,41):
        rr=sorted([r for r in verts if int(r['trajectory'])==k],key=lambda r:int(r['vertex']));trajectory.append((np.array([[float(r[f'factor_{i}']) for i in [1,2,3]] for r in rr]),'Trajectory '+str(k),k%8))
    # Use true 3D paths in factor space. Coordinate labels are overridden below.
    for name,paths,title in [('morris_trajectory',trajectory[:1],'First stored trajectory'),('morris_trajectories',trajectory,'40 stored trajectories')]:
        entry=mesh3d(name,title,np.empty((0,3)),np.empty((0,5)),ordered=paths,source=[MORRIS/'morris_vertices.csv'],config={'factor_space':'mass/inertia, blade stiffness, speed','bounds':[.9,1.1],'seed':meta['seed'],'schematic':False});entry['representation']='exploratory_design';entry['documents']=['studies/README.md'];entry['units']={'coordinates':'dimensionless factors'}
        dp=HERE/entry['dataset'];dp.write_text(dp.read_text().replace('"X [m]" "Y [m]" "Z [m]"','"Mass/inertia [-]" "Stiffness [-]" "Speed [-]"').replace('Representation="beam_centerline_only"','Representation="exploratory_factor_paths"'))
        p=HERE/'macros'/f'{name}.mcr';s=p.read_text().replace("Text = 'X [m]'","Text = 'Mass/inertia [-]'").replace("Text = 'Y [m]'","Text = 'Stiffness [-]'").replace("Text = 'Z [m]'","Text = 'Speed [-]'");p.write_text(s);native.append(entry)
    for metric,title,yl in [('signed','Signed Morris elementary effects','mu / 0.20 [-]'),('influence','Morris influence','mu* [-]'),('noise','Influence relative to noise','mu* / noise envelope [-]')]:
        f=result('morris_'+('signed' if metric=='signed' else 'influence' if metric=='influence' else 'noise'),title,[MORRIS/'morris_estimators.csv',ROOT/'studies/morris/report_data.json'],'Group index',yl,logy=metric=='noise',bounds=[.4,7.6,-.7,.7] if metric=='signed' else None)
        for c,p in enumerate(par):
            ok=[];bad=[]
            for gi,g in enumerate(gp,1):
                r=next(r for r in stats if r['parameter']==p and r['group']==g)
                if r['mu'] is None or r['muStar'] is None:continue
                v=r['mu']/.2 if metric=='signed' else r['muStar'] if metric=='influence' else r['muStar']/r['muNoiseBound']
                (ok if r['acceptedMean'] else bad).append([gi+(c-1)*.08,v])
            if ok:f.line(ok,pl[c]+' accepted',[0,2,1][c],symbols=True,only=True,filled=True)
            if bad:f.line(bad,pl[c]+' unresolved',[0,2,1][c],symbols=True,only=True)
        if metric=='noise':f.line([[.4,10],[7.6,10]],'Threshold 10',6,pattern='DASHED')
        f.notes=['Groups: '+', '.join(f'{i+1}={g}' for i,g in enumerate(gp)),'Filled: accepted mean. Open: unresolved. Group 12 excluded; no estimator.'];f.document=['studies/README.md'];figs.append(f)
    e=readcsv(LOCAL/'local/modal_energy_evidence.csv');f=result('morris_participation','Blade participation in individual branches 10 and 11',[LOCAL/'local/modal_energy_evidence.csv'],'Branch','Participation [%]',bounds=[9.5,11.5,0,105])
    for c,k in enumerate(['bladeMassFraction','bladeElasticFraction']):f.line([[float(r['mode']),100*float(r[k])] for r in e if r['mode'] in ['10','11']],['Mass','Elastic stiffness'][c],c,symbols=True)
    f.notes=['Reference quadratic forms, not the complete rotating-system energy.'];f.document=['studies/README.md'];figs.append(f)
    sweep=readcsv(MORRIS/'morris_sweeps.csv');slice_={}
    for r in sweep:
        if r['group']=='10+11' and r['trackingValid']=='1' and abs(float(r['rotorSpeedFactor'])-1.033333333333333)<1e-10:slice_[(round(float(r['bladeDensityFactor']),12),round(float(r['bladeStiffnessFactor']),12))]=float(r['frequencyHz'])
    assert len(slice_)==16
    f=result('morris_domain','Group 10+11: fixed speed factor 1.0333333333',[MORRIS/'morris_sweeps.csv'],'Factor mass/inercia [-]','Factor rigidez [-]',bounds=[.865,1.135,.87,1.14],legend=False)
    for (x,y),v in sorted(slice_.items()):f.line([[x,y]],color=0,symbols=True,only=True,filled=True).label(x,y+.012,f'{v:.5f} Hz',9)
    f.notes=['16 evaluated combinations, without interpolation. Group mean frequency, not a mode shape.'];f.document=['studies/README.md'];figs.append(f)
    estim=readcsv(MORRIS/'morris_estimators.csv');f=result('morris_convergence','Stabilization across prefixes of the same design',[MORRIS/'morris_estimators.csv'],'Trajectories','mu* [-]')
    for gi,g in enumerate(['6+7','10+11']):
        for c,p in enumerate(par):
            rr=sorted([r for r in estim if r['group']==g and r['parameter']==p and r['response']=='frequency'],key=lambda r:int(r['trajectories']));f.line([[float(r['trajectories']),float(r['muStar'])] for r in rr],g+' '+pl[c],[0,2,1][c],'SOLID' if gi==0 else 'DASHED',symbols=True,filled=gi==0)
    f.notes=['Prefixes 10/20/40 do not establish asymptotic convergence.'];f.document=['studies/README.md'];figs.append(f)
    f=result('morris_dispersion','Influence and dispersion: group 10+11',[MORRIS/'morris_estimators.csv'],'mu* [-]','1000 sigma [-]',bounds=[.03,.086,1,5.5],legend=False)
    for c,p in enumerate(par):
        r=next(r for r in stats if r['parameter']==p and r['group']=='10+11');v=r['sigma']*1000;f.line([[r['muStar'],v]],color=[0,2,1][c],symbols=True,only=True,filled=r['acceptedDispersion']).label(r['muStar'],v+.25,pl[c],10,[0,2,1][c])
    f.notes=['Filled: accepted dispersion. Open: not accepted. Not probabilistic uncertainty.'];f.document=['studies/README.md'];figs.append(f)
    checks['morris_completed_trajectories']=meta['completedTrajectories'];checks['morris_mean_accepted']=sum(r['acceptedMean'] for r in stats);checks['morris_dispersion_accepted']=sum(r['acceptedDispersion'] for r in stats);checks['morris_domain_slice_evaluated_points']=len(slice_);checks['finite_all_exported']=True
    dump(HERE/'reports/numerical_checks.json',checks)
    return figs,native
