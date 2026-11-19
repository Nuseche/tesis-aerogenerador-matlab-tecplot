function check_rotating_refinement(framesOnly)
% Resolve the local 3P reaction peak and compare physical multiblade maps through refinement.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
out=fullfile(root,'runs','periodic_loads_20261118');
if ~isfolder(out), mkdir(out); end
if nargin==0, framesOnly=false; end
maxNumCompThreads(1);
f=run_periodic_load_campaign("solver_handles");
cfg=config_aeroelastic_snl100(); cfg.gravity.enabled=false;
wa=2*pi*.17; wb=2*pi; z=.005;
cfg.damping.alpha=2*z*wa*wb/(wa+wb); cfg.damping.beta=2*z/(wa+wb);
model0=model.build_model(io.load_model_data(cfg),cfg);
angles=frameDeviations(model0);
writetable(angles,fullfile(out,'review_refinement_triad_angles.csv'));
if framesOnly, return; end
maps={}; parent=[];
for level=0:3
    system=aero.prepare_structure(model0,cfg);
    op=aero.turbine_mbc_operators(system,.371,.359);
    ne=numel(model0.mesh.elements.id);
    x=zeros(system.ndof,1);x(model0.dofs.node(:,1))=1;
    mass=x'*system.M*x;
    if level>0
        [geometry,frames,blocks]=compareStations(parent,previous,model0,op);
        maps(end+1,:)={ne/2,ne,system.n,mass,geometry,frames,blocks(1),blocks(2),blocks(3)};
        assert(max([geometry,frames,blocks])<1e-11 && abs(mass/mass0-1)<1e-11)
    else
        mass0=mass;
    end
    if level<3
        parent=model0; previous=op;
        model0=f.bisect(model0);
    end
end
audit=cell2table(maps,'VariableNames',{'parentElements','elements','freeCoordinates','rigidTranslationMassKg','maxCoordinateDifferenceM','maxFrameDifference','maxMapDifference','maxFirstDerivativeDifference','maxSecondDerivativeDifference'});
writetable(audit,fullfile(out,'review_refinement_maps.csv')); disp(audit);
% Fourier matrices reconstructed at an independent angle and angular speed.
[~,~,ec]=assembly.assemble_structural_matrices(model0,cfg);
[F1064,checks]=f.sample(system,ec,64,12);
assert(checks.reconstruction<1e-10)
fprintf('1064 Fourier reconstruction relative residual %.7g\n',checks.reconstruction);
% Coarse scan brackets the maximum, then a separate uniform grid resolves both half-power points.
coarse=3.3:.01:4.4;
survey=transfer(f,F1064,1064,coarse,0,true);
[~,i]=max(survey.amplitudeNmPerN);
assert(i>1 && i<numel(coarse));
near=round((coarse(i)-.06):.001:(coarse(i)+.06),5);
a=transfer(f,F1064,1064,unique([near 3.4445]),0,true);
writetable(survey,fullfile(out,'review_1064_average_survey.csv'));
writetable(a,fullfile(out,'review_1064_average_peak.csv'));
pFine=transfer(f,F1064,1064,[3.394 3.4445],6,false);
writetable(pFine,fullfile(out,'review_1064_periodic_spots.csv'));
comparisons=zeros(2,8);
for j=1:height(pFine)
    rpm=pFine.rpm(j); omega=rpm*pi/30;
    [u,meta]=f.solve(F1064,[],omega,12,false);
    y=f.solve(F1064,[],omega,6,false);
    a0=f.solve(F1064,[],omega,0,true);
    u=u(4,:,1); y=y(4,:,1); a0=a0(4,:,1);
    value=2*u(F1064.outputH+4);
    comparisons(j,:)=[1064,rpm,12,abs(value),angle(value)*180/pi,100*norm(a0-u)/norm(u), ...
        100*norm(y-u)/norm(u),meta.residual];
end
spotCheck=array2table(comparisons,'VariableNames',{'elements','rpm','H','periodicAmpNmPerN', ...
    'periodicPhaseDeg','averageHistoryErrorPercent','H6to12HistoryPercent','residual'});
writetable(spotCheck,fullfile(out,'review_1064_periodic_resolution.csv'));
clear F1064 system ec op parent previous
cache=fullfile(out,'correctionOperators532.mat');
if isfile(cache)
    data=load(cache,'F'); F532=data.F;
else
    mesh=model.build_model(io.load_model_data(cfg),cfg); mesh=f.bisect(f.bisect(mesh));
    system=aero.prepare_structure(mesh,cfg); [~,~,ec]=assembly.assemble_structural_matrices(mesh,cfg);
    [F532,checks532]=f.sample(system,ec,64,12); assert(checks532.reconstruction<1e-10);
end
local=unique(round([3.36:.002:3.43,3.4445],5));
p=transfer(f,F532,532,local,6,false);
spot=transfer(f,F532,532,[3.376 3.392 3.394 3.396 3.412 3.4445],12,false);
writetable(p,fullfile(out,'review_532_periodic_peak.csv'));
writetable(spot,fullfile(out,'review_532_periodic_resolution.csv'));
summary=[band(p);band(a)];
writetable(summary,fullfile(out,'review_refinement_peaks.csv'));disp(summary)
end

function result=transfer(f,F,ne,speeds,H,average)
rows=zeros(numel(speeds),6);
for j=1:numel(speeds)
    [y,meta]=f.solve(F,[],speeds(j)*pi/30,H,average);
    moment=2*y(4,F.outputH+4,1);
    rows(j,:)=[ne,speeds(j),H,abs(moment),angle(moment)*180/pi,meta.residual];
end
result=array2table(rows,'VariableNames',{'elements','rpm','H','amplitudeNmPerN','phaseDeg','residual'});
end

function result=band(t)
rpm=t.rpm; amp=t.amplitudeNmPerN;
[peak,i]=max(amp); target=peak/sqrt(2);
lo=find(amp(1:i)<target,1,'last'); hi=i-1+find(amp(i:end)<target,1,'first');
assert(~isempty(lo)&&~isempty(hi));
left=interp1(amp(lo:lo+1),rpm(lo:lo+1),target);
right=interp1(amp(hi-1:hi),rpm(hi-1:hi),target);
result=table(t.elements(i),t.H(i),rpm(i),peak,left,right,right-left, ...
    'VariableNames',{'elements','H','peakRpm','peakNmPerN','leftRpm','rightRpm','widthRpm'});
end

function [geometry,frames,blocks]=compareStations(parent,op,fine,opFine)
% Each retained blade node and each new midspan station uses its parent section axes.
bm=parent.bladeDofMap; bf=fine.bladeDofMap;
geometry=0; blocks=zeros(1,3);
frames=max(abs(bf.frameR-repelem(bm.frameR,1,1,2,1)),[],'all');
assert(isequal(bm.nodeIds,bf.nodeIds(2:2:end,:)));
for blade=1:3
    e=bm.frameElementIds(:,blade);
    a=parent.mesh.nodes.xyz(parent.mesh.elements.nodeI(e),:);
    b=parent.mesh.nodes.xyz(parent.mesh.elements.nodeJ(e),:);
    geometry=max([geometry,max(abs(fine.mesh.nodes.xyz(bf.nodeIds(1:2:end,blade),:)-(a+b)/2),[],'all'), ...
        max(abs(fine.mesh.nodes.xyz(bf.nodeIds(2:2:end,blade),:)-b),[],'all')]);
end
fields={'T','Tdot','Tddot'};
for station=1:size(bm.nodeIds,1)
    ids=reshape(op.map(6*(station-1)+(1:6),:),[],1);
    for child=2*station-1:2*station
        fineIds=reshape(opFine.map(6*(child-1)+(1:6),:),[],1);
        for k=1:3
            A=op.transformation.(fields{k}); B=opFine.transformation.(fields{k});
            blocks(k)=max(blocks(k),norm(A(ids,ids)-B(fineIds,fineIds),'fro'));
        end
    end
end
end


function angles=frameDeviations(md)
% Compare the native blade triad to a cyclic copy of blade 1 before rotor motion.
frame=md.bladeDofMap.frameR; axis=md.rotorAxis.direction(:);
roots=md.mesh.nodes.xyz(md.bladeDofMap.rootNodeIds,:)-md.rotorAxis.point.';
direction=sign(dot(axis,cross(roots(1,:),roots(2,:))));
W=[0,-axis(3),axis(2);axis(3),0,-axis(1);-axis(2),axis(1),0];
rows=zeros(2*size(frame,3),4); i=0;
for b=2:3
    theta=direction*(b-1)*2*pi/3;
    rotation=eye(3)+sin(theta)*W+(1-cos(theta))*W^2;
    for station=1:size(frame,3)
        delta=frame(:,:,station,b).'*(rotation*frame(:,:,station,1));
        triad=acosd(max(-1,min(1,(trace(delta)-1)/2)));
        tangent=acosd(max(-1,min(1,delta(1,1))));
        i=i+1; rows(i,:)=[b,station,triad,tangent];
    end
end
angles=array2table(rows,'VariableNames',{'blade','station','triadRotationDeg','tangentAngleDeg'});
end
