function refinement=refine_maza_growth(folder,extraFiles)
%REFINE_MAZA_GROWTH Resolve growing twist separately from tip bending.
% Optional explicit files reuse three computed runs after operating-input checks.
a=load(fullfile(folder,'condition_3_variant_1.mat'),'r');
b=load(fullfile(folder,'condition_3_variant_2.mat'),'r');
steps=[.0025 .00125 .000625];cases={a.r,b.r};
if nargin>1,assert(numel(extraFiles)==3,'Supply one file for each of the three refinement steps.');end
for j=1:numel(steps)
    if nargin<2
        cfg=b.r.configuration;cfg.aeroelastic.dt=steps(j);cfg.aeroelastic.duration=100;
        cfg.aeroelastic.outputStride=round(.05/steps(j));cfg.aeroelastic.saveResults=false;
        r=run_aeroelastic(cfg);
    else
        extra=load(extraFiles(j),'r');r=extra.r;
        assert(r.configuration.aeroelastic.dt==steps(j)&&r.configuration.aeroelastic.feedback ...
            &&isequal(r.configuration.aerodynamics,b.r.configuration.aerodynamics) ...
            &&isequal(r.configuration.rotor,b.r.configuration.rotor) ...
            &&isequal(r.configuration.sections,b.r.configuration.sections) ...
            &&isequal(r.configuration.data,b.r.configuration.data), ...
            'The supplied refinement file has different physical inputs.');
    end
    save(fullfile(folder,sprintf('condition_3_dt_%g.mat',steps(j))),'r','-v7.3');
    cases{end+1}=r; %#ok<AGROW>
end
target=cases{end};rows=cell(numel(cases),1);
for k=1:numel(cases)
    current=cases{k};use=current.t<=min(current.t(end),target.t(end));t=current.t(use);
    x=interp1(target.t,target.tipWindDisplacement,t);theta=interp1(target.t,target.q(end,:).',t);
    window=current.t>=50&current.t<=70;twist=current.q(end,window);
    rows{k}={current.configuration.aeroelastic.dt,current.terminationTime, ...
        norm(current.tipWindDisplacement(use)-x)/max(norm(x),eps), ...
        norm(current.q(end,use).'-theta)/max(norm(theta),eps), ...
        sqrt(mean((twist-mean(twist)).^2)),t(end)};
end
refinement=cell2table(vertcat(rows{:}),'VariableNames', ...
    {'dt_s','rotation_limit_time_s','tip_history_change_to_finest', ...
     'twist_history_change_to_finest','twist_rms_50_70_s_rad','common_end_s'});
writetable(refinement,fullfile(folder,'growing_twist_refinement.csv'));disp(refinement);
end
