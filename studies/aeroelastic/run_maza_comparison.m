function report=run_maza_comparison(outputFolder)
%RUN_MAZA_COMPARISON Reconstruct three published operating conditions, not UVLM.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin<1,outputFolder=fullfile(root,'runs','maza_'+string(datetime('now','Format','yyyyMMdd_HHmmss')));end
if ~isfolder(outputFolder),mkdir(outputFolder);end
conditions=[1 .7547 400;18.2 .7547 400;25 .1 700];
reference=readtable(fullfile(root,'data','aerodynamics','snl100_00','maza_2023_reference.csv'));
rows=struct([]);responses=cell(3,3);
for c=1:3
    for variant=1:3
        cfg=config_maza_isolated_blade(conditions(c,1),conditions(c,2));
        cfg.aeroelastic.duration=conditions(c,3);cfg.aeroelastic.saveResults=false;
        if variant==1,cfg.aeroelastic.dt=.01;else,cfg.aeroelastic.dt=.005;end
        cfg.aeroelastic.outputStride=round(.05/cfg.aeroelastic.dt);
        cfg.aeroelastic.feedback=variant~=3;cfg.aeroelastic.returnPartialOnDomainExit=true;
        fprintf('Maza condition %d/3, variant %d/3: U=%g m/s, omega=%g rad/s, dt=%g s, feedback=%d\n', ...
            c,variant,conditions(c,1),conditions(c,2),cfg.aeroelastic.dt,cfg.aeroelastic.feedback);
        row=struct('condition',c,'wind_mps',conditions(c,1),'omega_radps',conditions(c,2), ...
            'duration_s',cfg.aeroelastic.duration,'dt_s',cfg.aeroelastic.dt,'feedback',cfg.aeroelastic.feedback, ...
            'status',"",'stop_time_s',NaN,'mean_m',NaN,'half_range_m',NaN,'late_frequency_radps',NaN, ...
            'max_rotation_rad',NaN,'runtime_s',NaN,'mechanical_residual',NaN);
        clock=tic;
        try
            r=run_aeroelastic(cfg);responses{c,variant}=r;
            save(fullfile(outputFolder,sprintf('condition_%d_variant_%d.mat',c,variant)),'r','-v7.3');
            writetable(table(r.t,r.tipWindDisplacement,'VariableNames',{'time_s','tip_global_x_m'}), ...
                fullfile(outputFolder,sprintf('condition_%d_variant_%d.csv',c,variant)));
            row.status=r.status;row.stop_time_s=r.terminationTime;
            if r.status=="completed"
                row.mean_m=r.summary.mean_m;row.half_range_m=r.summary.halfRange_m;
                row.late_frequency_radps=r.summary.dominantFrequency_radps;
            end
            row.max_rotation_rad=r.summary.maximumElasticRotation_rad;row.runtime_s=r.elapsedSeconds;
            row.mechanical_residual=r.maximumMechanicalResidual;
            fprintf('  mean %.6g m; half range %.6g m; max rotation %.6g rad; runtime %.2f s\n', ...
                row.mean_m,row.half_range_m,row.max_rotation_rad,row.runtime_s);
            fprintf('  status %s; final attempted time %.6g s\n',row.status,row.stop_time_s);
        catch exception
            if ~strcmp(exception.identifier,'dynamics:CouplingRange'),rethrow(exception);end
            row.status=string(exception.message);row.runtime_s=toc(clock);fprintf('  %s\n',row.status);
        end
        if isempty(rows),rows=row;else,rows(end+1)=row;end %#ok<AGROW>
        writetable(struct2table(rows),fullfile(outputFolder,'computed_summary.csv'));
    end
end
comparison=table((1:3).',conditions(:,1),conditions(:,2),nan(3,1),nan(3,1), ...
    'VariableNames',{'condition','wind_mps','omega_radps','relative_history_change','mean_change_m'});
for c=1:3
    coarse=responses{c,1};fine=responses{c,2};
    if isempty(coarse)||isempty(fine),continue,end
    use=coarse.t<=min(coarse.t(end),fine.t(end));
    xf=interp1(fine.t,fine.tipWindDisplacement,coarse.t(use));
    comparison.relative_history_change(c)=norm(coarse.tipWindDisplacement(use)-xf)/max(norm(xf),eps);
    if coarse.status=="completed"&&fine.status=="completed"
        comparison.mean_change_m(c)=abs(coarse.summary.mean_m-fine.summary.mean_m);
    end
end
writetable(comparison,fullfile(outputFolder,'time_step_comparison.csv'));
report=struct('computed',struct2table(rows),'refinement',comparison,'reference',reference, ...
    'source','https://amcaonline.org.ar/ojs/index.php/mc/article/download/6643/6706', ...
    'claim','Operating-condition comparison; not reproduction or validation of UVLM flutter', ...
    'outputFolder',string(outputFolder));
save(fullfile(outputFolder,'comparison.mat'),'report');
make_maza_figures(responses,conditions,outputFolder);
report.growthRefinement=refine_maza_growth(outputFolder);
save(fullfile(outputFolder,'comparison.mat'),'report');
disp(report.computed);disp(comparison);fprintf('Comparison saved: %s\n',outputFolder);
end
