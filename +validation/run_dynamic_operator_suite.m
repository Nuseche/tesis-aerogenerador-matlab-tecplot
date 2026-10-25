function suite=run_dynamic_operator_suite(modelData,reduced,sweep,cfg)
%RUN_DYNAMIC_OPERATOR_SUITE Specialized Action-07 acceptance verification.

skewTol=value(cfg,{'action07','skewTolerance'},1e-12);
scaleTol=value(cfg,{'action07','scalingTolerance'},1e-12);
energyTol=value(cfg,{'action07','energyTolerance'},1e-12);
rigidTol=value(cfg,{'action07','rigidBenchmarkTolerance'},1e-10);
distributedTol=value(cfg,{'action07','distributedBenchmarkTolerance'},1e-10);
bladeTol=value(cfg,{'action07','bladeDispersionTolerance'},1e-3);
rayleighTol=value(cfg,{'action07','rayleighTolerance'},1e-12);
aeroTol=value(cfg,{'action07','aerodynamicTangentTolerance'},1e-6);
ratioMinimum=value(cfg,{'action07','aerodynamicConvergenceRatioMinimum'},3.5);
identityTol=value(cfg,{'action07','matrixIdentityTolerance'},1e-12);
checks=repmat(check("",true,0,0,"",false),0,1);

speeds=sweep.speedRPM(:);opsList=sweep.ops;n=numel(speeds);
operatorTable=table('Size',[n 13],'VariableTypes',repmat("double",1,13), ...
    'VariableNames',{'speedRPM','normC','normG','normD','normK','normKaero', ...
    'normCaero','skewErrorG','identityD','identityC','identityK', ...
    'distributedGyroNorm','rigidGyroNorm'});
allSparse=true;allFinite=true;maximumSkew=0;maximumDIdentity=0;
maximumCIdentity=0;maximumKIdentity=0;maximumPassiveSymmetry=0;
passivePositive=true;
for index=1:n
    ops=opsList{index};f=ops.full;r=ops.reduced;
    matrices={f.C,f.G,f.D,f.K,f.Kaero,f.Caero,r.C,r.G,r.D,r.K, ...
        r.Kaero,r.Caero,r.Cstruct,r.Cfoundation,r.Cdrivetrain};
    allSparse=allSparse&&all(cellfun(@issparse,matrices));
    allFinite=allFinite&&all(cellfun(@(A)all(isfinite(nonzeros(A))),matrices));
    gSkew=relative(f.G+f.G.',f.G);
    dIdentity=relative(f.D-f.C-f.G-f.massRate,f.D);
    cIdentity=relative(f.C-f.Cstruct-f.Cfoundation-f.Caero-f.Cdrivetrain,f.C);
    kIdentity=relative(f.K-f.Ke-f.Kg-f.KOmega-f.Kaero-f.Ktransport,f.K);
    maximumSkew=max(maximumSkew,gSkew);maximumDIdentity=max(maximumDIdentity,dIdentity);
    maximumCIdentity=max(maximumCIdentity,cIdentity);maximumKIdentity=max(maximumKIdentity,kIdentity);
    passive={r.Cstruct,r.Cfoundation,r.Cdrivetrain};
    for component=1:numel(passive)
        A=passive{component};sym=relative(A-A.',A);
        maximumPassiveSymmetry=max(maximumPassiveSymmetry,sym);
        passivePositive=passivePositive&&passiveQuadraticCheck(A);
    end
    report=ops.diagnostics.gyroscopic;
    operatorTable{index,:}=[speeds(index),norm(f.C,'fro'),norm(f.G,'fro'), ...
        norm(f.D,'fro'),norm(f.K,'fro'),norm(f.Kaero,'fro'), ...
        norm(f.Caero,'fro'),gSkew,dIdentity,cIdentity,kIdentity, ...
        report.distributedNorm,report.rigidNorm];
end
checks(end+1,1)=check("matrices.allSparse",allSparse,double(~allSparse),0, ...
    "Full and reduced first-order operators remain sparse.",true);
checks(end+1,1)=check("matrices.allFinite",allFinite,double(~allFinite),0, ...
    "Every stored first-order coefficient is finite.",true);
checks(end+1,1)=check("gyroscopic.skewSymmetry",maximumSkew<=skewTol, ...
    maximumSkew,skewTol,"Maximum full-system skew residual.",true);
checks(end+1,1)=check("identity.DequalsCplusGplusMassRate",maximumDIdentity<=identityTol, ...
    maximumDIdentity,identityTol,"Inertial D equals C+G+dM/dt at every speed.",true);
checks(end+1,1)=check("identity.dampingComponents",maximumCIdentity<=identityTol, ...
    maximumCIdentity,identityTol,"C equals its four named components.",true);
checks(end+1,1)=check("identity.stiffnessComponents",maximumKIdentity<=identityTol, ...
    maximumKIdentity,identityTol,"K equals its named components.",true);
checks(end+1,1)=check("damping.passiveSymmetry", ...
    maximumPassiveSymmetry<=skewTol,maximumPassiveSymmetry,skewTol, ...
    "Mechanical passive damping components are symmetric.",true);
checks(end+1,1)=check("damping.passiveQuadraticForms",passivePositive, ...
    double(~passivePositive),0,"Deterministic quadratic forms are nonnegative.",true);

[G0,G6,G12,Gminus,reports]=speedGyros(modelData,sweep,cfg);
zeroNorm=norm(G0,'fro');oddError=relative(Gminus+G6,G6);
linearError=relative(G12-2*G6,G12);
checks(end+1,1)=check("gyroscopic.zeroAtZeroRPM",zeroNorm==0,zeroNorm,0, ...
    "Every automatic gyro source vanishes at zero speed.",true);
checks(end+1,1)=check("gyroscopic.oddInSpeed",oddError<=scaleTol, ...
    oddError,scaleTol,"G(-Omega)=-G(Omega).",true);
checks(end+1,1)=check("gyroscopic.linearInSpeed",linearError<=scaleTol, ...
    linearError,scaleTol,"G(2*Omega)=2*G(Omega).",true);
componentError=relative(G12-reports.plus12.components.distributed- ...
    reports.plus12.components.rigid-reports.plus12.components.external,G12);
checks(end+1,1)=check("gyroscopic.componentSum",componentError<=identityTol, ...
    componentError,identityTol,"Distributed, rigid and external gyro sum exactly.",true);
checks(end+1,1)=check("gyroscopic.distributedBladesNonzero", ...
    reports.plus12.distributedNorm>0,reports.plus12.distributedNorm,0, ...
    "The three blades contribute automatic distributed gyroscopy.",true);
checks(end+1,1)=check("gyroscopic.rigidHubNonzero",reports.plus12.rigidNorm>0, ...
    reports.plus12.rigidNorm,0,"The rotating hub contributes rigid gyroscopy.",true);
bladeNorms=reports.plus12.bladeNorms;
bladeDispersion=(max(bladeNorms)-min(bladeNorms))/mean(bladeNorms);
checks(end+1,1)=check("gyroscopic.bladeInvariance",bladeDispersion<=bladeTol, ...
    bladeDispersion,bladeTol,"Norm dispersion among homologous blades.",true);
v=sin((1:size(G12,1)).'/13);power=abs(v.'*G12*v)/ ...
    max(norm(G12,'fro')*norm(v)^2,eps);
checks(end+1,1)=check("gyroscopic.zeroInstantaneousPower",power<=energyTol, ...
    power,energyTol,"A skew gyro operator performs no instantaneous work.",true);

[rigidMatrixError,whirlError]=rigidDiskBenchmark();
checks(end+1,1)=check("benchmark.rigidDiskMatrix",rigidMatrixError<=rigidTol, ...
    rigidMatrixError,rigidTol,"Assembled point-mass and disk angular momentum blocks.",true);
checks(end+1,1)=check("benchmark.rigidDiskWhirl",whirlError<=rigidTol, ...
    whirlError,rigidTol,"Forward/backward whirl frequencies versus closed form.",true);
distributedError=distributedElementBenchmark();
checks(end+1,1)=check("benchmark.distributedElement", ...
    distributedError<=distributedTol,distributedError,distributedTol, ...
    "Selective Timoshenko element versus analytic distributed Coriolis block.",true);

[rayleighError,rayleighTable]=rayleighChecks(opsList);
checks(end+1,1)=check("damping.rayleighTargetsRecovered", ...
    rayleighError<=rayleighTol,rayleighError,rayleighTol, ...
    "Both target damping ratios are recovered from alpha and beta.",true);
[connectorResidual,connectorPower]=connectorBenchmark();
checks(end+1,1)=check("damping.connectorObjectivity", ...
    connectorResidual<=1e-14,connectorResidual,1e-14, ...
    "The offset-aware connector sees no compatible rigid velocity.",true);
checks(end+1,1)=check("damping.connectorZeroRigidPower", ...
    connectorPower<=1e-12,connectorPower,1e-12, ...
    "The connector dissipates no energy under rigid motion.",true);

[aeroMetrics,aeroTable]=aerodynamicBenchmark();
checks(end+1,1)=check("aerodynamics.forceAndTangentSameFunction", ...
    aeroMetrics.forceError<=1e-14,aeroMetrics.forceError,1e-14, ...
    "The evaluated force is the source differentiated by the tangent routine.",true);
checks(end+1,1)=check("aerodynamics.positionTangent", ...
    aeroMetrics.positionError<=aeroTol,aeroMetrics.positionError,aeroTol, ...
    "Unsymmetric Kaero matches the analytic polynomial derivative.",true);
checks(end+1,1)=check("aerodynamics.velocityTangent", ...
    aeroMetrics.velocityError<=aeroTol,aeroMetrics.velocityError,aeroTol, ...
    "Caero matches the analytic polynomial derivative.",true);
checks(end+1,1)=check("aerodynamics.nonsymmetryPreserved", ...
    aeroMetrics.nonsymmetry>0,aeroMetrics.nonsymmetry,0, ...
    "Follower-load tangent is not silently symmetrized.",true);
checks(end+1,1)=check("aerodynamics.secondOrderConvergence", ...
    aeroMetrics.convergenceRatio>=ratioMinimum,aeroMetrics.convergenceRatio, ...
    ratioMinimum,"Central-difference refinement exhibits second-order convergence.",true);
checks(end+1,1)=check("aerodynamics.explicitZerosRecognized", ...
    aeroMetrics.explicitZeroRecognized,double(~aeroMetrics.explicitZeroRecognized),0, ...
    "Explicit zero matrices remain an intentional provided source.",true);
[equilibriumResidual,equilibriumIdentity]=aeroEquilibriumBenchmark();
checks(end+1,1)=check("aerodynamics.equilibriumResidual", ...
    equilibriumResidual<=1e-9,equilibriumResidual,1e-9, ...
    "Synthetic aerodynamic force participates in Newton equilibrium.",true);
checks(end+1,1)=check("aerodynamics.noStiffnessDoubleCount", ...
    equilibriumIdentity<=identityTol,equilibriumIdentity,identityTol, ...
    "Kaero embedded during Newton is separated from Kg and added once.",true);

gyroTable=gyroComponentTable(speeds,opsList);
suite=struct('schemaVersion',"1.0.0", ...
    'scope',"damping_distributed_and_rigid_gyroscopy_aerodynamic_linearization", ...
    'checks',checks,'checkTable',struct2table(checks), ...
    'operatorTable',operatorTable,'gyroTable',gyroTable, ...
    'dampingTable',rayleighTable,'aerodynamicTable',aeroTable, ...
    'metrics',struct('maximumGyroSkewError',maximumSkew, ...
    'oddSpeedError',oddError,'linearSpeedError',linearError, ...
    'bladeNormDispersion',bladeDispersion,'gyroPower',power, ...
    'rigidMatrixError',rigidMatrixError,'whirlFrequencyError',whirlError, ...
    'distributedElementError',distributedError,'rayleighTargetError',rayleighError, ...
    'aerodynamicPositionError',aeroMetrics.positionError, ...
    'aerodynamicVelocityError',aeroMetrics.velocityError, ...
    'aerodynamicConvergenceRatio',aeroMetrics.convergenceRatio, ...
    'aerodynamicEquilibriumResidual',equilibriumResidual));
suite.passed=all([checks.pass]|~[checks.critical]);
suite.criticalFailures=checks(~[checks.pass]&[checks.critical]);
if logical(value(cfg,{'validation','failOnCritical'},1))&&~suite.passed
    names=strjoin(string({suite.criticalFailures.name}),', ');
    error('validation:run_dynamic_operator_suite:CriticalFailure', ...
        'Action 07 critical checks failed: %s',names);
end
end

function [G0,G6,G12,Gminus,reports]=speedGyros(modelData,sweep,cfg)
state=sweep.states{find(sweep.speedRPM==0,1)};
cfg0=cfg;cfg0.rotor.speedRPM=0;state.angularVelocity=zeros(3,1);
[G0,reports.zero]=assembly.assemble_gyroscopic_matrix(modelData,state,cfg0);
axis=modelData.rotorAxis.direction(:);
state.angularVelocity=6*2*pi/60*axis;cfg6=cfg;cfg6.rotor.speedRPM=6;
[G6,reports.plus6]=assembly.assemble_gyroscopic_matrix(modelData,state,cfg6);
state.angularVelocity=12*2*pi/60*axis;cfg12=cfg;cfg12.rotor.speedRPM=12;
[G12,reports.plus12]=assembly.assemble_gyroscopic_matrix(modelData,state,cfg12);
state.angularVelocity=-6*2*pi/60*axis;cfgMinus=cfg;cfgMinus.rotor.speedRPM=-6;
[Gminus,reports.minus6]=assembly.assemble_gyroscopic_matrix(modelData,state,cfgMinus);
end

function [matrixError,whirlError]=rigidDiskBenchmark()
model.mesh.nodes=struct('id',130,'xyz',[0 0 0]);
model.mesh.elements=struct('id',zeros(0,1),'nodeI',zeros(0,1), ...
    'nodeJ',zeros(0,1),'section',zeros(0,1),'blade',zeros(0,1));
model.sections=struct([]);model.dofs.node=1:6;model.dofs.number=6;
model.rotorAxis=struct('point',[0;0;0],'direction',[1;0;0]);
m=10;Jp=4;Jd=3;omega=7;
model.rigidBodies.bodies=struct('name',"analytic_disk",'masterNode',130, ...
    'mass',m,'cgOffsetBody',zeros(3,1),'inertiaBody',diag([Jp Jd Jd]), ...
    'orientationBodyToGlobal',eye(3),'rotating',true);
[G,~]=assembly.assemble_gyroscopic_matrix( ...
    model,struct('angularVelocity',[omega;0;0]),struct());
S=[0 0 0;0 0 -omega;0 omega 0];expected=zeros(6);
% Inertial translations have no Coriolis block. Positive spin gives -S(h)
% on infinitesimal inertial tilt coordinates; the axisymmetric Mdot is zero.
expected(4:6,4:6)=-Jp*S;
matrixError=relative(full(G)-expected,expected);
k=120;solution=modal.solve_quadratic_modes( ...
    Jd*eye(2),full(G(5:6,5:6)),k*eye(2),struct('number',2));
root1=(sqrt((Jp*omega)^2+4*Jd*k)-Jp*omega)/(2*Jd);
root2=(sqrt((Jp*omega)^2+4*Jd*k)+Jp*omega)/(2*Jd);
whirlError=norm(sort(solution.dampedFrequencyHz)- ...
    sort([root1;root2]/(2*pi)))/norm([root1;root2]/(2*pi));
end

function errorValue=distributedElementBenchmark()
L=5;m=12;omega=3;
section=localSection();section.m=m;section.Jx=2;section.Jy=1;section.Jz=1;
cfg.elements.formulation="selective_integration";
G=elements.timoshenko_gyroscopic_matrix( ...
    [0 0 0],[L 0 0],[0 0 1],section,[omega;0;0],cfg);
mass2=m*L/6*[2 1;1 2];S2=[0 -1;1 0];
expected=2*omega*kron(mass2,S2);indices=[2 3 8 9];
errorValue=relative(full(G(indices,indices))-expected,expected);
end

function [errorValue,tableValue]=rayleighChecks(opsList)
n=numel(opsList);speedRPM=zeros(n,1);alpha=speedRPM;beta=speedRPM;
targetError=speedRPM;frequency1=speedRPM;frequency2=speedRPM;
zeta1=speedRPM;zeta2=speedRPM;
for index=1:n
    info=opsList{index}.diagnostics.damping.rayleigh;
    speedRPM(index)=opsList{index}.speedRPM;alpha(index)=info.alpha;beta(index)=info.beta;
    frequency1(index)=info.targetFrequenciesHz(1);frequency2(index)=info.targetFrequenciesHz(2);
    zeta1(index)=info.recoveredDampingRatios(1);zeta2(index)=info.recoveredDampingRatios(2);
    targetError(index)=max(abs(info.recoveredDampingRatios-info.targetDampingRatios));
end
errorValue=max(targetError);
tableValue=table(speedRPM,alpha,beta,frequency1,frequency2,zeta1,zeta2,targetError);
end

function [residual,power]=connectorBenchmark()
model.mesh.nodes=struct('id',[129;130],'xyz',[1 2 3;3 2.5 2.7]);
model.mesh.elements=struct('id',zeros(0,1));model.dofs.node=reshape(1:12,6,2).';
cfg.damping=struct('alpha',0,'beta',0);cfg.drivetrain.damping=1:6;
[C,parts]=assembly.assemble_damping_matrix(model,speye(12),speye(12),struct(),cfg);
theta=[.2;-.1;.3];translation=[1;-2;.5];q=zeros(12,1);
for node=1:2
    x=model.mesh.nodes.xyz(node,:).';
    q(model.dofs.node(node,1:3))=translation+cross(theta,x);
    q(model.dofs.node(node,4:6))=theta;
end
residual=norm(parts.drivetrainKinematics.relativeKinematicMatrix*q);
power=abs(q.'*C*q);
end

function [metrics,tableValue]=aerodynamicBenchmark()
q=[.2;-.1;.3];qd=[.4;-.2;.1];state=struct('qFull',q,'qdFull',qd);
cfg.aerodynamics=struct('loadFcn',@polynomialLoad,'dofIndices',(1:3).', ...
    'finiteDifferenceStep',1e-3,'status',"synthetic_benchmark");
[force,~]=assembly.evaluate_aerodynamic_load(struct(),state,cfg,3);
[K,C,report]=assembly.linearize_aerodynamic_loads(struct(),state,cfg,3);
[Kexact,Cexact,fexact]=polynomialTangent(q,qd);
cfgCoarse=cfg;cfgCoarse.aerodynamics.finiteDifferenceStep=2e-3;
[~,~,coarse]=assembly.linearize_aerodynamic_loads(struct(),state,cfgCoarse,3);
convergenceRatio=coarse.coarseFineRelativeK/max(report.coarseFineRelativeK,eps);
cfgZero.aerodynamics=struct('Kaero',sparse(3,3),'Caero',sparse(3,3));
[~,~,zeroReport]=assembly.linearize_aerodynamic_loads(struct(),state,cfgZero,3);
metrics=struct('forceError',norm(force-fexact)/max(norm(fexact),1), ...
    'positionError',relative(full(K)-Kexact,Kexact), ...
    'velocityError',relative(full(C)-Cexact,Cexact), ...
    'nonsymmetry',norm(K-K.','fro'), ...
    'convergenceRatio',convergenceRatio, ...
    'explicitZeroRecognized',zeroReport.method=="provided_matrices");
tableValue=struct2table(metrics,'AsArray',true);
end

function f=polynomialLoad(q,qd,~,~,~)
[~,~,f]=polynomialTangent(q,qd);
end

function [K,C,f]=polynomialTangent(q,v)
A=[2 3 -.4;-1 4 .2;.6 -.7 1.5];
B=[.5 -.2 .1;.7 .9 -.3;-.2 .4 .8];
f=A*q+B*v+[.7*q(1)^3+.2*v(1)^3;-.4*q(2)^3-.1*v(2)^3; ...
    .3*q(1)*q(2)+.2*q(3)^3+.15*v(1)*v(3)];
Jq=A;Jq(1,1)=Jq(1,1)+2.1*q(1)^2;
Jq(2,2)=Jq(2,2)-1.2*q(2)^2;
Jq(3,1)=Jq(3,1)+.3*q(2);Jq(3,2)=Jq(3,2)+.3*q(1);
Jq(3,3)=Jq(3,3)+.6*q(3)^2;
Jv=B;Jv(1,1)=Jv(1,1)+.6*v(1)^2;Jv(2,2)=Jv(2,2)-.3*v(2)^2;
Jv(3,1)=Jv(3,1)+.15*v(3);Jv(3,3)=Jv(3,3)+.15*v(1);
K=-Jq;C=-Jv;
end

function [residual,identity]=aeroEquilibriumBenchmark()
model.mesh.nodes=struct('id',[1;2],'xyz',[0 0 0;4 0 0]);
model.mesh.elements=struct('id',1,'nodeI',1,'nodeJ',2,'section',1, ...
    'blade',0,'type',"beam",'auxPoint',[0 1 0]);
model.sections=localSection();model.dofs.node=reshape(1:12,6,2).';
model.dofs.element=1:12;model.dofs.number=12;model.dofs.fixed=(1:6).';
model.boundaryConditions.fixedNodeIds=1;model.boundaryConditions.fixedDofs=(1:6).';
model.rotorAxis=struct('point',[0;0;0],'direction',[1;0;0]);
cfg.gravity=struct('enabled',false,'vector',[0;0;0]);cfg.rotor.speedRPM=0;
cfg.base.type="fixed";cfg.drivetrain.stiffness=[];cfg.drivetrain.damping=[];
    cfg.damping=struct('alpha',0,'beta',0);cfg.equilibrium.tolerance=1e-9;
cfg.equilibrium.maximumIterations=20;
cfg.aerodynamics=struct('loadFcn',@equilibriumAeroLoad, ...
    'tangentFcn',@equilibriumAeroTangent,'status',"synthetic_benchmark");
[M,Ke]=assembly.assemble_structural_matrices(model,cfg);
reduced=struct('Tc',speye(12),'free',(7:12).','full',struct('M',M,'Ke',Ke));
state=equilibrium.solve_static_equilibrium(model,reduced,cfg);
ops=assembly.build_operating_matrices(model,reduced,state,cfg);
residual=state.residualRelative;
identity=relative(ops.full.K-state.tangentFull,state.tangentFull);
end

function f=equilibriumAeroLoad(q,~,~,model,~)
f=zeros(model.dofs.number,1);f(8)=100-20*q(8);
end

function [K,C]=equilibriumAeroTangent(~,model,~)
n=model.dofs.number;K=sparse(n,n);K(8,8)=20;C=sparse(n,n);
end

function tableValue=gyroComponentTable(speeds,opsList)
n=numel(speeds);speedRPM=zeros(n*3,1);blade=zeros(n*3,1);normValue=zeros(n*3,1);
cursor=0;
for index=1:n
    report=opsList{index}.diagnostics.gyroscopic;
    for bladeIndex=1:numel(report.bladeIds)
        cursor=cursor+1;speedRPM(cursor)=speeds(index);
        blade(cursor)=report.bladeIds(bladeIndex);normValue(cursor)=report.bladeNorms(bladeIndex);
    end
end
speedRPM=speedRPM(1:cursor);blade=blade(1:cursor);normValue=normValue(1:cursor);
tableValue=table(speedRPM,blade,normValue);
end

function tf=passiveQuadraticCheck(A)
if nnz(A)==0,tf=true;return,end
scale=max(norm(A,'fro'),1);tf=true;
for index=1:12
    v=sin((1:size(A,1)).'*(index+1)/17);
    tf=tf&&real(v.'*A*v)>=-1e-12*scale*norm(v)^2;
end
end

function section=localSection()
section=struct('id',1,'EA',2.1e9,'GAy',4e8,'GAz',3e8,'GJ',1.5e8, ...
    'EIy',8e7,'EIz',6e7,'m',25,'Jx',2,'Jy',1.2,'Jz',1.4, ...
    'xcg',0,'ycg',0,'zcg',0);
end

function result=relative(numerator,reference)
result=norm(numerator,'fro')/max(norm(reference,'fro'),1);
end

function item=check(name,passValue,numericValue,tolerance,message,critical)
item=struct('name',string(name),'pass',logical(passValue), ...
    'value',double(numericValue),'tolerance',double(tolerance), ...
    'message',string(message),'critical',logical(critical));
end

function result=value(cfg,path,fallback)
result=fallback;cursor=cfg;
for index=1:numel(path)
    if ~isstruct(cursor)||~isfield(cursor,path{index}),return,end
    cursor=cursor.(path{index});
end
if isnumeric(cursor)&&isscalar(cursor)&&isfinite(cursor),result=double(cursor);end
end
