function result=verify_rotor_periodicity(folder)
%VERIFY_ROTOR_PERIODICITY Stability and damping sensitivity near the 3P peak.
if nargin<1,folder=fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'runs','rotor_orders_20261117');end
s0=load(fullfile(folder,'rotor_orders.mat'),'report');report=s0.report;cfg=report.configuration;
md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);
w=report.peakRPM*pi/30;V=report.basis;N=48;M=zeros(size(V,2),size(V,2),N);D=M;K=M;
for j=1:N
    o=aero.turbine_mbc_operators(s,(j-1)*2*pi/N,w);
    M(:,:,j)=V'*o.M*V;D(:,:,j)=V'*o.D*V;K(:,:,j)=V'*o.K*V;
end
rows={};for n=[24 48]
    for count=[96 192]
        f=dynamics.periodic_stability(M(1:n,1:n,:),D(1:n,1:n,:),K(1:n,1:n,:),w,count);
        rows(end+1,:)={n,count,f.spectralRadius,max(f.growthRates)}; %#ok<AGROW>
        fprintf('Floquet modes=%d intervals=%d rho=%g\n',n,count,f.spectralRadius);
    end
end
stability=cell2table(rows,'VariableNames',{'retained_modes','time_intervals','spectral_radius','largest_growth_rate_per_s'});
writetable(stability,fullfile(folder,'floquet_convergence.csv'));
% Check the complex response, retaining phase as well as amplitude.
rows={};responses=cell(2,2);counts=[48 96];widths=[6 9];
for j=1:2
    n=counts(j);
    for k=1:2
        z=dynamics.harmonic_balance(M(1:n,1:n,:),D(1:n,1:n,:),K(1:n,1:n,:),w,3,V(:,1:n)'*report.B,widths(k));
        y=report.C*V(:,1:n)*(2*z.coefficients(:,z.orders==3));responses{j,k}=y;
    end
end
reference=responses{2,2};
for j=1:2
    for k=1:2
        y=responses{j,k};rows(end+1,:)={counts(j),widths(k),abs(y(1)),angle(y(1))*180/pi, ...
            abs(y(1)-reference(1))/abs(reference(1)),max(abs(y-reference)./max(abs(reference),realmin))}; %#ok<AGROW>
    end
end
harmonics=cell2table(rows,'VariableNames',{'retained_modes','half_width','hub_axial_m_per_N','phase_deg', ...
    'hub_complex_change_to_finest','maximum_component_relative_change'});
writetable(harmonics,fullfile(folder,'periodic_complex_convergence.csv'));disp(harmonics);
a=report.average;rows={};
for factor=[.5 1 2]
    d=factor*a.D0+w*a.D1;k=a.K0+w*factor*a.K1+w*w*a.K2;
    y=report.C*((k+3i*w*d-9*w*w*a.M)\report.B);
    rows(end+1,:)={.005*factor,abs(y(1)),angle(y(1))*180/pi}; %#ok<AGROW>
end
damping=cell2table(rows,'VariableNames',{'target_damping_ratio','hub_axial_m_per_N','phase_deg'});
writetable(damping,fullfile(folder,'damping_sensitivity.csv'));
result=struct('stability',stability,'harmonics',harmonics,'complexResponses',{responses},'damping',damping);
save(fullfile(folder,'periodicity_verification.mat'),'result');
report.loadOrders=readtable(fullfile(folder,'rigid_rotor_load_orders.csv'),'TextType','string');
save(fullfile(folder,'rotor_orders.mat'),'report','-v7.3');
end
