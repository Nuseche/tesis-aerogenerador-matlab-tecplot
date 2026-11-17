function report=run_rotor_orders(folder)
%RUN_ROTOR_ORDERS Campbell, load orders and hub/support harmonic receptances.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin<1,folder=fullfile(root,'runs','rotor_orders_20261117');end
if ~isfolder(folder),mkdir(folder);end
cfg=config_aeroelastic_snl100();cfg.gravity.enabled=false;
zeta=.005;wa=2*pi*.17;wb=2*pi;cfg.damping.alpha=2*zeta*wa*wb/(wa+wb);cfg.damping.beta=2*zeta/(wa+wb);
md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);N=48;
names={'M','D0','D1','K0','K1','K2'};samples=cell(N,1);average=struct();
for j=1:numel(names),average.(names{j})=sparse(s.n,s.n);end
for j=1:N
    psi=(j-1)*2*pi/N;a=aero.turbine_mbc_operators(s,psi,0);p=aero.turbine_mbc_operators(s,psi,1);m=aero.turbine_mbc_operators(s,psi,-1);
    sample=struct('M',a.M,'D0',a.D,'D1',(p.D-m.D)/2,'K0',a.K,'K1',(p.K-m.K)/2,'K2',(p.K+m.K)/2-a.K);
    samples{j}=sample;
    for k=1:numel(names),name=names{k};average.(name)=average.(name)+sample.(name)/N;end
    if j==1,recovery=a.recovery;end
end
axis=md.rotorAxis.direction;hub=md.dofs.node(130,:);nac=md.dofs.node(129,:);top=md.dofs.node(20,:);
input=zeros(s.ndof,1);input(hub(1:3))=axis;B=recovery.'*input;
C=[axis.'*recovery(hub(1:3),:);recovery(hub(2),:);recovery(hub(3),:); ...
    axis.'*recovery(nac(1:3),:);axis.'*recovery(top(1:3),:);recovery(hub(5),:)];
channelNames=["hub_axial_m_per_N" "hub_lateral_m_per_N" "hub_vertical_m_per_N" ...
    "nacelle_axial_m_per_N" "tower_top_axial_m_per_N" "hub_pitch_rad_per_N"];
rpm=unique([linspace(.5,7.44,71),.7547*30/pi]);orders=[1 3 6];frequencies=zeros(numel(rpm),16);rows={};
for j=1:numel(rpm)
    w=rpm(j)*pi/30;[M,D,K]=operating(average,w);
    e=modal.solve_quadratic_modes(M,D,K,struct('number',16));
    % Frequencies are sorted at each speed; no unsupported branch labels.
    frequencies(j,:)=e.dampedFrequencyHz.';
    H0=C*(K\B);
    for k=1:numel(orders)
        order=orders(k);nu=order*w;x=(K+1i*nu*D-nu^2*M)\B;y=C*x;
        base=(s.Ke(5,:)+1i*nu*s.C(5,:)-nu^2*s.M(5,:))*recovery*x;
        rows(end+1,:)=[{rpm(j),order,nu/(2*pi)},num2cell(abs(y).'), ...
            {abs(base),abs(y(1))/max(abs(H0(1)),eps),angle(y(1))*180/pi}]; %#ok<AGROW>
    end
    if mod(j,12)==0,fprintf('Rotor-order sweep %d/%d\n',j,numel(rpm));end
end
responseTable=cell2table(rows,'VariableNames',cellstr(["rpm" "order" "frequency_hz" channelNames "base_pitch_Nm_per_N" "hub_axial_amplification" "hub_phase_deg"]));
writetable(responseTable,fullfile(folder,'hub_receptance.csv'));
writetable(array2table([rpm(:) frequencies],'VariableNames',[{'rpm'},cellstr("frequency_"+string(1:16)+"_hz")]),fullfile(folder,'campbell.csv'));
% Resolve narrow peaks with direct full-order solves, not the coarse RPM grid.
peakRows={};fineRows={};
for order=orders
    subset=responseTable(responseTable.order==order,:);values=subset.hub_axial_m_per_N;
    indices=find(values(2:end-1)>values(1:end-2)&values(2:end-1)>values(3:end))+1;
    for index=indices.'
        lo=subset.rpm(index-1);hi=subset.rpm(index+1);
        objective=@(r)-hubAmplitude(average,r,order,C,B);
        peak=fminbnd(objective,lo,hi,optimset('TolX',1e-7,'Display','off'));
        [amp,phase,amplification]=hubAmplitude(average,peak,order,C,B);
        peakRows(end+1,:)={order,peak,order*peak/60,amp,phase,amplification}; %#ok<AGROW>
        for rr=linspace(lo,hi,81)
            [am,ph,ampl,yy]=hubAmplitude(average,rr,order,C,B);
            fineRows(end+1,:)=[{order,rr,am,ph,ampl},num2cell(abs(yy(2:5)).')]; %#ok<AGROW>
        end
    end
end
peakTable=cell2table(peakRows,'VariableNames',{'order','rpm','frequency_hz','hub_axial_m_per_N','phase_deg','amplification'});
fineTable=cell2table(fineRows,'VariableNames',{'order','rpm','hub_axial_m_per_N','phase_deg','amplification','hub_lateral_m_per_N','hub_vertical_m_per_N','nacelle_axial_m_per_N','tower_top_axial_m_per_N'});
writetable(peakTable,fullfile(folder,'resolved_peaks.csv'));writetable(fineTable,fullfile(folder,'peak_neighborhoods.csv'));
% Verify the strongest 3P hub response against periodic and modal truncation.
three=peakTable(peakTable.order==3,:);[~,peak]=max(three.hub_axial_m_per_N);peakRPM=three.rpm(peak);w=peakRPM*pi/30;
[V,L]=eigs(average.K0,average.M,96,'smallestabs');[~,ix]=sort(real(diag(L)));V=V(:,ix);
for j=1:size(V,2),V(:,j)=V(:,j)/sqrt(real(V(:,j)'*average.M*V(:,j)));end
checks={};[M,D,K]=operating(average,w);reference=C*((K+1i*3*w*D-(3*w)^2*M)\B);
for count=[24 48 96]
    basis=V(:,1:count);Mm=zeros(count,count,N);Dm=Mm;Km=Mm;
    for j=1:N,[ms,ds,ks]=operating(samples{j},w);Mm(:,:,j)=basis'*ms*basis;Dm(:,:,j)=basis'*ds*basis;Km(:,:,j)=basis'*ks*basis;end
    for H=[3 6 9]
        z=dynamics.harmonic_balance(Mm,Dm,Km,w,3,basis'*B,H);
        x=2*z.coefficients(:,z.orders==3);y=C*basis*x;
        checks(end+1,:)={peakRPM,count,H,abs(y(1)),abs(y(1)-reference(1))/abs(reference(1)),z.residual}; %#ok<AGROW>
        fprintf('Periodic check: modes=%d H=%d hub=%g m/N\n',count,H,abs(y(1)));
    end
end
checkTable=cell2table(checks,'VariableNames',{'rpm','retained_modes','half_width','hub_axial_m_per_N','change_from_full_averaged','algebraic_residual'});
writetable(checkTable,fullfile(folder,'periodic_convergence.csv'));
% Angular integration check of the full mean matrices at the selected speed.
angular={};for count=[12 24 48]
    ma=0;da=0;ka=0;for j=1:N/count:N,[ms,ds,ks]=operating(samples{j},w);ma=ma+ms/count;da=da+ds/count;ka=ka+ks/count;end
    y=C*((ka+1i*3*w*da-9*w*w*ma)\B);angular(end+1,:)={count,abs(y(1)),norm(y-reference)/norm(reference)}; %#ok<AGROW>
end
angularTable=cell2table(angular,'VariableNames',{'angular_samples','hub_axial_m_per_N','relative_channel_change'});writetable(angularTable,fullfile(folder,'angular_convergence.csv'));
loadReport=rotor_load_orders(s,folder);
report=struct('configuration',cfg,'rpm',rpm,'frequencies',frequencies,'responses',responseTable, ...
    'periodicChecks',checkTable,'angularChecks',angularTable,'loadOrders',loadReport, ...
    'resolvedPeaks',peakTable,'peakRPM',peakRPM,'average',average,'basis',V,'C',C,'B',B, ...
    'scope',"structural periodic model; unit axial hub force; no aerodynamic feedback or gravity prestress", ...
    'damping',"illustrative Rayleigh damping, 0.5% at 0.17 and 1 Hz; not identified");
save(fullfile(folder,'rotor_orders.mat'),'report','-v7.3');
end
function [M,D,K]=operating(a,w)
M=a.M;D=a.D0+w*a.D1;K=a.K0+w*a.K1+w*w*a.K2;
end

function [amplitude,phase,amplification,y]=hubAmplitude(a,rpm,order,C,B)
w=rpm*pi/30;nu=order*w;[M,D,K]=operating(a,w);
y=C*((K+1i*nu*D-nu^2*M)\B);y0=C*(K\B);
amplitude=abs(y(1));phase=angle(y(1))*180/pi;amplification=amplitude/abs(y0(1));
end
