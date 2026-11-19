function summary=summarize_floquet_study
% Compact study table. Include the two observed resonance peaks per level.
root=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(root,'runs','stability_20261119');
data=fullfile(root,'runs','periodic_loads_20261118');
summary=table();
for z=[0.5 1 2 5]
    peaks=readtable(fullfile(data,sprintf('damping_summary_%d.csv',round(10*z))));
    speeds=unique([2.95 3.394 3.4445 3.49 3.90 peaks.periodicPeakRpm peaks.averagePeakRpm peaks.maxErrorRpm]);
    radii=zeros(numel(speeds),1);
    for j=1:numel(speeds)
        r=readtable(fullfile(out,sprintf('arnoldi_266_%g_%g_128.csv',speeds(j),z)));
        radii(j)=r.spectralRadius;
    end
    r=readtable(fullfile(out,sprintf('arnoldi_266_3.4445_%g_256.csv',z)));
    [rhoMax,j]=max(radii);
    row=table(z,numel(speeds),rhoMax,speeds(j),r.spectralRadius, ...
        'VariableNames',{'dampingPercent','testedSpeeds','maxRho128','rpmAtMax','rhoAt34445N256'});
    summary=[summary;row];
end
writetable(summary,fullfile(out,'stability_summary.csv'));
end
