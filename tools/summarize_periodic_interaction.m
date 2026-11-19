function summarize_periodic_interaction()
% Signed differences are formed on complex coefficients before taking norms.
root=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(root,'runs','periodic_loads_20261118');
load(fullfile(folder,'campaign.mat'),'raw'); rows={};
for j=1:numel(raw)
 s=raw{j};
 for ix=1:numel(s.models)
  m=s.models{ix};
  for channel=1:7
   for loadIndex=1:2
    extract=@(x) squeeze(x(channel,:,loadIndex));
    p=extract(s.reference);a=extract(s.average);pr=extract(m.Yperiodic);ar=extract(m.Yaverage);
    % Effect of time averaging, spatial truncation, and their interaction.
    avg=a-p; spatial=pr-p; interaction=(ar-a)-spatial; total=ar-p;
    scale=norm(p);
    rows(end+1,:)={s.rpm,m.label,channel,loadIndex,100*norm(avg)/scale,100*norm(spatial)/scale, ...
      100*norm(interaction)/scale,100*norm(total)/scale,norm(total-avg-spatial-interaction)/scale};
   end
  end
 end
end
t=cell2table(rows,'VariableNames',{'rpm','basis','channel','load','averageEffectPercent','modalEffectPercent','interactionPercent','combinedPercent','closure'});
assert(max(t.closure)<1e-12);writetable(t,fullfile(folder,'interaction.csv'));
end
