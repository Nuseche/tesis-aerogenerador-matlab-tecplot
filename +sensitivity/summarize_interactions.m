function T=summarize_interactions(local,campaign,names,h)
%SUMMARIZE_INTERACTIONS Central mixed derivatives with group/identity flags.
ref=local.nominal;s=campaign.study;n=s.branches;ys=zeros(n,4);valid=true(n,1);q=zeros(numel(ref.staticQ),4);
ids=["comb_1_1","comb_1_3","comb_3_1","comb_3_3"];
for k=1:4
    r=sensitivity.read_case(campaign.folder,ids(k));tr=sensitivity.track_modes(ref,r,s);
    ys(:,k)=tr.matchedFrequencyHz;valid=valid&tr.individualValid;q(:,k)=r.staticQ;
end
mixed=(ys(:,4)-ys(:,3)-ys(:,2)+ys(:,1))/(4*h^2);
f0=ref.solution.dampedFrequencyHz(1:n);scaled=mixed./f0;mixed(~valid)=NaN;scaled(~valid)=NaN;
T=table((1:n).',repmat(names(1),n,1),repmat(names(2),n,1),f0,mixed,scaled,valid, ...
    'VariableNames',{'mode','parameterA','parameterB','nominalHz','mixedDerivativeHz', ...
    'scaledMixedDerivative','individualTrackingValid'});
writetable(T,fullfile(campaign.folder,'frequency_interactions.csv'));
staticMixed=(q(:,4)-q(:,3)-q(:,2)+q(:,1))/(4*h^2);
writetable(table(ref.channels(:,1),ref.channels(:,2),staticMixed, ...
    'VariableNames',{'nodeId','component','mixedDerivativeM'}),fullfile(campaign.folder,'static_interactions.csv'));
end
