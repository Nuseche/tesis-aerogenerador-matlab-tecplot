function T=summarize_mesh(campaign)
%SUMMARIZE_MESH Common original-node physical space; never sort-match modes.
r1=sensitivity.read_case(campaign.folder,'mesh_1');
r2=sensitivity.read_case(campaign.folder,'mesh_2');
r4=sensitivity.read_case(campaign.folder,'mesh_4');
s=campaign.study;n=s.branches;nd=size(r1.fullMass,1);
r2.solution.fullModes=r2.solution.fullModes(1:nd,:);
r4.solution.fullModes=r4.solution.fullModes(1:nd,:);
a=sensitivity.track_modes(r1,r2,s);b=sensitivity.track_modes(r1,r4,s);
f1=r1.solution.dampedFrequencyHz(1:n);f2=a.matchedFrequencyHz;f4=b.matchedFrequencyHz;
T=table((1:n).',f1,f2,f4,abs(f2-f4)./max(f4,eps), ...
    abs(f1-f4)./max(f4,eps),a.individualMAC,b.individualMAC, ...
    a.individualValid&b.individualValid,'VariableNames', ...
    {'mode','frequencyMesh1Hz','frequencyMesh2Hz','frequencyMesh4Hz', ...
    'relativeDifference2to4','relativeDifference1to4','MAC2','MAC4','individualValid'});
writetable(T,fullfile(campaign.folder,'mesh_convergence.csv'));
end
