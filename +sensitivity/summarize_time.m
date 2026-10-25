function T=summarize_time(campaign)
%SUMMARIZE_TIME Synthetic frozen-point peaks on an explicit 0--1 s window.
dt=[0.01 0.005 0.0025 0.00125];results=cell(4,1);rows=cell(0,10);
for j=1:4,results{j}=sensitivity.read_case(campaign.folder,"dt_"+round(dt(j)*1e6));end
fine=results{end};
for j=1:4
    r=results{j};
    for c=1:numel(r.time.peakQ)
        [found,index]=ismembertol(r.time.t,fine.time.t,1e-10,'DataScale',1);
        if ~all(found),error('sensitivity:TimeGridMismatch','Nested grid required.');end
        y=r.time.historyQ(c,:);yf=fine.time.historyQ(c,index);
        err=norm(y-yf)/max(norm(yf),eps);
        rows(end+1,:)={dt(j),r.channels(c,1),r.channels(c,2),r.time.peakQ(c), ...
            r.time.peakAbsoluteA(c),err, ...
            abs(r.time.peakQ(c)-fine.time.peakQ(c))/max(fine.time.peakQ(c),eps), ...
            r.time.dynamicResidual,r.time.window(1),r.time.window(2)}; %#ok<AGROW>
    end
end
T=cell2table(rows,'VariableNames',{'dtS','nodeId','component','peakRelativeQ_M', ...
    'peakAbsoluteAcceleration_M_S2','relativeL2ToFinest','peakQRelativeDifference', ...
    'projectedDynamicResidual','windowStartS','windowEndS'});
writetable(T,fullfile(campaign.folder,'time_convergence.csv'));
minus=sensitivity.read_case(campaign.folder,'amplitude_1');plus=sensitivity.read_case(campaign.folder,'amplitude_3');
S=(plus.time.peakQ-minus.time.peakQ)./(0.02*fine.time.peakQ);
A=(plus.time.peakAbsoluteA-minus.time.peakAbsoluteA)./(0.02*fine.time.peakAbsoluteA);
writetable(table(fine.channels(:,1),fine.channels(:,2),S,A, ...
    'VariableNames',{'nodeId','component','displacementAmplitudeSensitivity','accelerationAmplitudeSensitivity'}), ...
    fullfile(campaign.folder,'seismic_amplitude_sensitivity.csv'));
end
