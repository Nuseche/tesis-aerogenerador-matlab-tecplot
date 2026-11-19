function result=run_rotating_damping_sweep(level)
% Resolve the 3P bending reaction under unit axial force on the 266-element mesh.
% Supply one target in percent, or run all four campaigns without an argument.
if nargin==0
    levels=[.5,1,2,5];
    summaries=cell(size(levels));
    for j=1:numel(levels)
        summaries{j}=run_rotating_damping_sweep(levels(j));
    end
    result=vertcat(summaries{:});
    return
end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
out=fullfile(root,'runs','periodic_loads_20261118');
cfgData=load(fullfile(out,'operators64.mat'),'cfg');
base=load(fullfile(out,'correctionOperators266.mat'),'F');
solver=run_periodic_load_campaign("solver_handles");
F=base.F;
% For constant-speed prescribed rotation Rayleigh damping enters D0 and
% the velocity transport stiffness K1. Reaction recovery uses O10 and O01.
ratio=level/.5;
for name=["D0","K1","O10","O01"]
    F.(name)=cellfun(@(x)x*ratio,F.(name),'UniformOutput',false);
end
maxNumCompThreads(1);
cfg=cfgData.cfg;
cfg.damping.alpha=cfg.damping.alpha*ratio;
cfg.damping.beta=cfg.damping.beta*ratio;
mesh=solver.bisect(model.build_model(io.load_model_data(cfg),cfg));
system=aero.prepare_structure(mesh,cfg);
psi=.1234567;
w=3.41*pi/30;
direct=aero.turbine_mbc_operators(system,psi,w);
mass=0;damping=0;stiffness=0;
for ell=-F.L:F.L
    j=ell+F.L+1;
    phase=exp(1i*ell*psi);
    mass=mass+phase*F.M{j};
    damping=damping+phase*(F.D0{j}+w*F.D1{j});
    stiffness=stiffness+phase*(F.K0{j}+w*F.K1{j}+w*w*F.K2{j});
end
operatorError=max([norm(mass-direct.M,'fro')/norm(direct.M,'fro'), ...
    norm(damping-direct.D,'fro')/norm(direct.D,'fro'), ...
    norm(stiffness-direct.K,'fro')/norm(direct.K,'fro')]);
assert(operatorError<1e-10);
% Fine near both peaks, with extended flanks to enclose the 5% widths.
rpms=unique(round([2.95:.01:3.90,3.32:.002:3.56,3.4445],6))';
rows=zeros(numel(rpms),10);
for i=1:numel(rpms)
    w=rpms(i)*pi/30;
    [p,m]=solver.solve(F,[],w,6,false);
    a=solver.solve(F,[],w,0,true);
    p=p(4,:,1);a=a(4,:,1);
    yp=2*p(F.outputH+4);ya=2*a(F.outputH+4);
    rows(i,:)=[level,rpms(i),real(yp),imag(yp),real(ya),imag(ya), ...
        abs(yp),abs(ya),100*norm(a-p)/norm(p),m.residual];
    if mod(i,50)==0,fprintf('%g percent, %d/%d\n',level,i,numel(rpms));end
end
data=array2table(rows,'VariableNames',{'dampingPct','rpm','periodicReal','periodicImag', ...
    'averageReal','averageImag','periodicAmplitude','averageAmplitude','historyErrorPct','relativeResidual'});
P=complex(data.periodicReal,data.periodicImag); A=complex(data.averageReal,data.averageImag);
[pp,ip]=max(abs(P));[ap,ia]=max(abs(A));
data.peakNormalizedComplexErrorPct=100*abs(A-P)/pp;
[emax,im]=max(data.peakNormalizedComplexErrorPct);
[lp,up]=boundaries(rpms,abs(P),ip);[la,ua]=boundaries(rpms,abs(A),ia);
tag=string(round(level*10));
writetable(data,fullfile(out,'damping_sweep_'+tag+'.csv'));
ic=find(rpms==3.4445);
checkRows=[];
for idx=unique([ip,ia,im,ic])
    w=rpms(idx)*pi/30;
    y12=solver.solve(F,[],w,12,false); y6=solver.solve(F,[],w,6,false);
    checkRows(end+1,:)=[level,rpms(idx),100*norm(y12(4,:,1)-y6(4,:,1))/norm(y12(4,:,1))];
end
writetable(array2table(checkRows,'VariableNames',{'dampingPct','rpm','H6toH12HistoryErrorPct'}), ...
    fullfile(out,'damping_convergence_'+tag+'.csv'));
result=table(level,cfg.damping.alpha,cfg.damping.beta,rpms(ip),rpms(ia),pp,ap,lp,up,la,ua, ...
    (rpms(ia)-rpms(ip))/(up-lp),emax,rpms(im),data.peakNormalizedComplexErrorPct(ip), ...
    data.peakNormalizedComplexErrorPct(ia),data.historyErrorPct(ic),operatorError,max(checkRows(:,3)), ...
    'VariableNames',{'dampingPct','alpha','beta','periodicPeakRpm','averagePeakRpm','periodicPeakNmPerN', ...
    'averagePeakNmPerN','periodicLowerRpm','periodicUpperRpm','averageLowerRpm','averageUpperRpm', ...
    'separationOverPeriodicWidth','maxNormalizedErrorPct','maxErrorRpm','errorAtPeriodicPeakPct', ...
    'errorAtAveragePeakPct','historyErrorAt34445Pct','offgridOperatorMismatch','H6to12MaxPct'});
writetable(result,fullfile(out,'damping_summary_'+tag+'.csv'));
disp(result);
end

function [lo,hi]=boundaries(x,y,i)
threshold=y(i)/sqrt(2);
left=find(y(1:i)<threshold,1,'last');
right=i-1+find(y(i:end)<threshold,1,'first');
assert(~isempty(left)&&~isempty(right),'Half-power crossing lies outside the scan.');
lo=interp1(y(left:left+1),x(left:left+1),threshold);
hi=interp1(y(right-1:right),x(right-1:right),threshold);
end
