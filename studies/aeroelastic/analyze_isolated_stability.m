function result=analyze_isolated_stability(folder)
%ANALYZE_ISOLATED_STABILITY Independent equilibrium, tangent, mesh and energy checks.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin<1,folder=fullfile(root,'runs','aeroelastic_convergence_20261117');end
if ~isfolder(folder),mkdir(folder);end
rows={};points=cell(3,1);modes=cell(3,1);
for factor=[1 2 4]
    steps=1e-5;if factor==1,steps=[1e-4 1e-5 1e-6];end
    for h=steps
        cfg=config_maza_isolated_blade(25,.1);cfg.aeroelastic.meshSubdivision=factor;
        p=aero.isolated_operating_point(cfg,h);
        e=modal.solve_quadratic_modes(p.M,p.D,p.K,struct('number',30,'target',21i));
        use=find(imag(e.eigenvalues)>15&imag(e.eigenvalues)<30);[~,j]=max(real(e.eigenvalues(use)));j=use(j);
        lambda=e.eigenvalues(j);phi=e.modes(:,j);omega=imag(lambda);
        force=(p.Fq+1i*omega*p.Fv)*phi;velocity=1i*omega*phi;
        power=.5*real(velocity'*force);
        energy=.25*real(omega^2*(phi'*p.M*phi)+phi'*p.op.K*phi);
        rows(end+1,:)={factor,35*factor,h,p.equilibriumResidual,p.q(end-5), ...
            real(lambda),omega/(2*pi),power/(2*energy),e.residual(j)}; %#ok<AGROW>
        fprintf('mesh=%d h=%g pole=%g + i %g, energy estimate=%g\n',factor,h,real(lambda),omega,power/(2*energy));
        if h==1e-5,points{log2(factor)+1}=p;modes{log2(factor)+1}=struct('lambda',lambda,'phi',phi);end
    end
end
results=cell2table(rows,'VariableNames',{'subdivision','elements','difference_step', ...
    'equilibrium_residual','equilibrium_tip_x_m','growth_rate_per_s','frequency_hz', ...
    'growth_from_cycle_work_per_s','eigen_residual'});
writetable(results,fullfile(folder,'stability_refinement.csv'));
result=struct('table',results,'points',{points},'modes',{modes});
save(fullfile(folder,'isolated_stability.mat'),'result','-v7.3');disp(results);
end
