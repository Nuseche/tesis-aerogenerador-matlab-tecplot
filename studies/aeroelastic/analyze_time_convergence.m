function report=analyze_time_convergence(folder)
%ANALYZE_TIME_CONVERGENCE Same-time histories; no phase shifts or curve fitting.
steps=[.000625 .0003125 .00015625 .000078125];cases=cell(1,numel(steps));
for k=1:numel(steps),s=load(fullfile(folder,sprintf('acceleration_dt_%g.mat',steps(k))),'r');cases{k}=s.r;end
target=cases{end};rows={};fitRows={};
for k=1:numel(steps)
    r=cases{k};assert(max(abs(r.t-target.t))<1e-10,'Output times must coincide.');
    translation=mod(0:size(r.q,1)-1,6)<3;rotation=~translation;
    values={r.q(end-5,:),r.q(end,:),r.aerodynamicForce(translation,:),r.aerodynamicForce(rotation,:)};
    reference={target.q(end-5,:),target.q(end,:),target.aerodynamicForce(translation,:),target.aerodynamicForce(rotation,:)};
    labels=["tip_displacement" "tip_twist" "aerodynamic_force" "aerodynamic_moment"];
    window=r.t>=20;
    for j=1:4
        x=values{j};y=reference{j};dx=x-y;
        fluctuation=y(:,window)-mean(y(:,window),2);
        rows(end+1,:)={steps(k),labels(j),norm(dx,'fro')/max(norm(y,'fro'),eps), ...
            max(abs(dx),[],'all')/max(max(abs(y),[],'all'),eps), ...
            norm(dx(:,window),'fro')/max(norm(fluctuation,'fro'),eps)}; %#ok<AGROW>
    end
    use=r.t>=20&r.t<=50;t=r.t(use)-20;y=r.q(end,use).';
    objective=@(p)fitResidual(p,t,y);p=fminsearch(objective,[.04 21.03],optimset('TolX',1e-10,'Display','off'));
    fitRows(end+1,:)={steps(k),p(1),p(2)/(2*pi),objective(p)}; %#ok<AGROW>
end
metrics=cell2table(rows,'VariableNames',{'dt_s','channel','relative_L2','relative_maximum_difference','relative_change_to_fluctuation_20_60_s'});
fits=cell2table(fitRows,'VariableNames',{'dt_s','growth_rate_per_s','frequency_hz','single_mode_fit_residual'});
writetable(metrics,fullfile(folder,'temporal_convergence.csv'));writetable(fits,fullfile(folder,'growth_frequency_fit.csv'));
last=metrics(metrics.dt_s==steps(end-1),:);accepted=all(last.relative_L2<.01&last.relative_maximum_difference<.01&last.relative_change_to_fluctuation_20_60_s<.01);
report=struct('metrics',metrics,'fits',fits,'acceptedAtOnePercent',accepted, ...
    'criterion','L2 and maximum history changes on 0--60 s, and change relative to fluctuations on 20--60 s, all below 1%; no phase alignment; finer run is a numerical reference.');
save(fullfile(folder,'temporal_analysis.mat'),'report');disp(metrics);disp(fits);disp(report.acceptedAtOnePercent);
end
function residual=fitResidual(p,t,y)
e=exp(p(1)*t);B=[e.*cos(p(2)*t),e.*sin(p(2)*t),ones(size(t))];
residual=norm(B*(B\y)-y)/norm(y-mean(y));
end
